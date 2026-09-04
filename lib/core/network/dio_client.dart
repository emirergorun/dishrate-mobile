import 'dart:async';

import 'package:dio/dio.dart';
import '../auth/token_storage.dart';
import '../constants/api_constants.dart';

/// Uygulama genelinde kullanılan tek Dio örneği.
/// - Her isteğe otomatik Bearer token ekler
/// - 401 gelince refresh token ile yeni access token alır ve isteği tekrarlar
class DioClient {
  DioClient._();

  static final Dio _instance = _create();

  static Dio get instance => _instance;

  static Dio _create() {
    final dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: ApiConstants.connectTimeout),
        receiveTimeout: const Duration(seconds: ApiConstants.receiveTimeout),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Auth interceptor: token ekleme + otomatik yenileme
    dio.interceptors.add(_AuthInterceptor(dio));

    // Geliştirme: loglama
    dio.interceptors.add(
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        logPrint: (obj) => _debugLog(obj.toString()),
      ),
    );

    return dio;
  }

  static void _debugLog(String message) {
    // ignore: avoid_print
    print('[DIO] $message');
  }
}

// ── Auth Interceptor ──────────────────────────────────────────────────────────

class _AuthInterceptor extends Interceptor {
  _AuthInterceptor(this._dio);

  final Dio _dio;
  final _storage = TokenStorage.instance;

  /// Aynı anda birden fazla istek 401 alırsa hepsi TEK bir yenileme işlemini
  /// bekler. Aksi halde ilk istek yenilerken diğerleri hiç denenmeden düşer
  /// (uygulama ilk açılışta ekranların boş kalmasına yol açıyordu).
  Completer<String?>? _refreshCompleter;

  /// Sonsuz döngüyü önlemek için: bir istek yalnızca bir kez tekrarlanır.
  static const _retriedFlag = '__dishrate_retried';

  // Auth endpoint'leri — token eklenmez, 401'de yenileme denenmez
  static const _publicPaths = [
    ApiConstants.authLogin,
    ApiConstants.authRegister,
    ApiConstants.authRefresh,
    ApiConstants.authLogout,
  ];

  bool _isPublic(String path) => _publicPaths.any((p) => path.contains(p));

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (_isPublic(options.path)) {
      return handler.next(options);
    }

    final token = await _storage.getAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final options = err.requestOptions;
    final is401 = err.response?.statusCode == 401;
    final alreadyRetried = options.extra[_retriedFlag] == true;

    if (!is401 || alreadyRetried || _isPublic(options.path)) {
      return handler.next(err);
    }

    // Tek bir yenileme işlemi; eşzamanlı 401'ler aynı sonucu bekler.
    final newToken = await _refreshAccessToken();
    if (newToken == null) {
      return handler.next(err);
    }

    // İsteği yeni token ile tekrarla
    options.extra[_retriedFlag] = true;
    options.headers['Authorization'] = 'Bearer $newToken';
    try {
      final retryResponse = await _dio.fetch(options);
      return handler.resolve(retryResponse);
    } on DioException catch (retryError) {
      return handler.next(retryError);
    }
  }

  /// Access token'ı yeniler. Zaten devam eden bir yenileme varsa onu bekler.
  /// Başarısızsa null döner.
  Future<String?> _refreshAccessToken() {
    final inFlight = _refreshCompleter;
    if (inFlight != null) return inFlight.future;

    final completer = Completer<String?>();
    _refreshCompleter = completer;

    unawaited(() async {
      try {
        final refreshToken = await _storage.getRefreshToken();
        if (refreshToken == null || refreshToken.isEmpty) {
          completer.complete(null);
          return;
        }

        // Interceptor'sız ayrı Dio — yenileme isteği kendi kendini tetiklemesin
        final refreshDio = Dio(BaseOptions(baseUrl: ApiConstants.baseUrl));
        final response = await refreshDio.post(
          ApiConstants.authRefresh,
          data: {'refreshToken': refreshToken},
        );

        final newAccessToken = response.data['accessToken'] as String;
        await _storage.updateAccessToken(newAccessToken);
        completer.complete(newAccessToken);
      } on DioException catch (e) {
        // Yalnızca refresh token GERÇEKTEN geçersizse oturumu kapat.
        // Ağ hatasında token'ları silmek kullanıcıyı gereksiz yere atardı.
        final status = e.response?.statusCode;
        if (status == 401 || status == 403 || status == 404) {
          await _storage.clearAll();
        }
        completer.complete(null);
      } catch (_) {
        completer.complete(null);
      } finally {
        _refreshCompleter = null;
      }
    }());

    return completer.future;
  }
}

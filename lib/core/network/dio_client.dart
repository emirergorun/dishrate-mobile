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
  bool _isRefreshing = false;

  // Auth endpoint'leri — token ekleme
  static const _publicPaths = [
    ApiConstants.authLogin,
    ApiConstants.authRegister,
    ApiConstants.authRefresh,
    ApiConstants.authLogout,
  ];

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Public endpoint'lere token ekleme
    if (_publicPaths.any((p) => options.path.contains(p))) {
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
    final statusCode = err.response?.statusCode;

    // 401: access token süresi dolmuş → refresh et
    if (statusCode == 401 && !_isRefreshing) {
      _isRefreshing = true;

      try {
        final refreshToken = await _storage.getRefreshToken();
        if (refreshToken == null) {
          _isRefreshing = false;
          return handler.next(err);
        }

        // Yeni access token al
        final refreshDio = Dio(BaseOptions(baseUrl: ApiConstants.baseUrl));
        final response = await refreshDio.post(
          ApiConstants.authRefresh,
          data: {'refreshToken': refreshToken},
        );

        final newAccessToken = response.data['accessToken'] as String;
        await _storage.updateAccessToken(newAccessToken);

        // Başarısız isteği yeni token ile tekrarla
        final retryOptions = err.requestOptions;
        retryOptions.headers['Authorization'] = 'Bearer $newAccessToken';
        final retryResponse = await _dio.fetch(retryOptions);

        _isRefreshing = false;
        return handler.resolve(retryResponse);
      } catch (_) {
        _isRefreshing = false;
        // Refresh başarısız → token'ları sil (auth provider logout yapar)
        await _storage.clearAll();
        return handler.next(err);
      }
    }

    handler.next(err);
  }
}

import 'package:dio/dio.dart';
import '../constants/api_constants.dart';

/// Uygulama genelinde kullanılan tek Dio örneği.
/// Interceptor'lar buraya eklenir (auth token, loglama vb.)
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

    // Geliştirme ortamı: istek/yanıt loglama
    dio.interceptors.add(
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        logPrint: (obj) => debugDioLog(obj.toString()),
      ),
    );

    return dio;
  }

  static void debugDioLog(String message) {
    // ignore: avoid_print
    print('[DIO] $message');
  }
}

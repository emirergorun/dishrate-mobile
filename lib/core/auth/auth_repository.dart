import 'package:dio/dio.dart';
import '../constants/api_constants.dart';
import '../network/dio_client.dart';
import '../../shared/models/auth_model.dart';

class AuthRepository {
  AuthRepository._();
  static final AuthRepository instance = AuthRepository._();

  final Dio _dio = DioClient.instance;

  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    final response = await _dio.post(
      ApiConstants.authLogin,
      data: {'email': email, 'password': password},
    );
    return AuthResponse.fromJson(response.data as Map<String, dynamic>);
  }

  Future<AuthResponse> register({
    required String username,
    required String firstName,
    required String lastName,
    required String email,
    required String password,
  }) async {
    final response = await _dio.post(
      ApiConstants.authRegister,
      data: {
        'username': username,
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'password': password,
      },
    );
    return AuthResponse.fromJson(response.data as Map<String, dynamic>);
  }

  Future<AuthResponse> refresh(String refreshToken) async {
    final response = await _dio.post(
      ApiConstants.authRefresh,
      data: {'refreshToken': refreshToken},
    );
    return AuthResponse.fromJson(response.data as Map<String, dynamic>);
  }

  /// Şifremi unuttum, 1. adım (2.7): kayıtlı hesap varsa e-postaya kod gider.
  /// Cevap hesabın var olup olmadığından bağımsız; sunucunun mesajı döner.
  Future<String> requestPasswordReset(String identifier) async {
    final response = await _dio.post(
      ApiConstants.authPasswordForgot,
      data: {'identifier': identifier},
    );
    final data = response.data;
    return data is Map && data['message'] is String
        ? data['message'] as String
        : 'Bu bilgiyle kayıtlı bir hesap varsa e-postana 6 haneli bir kod gönderdik.';
  }

  /// Şifremi unuttum, 2. adım: kod + yeni şifre. Başarıda sunucu bütün
  /// oturumları kapatır; ardından yeni şifreyle giriş yapılır.
  Future<void> resetPassword({
    required String identifier,
    required String code,
    required String newPassword,
  }) async {
    await _dio.post(
      ApiConstants.authPasswordReset,
      data: {
        'identifier': identifier,
        'code': code,
        'newPassword': newPassword
      },
    );
  }

  Future<void> logout(String refreshToken) async {
    await _dio.post(
      ApiConstants.authLogout,
      data: {'refreshToken': refreshToken},
    );
  }
}

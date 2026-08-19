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

  Future<void> logout(String refreshToken) async {
    await _dio.post(
      ApiConstants.authLogout,
      data: {'refreshToken': refreshToken},
    );
  }

  Future<void> submitRestaurantApplication({
    required String restaurantName,
    required String city,
    String? district,
    String? fullAddress,
    String? contactPhone,
    String? description,
  }) async {
    await _dio.post(
      ApiConstants.applications,
      data: {
        'restaurantName': restaurantName,
        'city': city,
        if (district != null && district.isNotEmpty) 'district': district,
        if (fullAddress != null && fullAddress.isNotEmpty) 'fullAddress': fullAddress,
        if (contactPhone != null && contactPhone.isNotEmpty) 'contactPhone': contactPhone,
        if (description != null && description.isNotEmpty) 'description': description,
      },
    );
  }
}

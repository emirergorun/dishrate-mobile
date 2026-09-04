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
    required String district,
    required String addressLine1,
    required String buildingNo,
    String? addressLine2,
    String? floorApartment,
    String? postalCode,
    String? contactPhone,
    String? description,
  }) async {
    bool has(String? v) => v != null && v.trim().isNotEmpty;
    await _dio.post(
      ApiConstants.applications,
      data: {
        'restaurantName': restaurantName,
        'city': city,
        'district': district,
        'addressLine1': addressLine1,
        'buildingNo': buildingNo,
        if (has(addressLine2)) 'addressLine2': addressLine2,
        if (has(floorApartment)) 'floorApartment': floorApartment,
        if (has(postalCode)) 'postalCode': postalCode,
        if (has(contactPhone)) 'contactPhone': contactPhone,
        if (has(description)) 'description': description,
      },
    );
  }
}

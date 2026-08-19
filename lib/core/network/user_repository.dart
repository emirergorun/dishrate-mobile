import '../constants/api_constants.dart';
import '../mock/mock_data.dart';
import 'dio_client.dart';
import '../../shared/models/user_model.dart';

class UserRepository {
  UserRepository._();
  static final UserRepository instance = UserRepository._();

  final _dio = DioClient.instance;

  Future<UserModel> getUser(int userId) async {
    if (MockData.enabled) return MockData.mockUser;
    final response = await _dio.get('${ApiConstants.users}/$userId');
    return UserModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// Profil güncelle (PATCH). Yalnızca verilen alanlar gönderilir.
  /// İsim/soyisim 15 günde bir değiştirilebilir — kural ihlalinde backend
  /// 409 + Türkçe mesaj döner (DioException olarak yükselir).
  Future<UserModel> updateUser(
    int userId, {
    String? username,
    String? firstName,
    String? lastName,
    String? bio,
    String? profilePhotoUrl,
  }) async {
    final response = await _dio.patch(
      '${ApiConstants.users}/$userId',
      data: {
        if (username != null) 'username': username,
        if (firstName != null) 'firstName': firstName,
        if (lastName != null) 'lastName': lastName,
        if (bio != null) 'bio': bio,
        if (profilePhotoUrl != null) 'profilePhotoUrl': profilePhotoUrl,
      },
    );
    return UserModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// Şifre değiştir. Mevcut şifre yanlışsa backend 409 + Türkçe mesaj döner.
  Future<void> changePassword(
    int userId, {
    required String currentPassword,
    required String newPassword,
  }) async {
    await _dio.patch(
      '${ApiConstants.users}/$userId/password',
      data: {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      },
    );
  }
}

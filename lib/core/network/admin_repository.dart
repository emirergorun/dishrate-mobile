import '../constants/api_constants.dart';
import 'dio_client.dart';
import '../../shared/models/restaurant_application_model.dart';
import '../../shared/models/user_model.dart';

class AdminRepository {
  AdminRepository._();
  static final AdminRepository instance = AdminRepository._();

  final _dio = DioClient.instance;

  // ── Başvurular ──────────────────────────────────────────────────────────────

  /// Tüm başvurular (pendingOnly=true → sadece bekleyenler).
  Future<List<RestaurantApplicationModel>> getApplications({
    bool pendingOnly = false,
  }) async {
    final response = await _dio.get(
      '${ApiConstants.admin}/applications',
      queryParameters: {'pendingOnly': pendingOnly},
    );
    final list = response.data as List<dynamic>;
    return list
        .map((e) =>
            RestaurantApplicationModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> approveApplication(int id) async {
    await _dio.post('${ApiConstants.admin}/applications/$id/approve');
  }

  Future<void> rejectApplication(int id, {String? note}) async {
    await _dio.post(
      '${ApiConstants.admin}/applications/$id/reject',
      data: {if (note != null && note.isNotEmpty) 'adminNote': note},
    );
  }

  // ── Kullanıcılar ────────────────────────────────────────────────────────────

  Future<List<UserModel>> getAllUsers() async {
    final response = await _dio.get('${ApiConstants.admin}/users');
    final list = response.data as List<dynamic>;
    return list
        .map((e) => UserModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Rol değiştir. [role] backend enum adı: USER | RESTAURANT_OWNER | ADMIN
  Future<UserModel> changeUserRole(int userId, String role) async {
    final response = await _dio.patch(
      '${ApiConstants.admin}/users/$userId/role',
      queryParameters: {'role': role},
    );
    return UserModel.fromJson(response.data as Map<String, dynamic>);
  }
}

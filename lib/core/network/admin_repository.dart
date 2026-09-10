import '../constants/api_constants.dart';
import 'dio_client.dart';
import '../../shared/models/restaurant_claim_model.dart';
import '../../shared/models/user_model.dart';

class AdminRepository {
  AdminRepository._();
  static final AdminRepository instance = AdminRepository._();

  final _dio = DioClient.instance;

  // ── Sahiplik talepleri ──────────────────────────────────────────────────────

  /// Talepler. Varsayılan olarak yalnızca bekleyenler gelir.
  Future<List<RestaurantClaimModel>> getClaims({bool pendingOnly = true}) async {
    final response = await _dio.get(
      '${ApiConstants.admin}/claims',
      queryParameters: {'pendingOnly': pendingOnly},
    );
    final list = response.data as List<dynamic>;
    return list
        .map((e) => RestaurantClaimModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Talebi sonuçlandırır. Onay ve red aynı uçtan gider — karar gövdede.
  Future<RestaurantClaimModel> reviewClaim(
    int id, {
    required bool approve,
    String? note,
  }) async {
    final response = await _dio.patch(
      '${ApiConstants.admin}/claims/$id',
      data: {
        'status': approve ? 'APPROVED' : 'REJECTED',
        if (note != null && note.isNotEmpty) 'adminNote': note,
      },
    );
    return RestaurantClaimModel.fromJson(response.data as Map<String, dynamic>);
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

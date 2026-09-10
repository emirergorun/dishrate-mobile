import '../constants/api_constants.dart';
import 'dio_client.dart';
import '../../shared/models/restaurant_claim_model.dart';

/// Restoran sahipliği talepleri (kullanıcı tarafı).
class ClaimRepository {
  ClaimRepository._();
  static final ClaimRepository instance = ClaimRepository._();

  final _dio = DioClient.instance;

  /// Mevcut bir restoranın sahipliğini talep eder.
  ///
  /// Restoranın zaten sahibi varsa ya da bekleyen başka bir talep varsa
  /// sunucu 409 döner; mesajı kullanıcıya olduğu gibi gösterilebilir.
  Future<RestaurantClaimModel> claim(int restaurantId) async {
    final response = await _dio.post(
      '${ApiConstants.restaurants}/$restaurantId/claim',
    );
    return RestaurantClaimModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// Kullanıcının kendi talepleri — durum takibi ekranı için.
  Future<List<RestaurantClaimModel>> myClaims() async {
    final response = await _dio.get('${ApiConstants.restaurants}/claims/me');
    final list = response.data as List<dynamic>;
    return list
        .map((e) => RestaurantClaimModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

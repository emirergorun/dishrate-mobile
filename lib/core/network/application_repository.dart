import '../constants/api_constants.dart';
import 'dio_client.dart';
import '../../shared/models/restaurant_application_model.dart';

class ApplicationRepository {
  ApplicationRepository._();
  static final ApplicationRepository instance = ApplicationRepository._();

  final _dio = DioClient.instance;

  /// Giriş yapmış kullanıcının kendi başvuruları (durum takibi).
  Future<List<RestaurantApplicationModel>> getMyApplications() async {
    final response = await _dio.get('${ApiConstants.applications}/me');
    final list = response.data as List<dynamic>;
    return list
        .map((e) =>
            RestaurantApplicationModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

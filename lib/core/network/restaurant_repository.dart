import '../constants/api_constants.dart';
import 'dio_client.dart';
import '../../shared/models/restaurant_model.dart';
import '../../shared/models/menu_item_model.dart';

class RestaurantRepository {
  RestaurantRepository._();
  static final RestaurantRepository instance = RestaurantRepository._();

  final _dio = DioClient.instance;

  /// Search restaurants by name
  Future<List<RestaurantModel>> searchRestaurants(String name) async {
    final response = await _dio.get(
      ApiConstants.restaurants,
      queryParameters: {'name': name},
    );
    final list = response.data as List<dynamic>;
    return list
        .map((e) => RestaurantModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Get menu items for a restaurant
  Future<List<MenuItemModel>> getRestaurantMenu(int restaurantId) async {
    final response = await _dio.get(
      '${ApiConstants.restaurants}/$restaurantId/menu',
    );
    final list = response.data as List<dynamic>;
    return list
        .map((e) => MenuItemModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

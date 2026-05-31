import '../constants/api_constants.dart';
import '../mock/mock_data.dart';
import 'dio_client.dart';
import '../../shared/models/restaurant_model.dart';
import '../../shared/models/menu_item_model.dart';

class RestaurantRepository {
  RestaurantRepository._();
  static final RestaurantRepository instance = RestaurantRepository._();

  final _dio = DioClient.instance;

  /// Get all restaurants (for map)
  Future<List<RestaurantModel>> getAllRestaurants() async {
    if (MockData.enabled) return MockData.restaurants;
    final response = await _dio.get(ApiConstants.restaurants);
    final list = response.data as List<dynamic>;
    return list
        .map((e) => RestaurantModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Search restaurants by name
  Future<List<RestaurantModel>> searchRestaurants(String name) async {
    if (MockData.enabled) return MockData.searchRestaurants(name);
    final response = await _dio.get(
      ApiConstants.restaurants,
      queryParameters: {'name': name},
    );
    final list = response.data as List<dynamic>;
    return list
        .map((e) => RestaurantModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Search menu items by name (used for category-based map filtering)
  Future<List<MenuItemModel>> searchMenuItems(String name) async {
    if (MockData.enabled) return MockData.searchMenuItems(name);
    final response = await _dio.get(
      ApiConstants.menuItems,
      queryParameters: {'name': name},
    );
    final list = response.data as List<dynamic>;
    return list
        .map((e) => MenuItemModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Get menu items for a restaurant
  Future<List<MenuItemModel>> getRestaurantMenu(int restaurantId) async {
    if (MockData.enabled) return MockData.getMenu(restaurantId);
    final response = await _dio.get(
      '${ApiConstants.restaurants}/$restaurantId/menu',
    );
    final list = response.data as List<dynamic>;
    return list
        .map((e) => MenuItemModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

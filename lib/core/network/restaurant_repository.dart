import '../constants/api_constants.dart';
import '../mock/mock_data.dart';
import 'dio_client.dart';
import '../../shared/models/restaurant_model.dart';
import '../../shared/models/menu_item_model.dart';
import '../../shared/models/category_model.dart';

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

  /// Get all menu items (keşfet akışı için)
  Future<List<MenuItemModel>> getAllMenuItems() async {
    if (MockData.enabled) {
      return MockData.searchMenuItems('');
    }
    final response = await _dio.get(ApiConstants.menuItems);
    final list = response.data as List<dynamic>;
    return list
        .map((e) => MenuItemModel.fromJson(e as Map<String, dynamic>))
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

  /// Get menu items filtered by category name (kategori çipleri için)
  Future<List<MenuItemModel>> getMenuItemsByCategory(String category) async {
    if (MockData.enabled) {
      return MockData.searchMenuItems('')
          .where((i) => i.categoryName == category)
          .toList();
    }
    final response = await _dio.get(
      ApiConstants.menuItems,
      queryParameters: {'category': category},
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

  // ── Owner (restoran sahibi) işlemleri ───────────────────────────────────────

  /// Giriş yapmış kullanıcının sahip olduğu restoranlar.
  Future<List<RestaurantModel>> getMyRestaurants() async {
    final response = await _dio.get('${ApiConstants.restaurants}/mine');
    final list = response.data as List<dynamic>;
    return list
        .map((e) => RestaurantModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Restoran bilgisini güncelle (sahip/admin).
  Future<RestaurantModel> updateRestaurant(
    int restaurantId, {
    String? name,
    String? logoUrl,
    String? city,
    String? district,
    String? fullAddress,
  }) async {
    final response = await _dio.patch(
      '${ApiConstants.restaurants}/$restaurantId',
      data: {
        if (name != null) 'name': name,
        if (logoUrl != null) 'logoUrl': logoUrl,
        if (city != null) 'city': city,
        if (district != null) 'district': district,
        if (fullAddress != null) 'fullAddress': fullAddress,
      },
    );
    return RestaurantModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// Kategori listesi (menü öğesi formu dropdown'u için).
  Future<List<CategoryModel>> getCategories() async {
    final response = await _dio.get(ApiConstants.categories);
    final list = response.data as List<dynamic>;
    return list
        .map((e) => CategoryModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Menü öğesi ekle.
  Future<MenuItemModel> createMenuItem({
    required int restaurantId,
    required String name,
    int? categoryId,
    String? photoUrl,
  }) async {
    final response = await _dio.post(
      ApiConstants.menuItems,
      data: {
        'restaurantId': restaurantId,
        'name': name,
        if (categoryId != null) 'categoryId': categoryId,
        if (photoUrl != null && photoUrl.isNotEmpty) 'photoUrl': photoUrl,
      },
    );
    return MenuItemModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// Menü öğesi güncelle.
  Future<MenuItemModel> updateMenuItem(
    int menuItemId, {
    String? name,
    int? categoryId,
    String? photoUrl,
  }) async {
    final response = await _dio.patch(
      '${ApiConstants.menuItems}/$menuItemId',
      data: {
        if (name != null) 'name': name,
        if (categoryId != null) 'categoryId': categoryId,
        if (photoUrl != null) 'photoUrl': photoUrl,
      },
    );
    return MenuItemModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// Menü öğesi sil.
  Future<void> deleteMenuItem(int menuItemId) async {
    await _dio.delete('${ApiConstants.menuItems}/$menuItemId');
  }
}

import '../constants/api_constants.dart';
import 'dio_client.dart';
import '../../shared/models/restaurant_model.dart';
import '../../shared/models/menu_item_model.dart';
import '../../shared/models/feed_section_model.dart';

import '../../shared/models/search_result_model.dart';

export '../../shared/models/feed_section_model.dart';
export '../../shared/models/search_result_model.dart';

class RestaurantRepository {
  RestaurantRepository._();
  static final RestaurantRepository instance = RestaurantRepository._();

  final _dio = DioClient.instance;

  /// Get all restaurants (for map)
  Future<List<RestaurantModel>> getAllRestaurants() async {
    final response = await _dio.get(ApiConstants.restaurants);
    final list = response.data as List<dynamic>;
    return list
        .map((e) => RestaurantModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

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

  /// Keşfet akışı: konuma (ve seçiliyse kategoriye) göre bölümler, her biri
  /// en fazla [limit] öğe. Tüm katalogu indirmek yerine bu kullanılır.
  Future<List<FeedSection>> getFeed({
    String? city,
    String? district,
    String? category,
    int limit = 10,
  }) async {
    final response = await _dio.get(
      '${ApiConstants.menuItems}/feed',
      queryParameters: {
        if (city != null) 'city': city,
        if (district != null) 'district': district,
        if (category != null) 'category': category,
        'limit': limit,
      },
    );
    return (response.data as List<dynamic>)
        .map((e) => FeedSection.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// "Tümünü gör" — bir bölümün [page]. sayfası.
  Future<List<MenuItemModel>> getFeedSection(
    String key, {
    String? city,
    String? district,
    String? category,
    int page = 0,
    int size = 20,
  }) async {
    final response = await _dio.get(
      '${ApiConstants.menuItems}/feed/$key',
      queryParameters: {
        if (city != null) 'city': city,
        if (district != null) 'district': district,
        if (category != null) 'category': category,
        'page': page,
        'size': size,
      },
    );
    return (response.data as List<dynamic>)
        .map((e) => MenuItemModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Arama ekranı: yemek, restoran ve kategori adında arar. Türkçe karakter
  /// ve harf büyüklüğü sunucuda yok sayılır ("sisli" → Şişli).
  Future<List<SearchResult>> search(String query) async {
    final response = await _dio.get('/search', queryParameters: {'q': query});
    return (response.data as List<dynamic>)
        .map((e) => SearchResult.fromJson(e as Map<String, dynamic>))
        .toList();
  }



  /// Get menu items filtered by category name (kategori çipleri için)
  Future<List<MenuItemModel>> getMenuItemsByCategory(String category) async {
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
    final response = await _dio.get(
      '${ApiConstants.restaurants}/$restaurantId/menu',
    );
    final list = response.data as List<dynamic>;
    return list
        .map((e) => MenuItemModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

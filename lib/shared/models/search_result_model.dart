import 'menu_item_model.dart';

/// Arama ekranında bir restoran kartı (`GET /search?q=`).
class SearchResult {
  const SearchResult({
    required this.restaurantId,
    required this.name,
    this.city,
    this.district,
    this.latitude,
    this.longitude,
    required this.nameMatched,
    required this.items,
  });

  final int restaurantId;
  final String name;
  final String? city;
  final String? district;
  final double? latitude;
  final double? longitude;

  /// Restoranın kendi adı eşleşti — [items] o zaman restoranın menüsü.
  final bool nameMatched;

  /// Menüsü henüz olmayan restoranda boş.
  final List<MenuItemModel> items;

  factory SearchResult.fromJson(Map<String, dynamic> json) => SearchResult(
        restaurantId: json['restaurantId'] as int,
        name: json['name'] as String,
        city: json['city'] as String?,
        district: json['district'] as String?,
        latitude: (json['latitude'] as num?)?.toDouble(),
        longitude: (json['longitude'] as num?)?.toDouble(),
        nameMatched: json['nameMatched'] as bool? ?? false,
        items: (json['items'] as List<dynamic>? ?? const [])
            .map((e) => MenuItemModel.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

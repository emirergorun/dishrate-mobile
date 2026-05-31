class RestaurantModel {
  final int restaurantId;
  final String name;
  final String? logoUrl;
  final String city;
  final String? district;
  final String fullAddress;
  final double? latitude;
  final double? longitude;
  /// Restoran türü — harita marker emoji'si için kullanılır.
  /// Gerçek API'da bu alan yoksa null gelir ve varsayılan emoji gösterilir.
  final String? categoryName;

  const RestaurantModel({
    required this.restaurantId,
    required this.name,
    this.logoUrl,
    required this.city,
    this.district,
    required this.fullAddress,
    this.latitude,
    this.longitude,
    this.categoryName,
  });

  factory RestaurantModel.fromJson(Map<String, dynamic> json) {
    final address = json['address'] as Map<String, dynamic>? ?? {};
    return RestaurantModel(
      restaurantId: json['restaurantId'] as int,
      name: json['name'] as String,
      logoUrl: json['logoUrl'] as String?,
      city: address['city'] as String? ?? '',
      district: address['district'] as String?,
      fullAddress: address['fullAddress'] as String? ?? '',
      latitude: (address['latitude'] as num?)?.toDouble(),
      longitude: (address['longitude'] as num?)?.toDouble(),
    );
  }
}

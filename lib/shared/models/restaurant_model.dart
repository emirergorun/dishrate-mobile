class RestaurantModel {
  final int restaurantId;
  final String name;
  final String? logoUrl;
  final String city;
  final String? district;
  final String fullAddress;

  const RestaurantModel({
    required this.restaurantId,
    required this.name,
    this.logoUrl,
    required this.city,
    this.district,
    required this.fullAddress,
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
    );
  }
}

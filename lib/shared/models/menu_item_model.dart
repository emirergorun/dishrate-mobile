class MenuItemModel {
  final int menuItemId;
  final String name;
  final double averageRating;

  /// Kaç kişi puanladı — restoran menüsünü "en çok değerlendirilen"e göre
  /// sıralamak için.
  final int ratingCount;
  final String? photoUrl;
  final int restaurantId;
  final String restaurantName;
  final String? categoryName;
  final String? city;
  final String? district;
  final double? restaurantLatitude;
  final double? restaurantLongitude;

  const MenuItemModel({
    required this.menuItemId,
    required this.name,
    required this.averageRating,
    this.ratingCount = 0,
    this.photoUrl,
    required this.restaurantId,
    required this.restaurantName,
    this.categoryName,
    this.city,
    this.district,
    this.restaurantLatitude,
    this.restaurantLongitude,
  });

  factory MenuItemModel.fromJson(Map<String, dynamic> json) {
    return MenuItemModel(
      menuItemId: json['menuItemId'] as int,
      name: json['name'] as String,
      averageRating: (json['averageRating'] as num).toDouble(),
      ratingCount: json['ratingCount'] as int? ?? 0,
      photoUrl: json['photoUrl'] as String?,
      restaurantId: json['restaurantId'] as int,
      restaurantName: json['restaurantName'] as String,
      categoryName: json['category']?['name'] as String?,
      city: json['city'] as String?,
      district: json['district'] as String?,
      restaurantLatitude: (json['restaurantLatitude'] as num?)?.toDouble(),
      restaurantLongitude: (json['restaurantLongitude'] as num?)?.toDouble(),
    );
  }
}

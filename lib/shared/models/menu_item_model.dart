class MenuItemModel {
  final int menuItemId;
  final String name;
  final double price;
  final double averageRating;
  final String? photoUrl;
  final int restaurantId;
  final String restaurantName;
  final String? categoryName;
  final String? city;
  final String? district;

  const MenuItemModel({
    required this.menuItemId,
    required this.name,
    required this.price,
    required this.averageRating,
    this.photoUrl,
    required this.restaurantId,
    required this.restaurantName,
    this.categoryName,
    this.city,
    this.district,
  });

  factory MenuItemModel.fromJson(Map<String, dynamic> json) {
    return MenuItemModel(
      menuItemId: json['menuItemId'] as int,
      name: json['name'] as String,
      price: (json['price'] as num).toDouble(),
      averageRating: (json['averageRating'] as num).toDouble(),
      photoUrl: json['photoUrl'] as String?,
      restaurantId: json['restaurantId'] as int,
      restaurantName: json['restaurantName'] as String,
      categoryName: json['category']?['name'] as String?,
      city: json['city'] as String?,
      district: json['district'] as String?,
    );
  }
}

class WishlistModel {
  final int wishId;
  final int menuItemId;
  final String menuItemName;
  final int restaurantId;
  final String restaurantName;
  final double averageRating;
  final double? price;

  const WishlistModel({
    required this.wishId,
    required this.menuItemId,
    required this.menuItemName,
    required this.restaurantId,
    required this.restaurantName,
    required this.averageRating,
    this.price,
  });

  factory WishlistModel.fromJson(Map<String, dynamic> json) {
    final item = json['menuItem'] as Map<String, dynamic>? ?? {};
    return WishlistModel(
      wishId: json['wishId'] as int,
      menuItemId: item['menuItemId'] as int,
      menuItemName: item['name'] as String,
      restaurantId: item['restaurantId'] as int,
      restaurantName: item['restaurantName'] as String,
      averageRating: (item['averageRating'] as num?)?.toDouble() ?? 0.0,
      price: (item['price'] as num?)?.toDouble(),
    );
  }
}

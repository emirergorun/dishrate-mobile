class RatingModel {
  final int ratingId;
  final int userId;
  final String username;
  final int menuItemId;
  final String menuItemName;

  /// Yemeğin kendi fotoğrafı.
  final String? photoUrl;

  /// Kullanıcının değerlendirmeye eklediği fotoğraf (varsa).
  final String? reviewPhotoUrl;
  final int? restaurantId;
  final String restaurantName;
  final String? categoryName;
  final double score;
  final String? comment;
  final DateTime? ratedAt;

  const RatingModel({
    required this.ratingId,
    required this.userId,
    required this.username,
    required this.menuItemId,
    required this.menuItemName,
    this.photoUrl,
    this.reviewPhotoUrl,
    this.restaurantId,
    required this.restaurantName,
    this.categoryName,
    required this.score,
    this.comment,
    this.ratedAt,
  });

  factory RatingModel.fromJson(Map<String, dynamic> json) {
    return RatingModel(
      ratingId: json['ratingId'] as int,
      userId: json['userId'] as int,
      username: json['username'] as String,
      menuItemId: json['menuItemId'] as int,
      menuItemName: json['menuItemName'] as String,
      photoUrl: json['photoUrl'] as String?,
      reviewPhotoUrl: json['reviewPhotoUrl'] as String?,
      restaurantId: json['restaurantId'] as int?,
      restaurantName: json['restaurantName'] as String,
      categoryName: json['categoryName'] as String?,
      score: (json['score'] as num).toDouble(),
      comment: json['comment'] as String?,
      ratedAt: json['ratedAt'] != null
          ? DateTime.parse(json['ratedAt'] as String)
          : null,
    );
  }

  RatingModel copyWith({double? score, String? comment}) => RatingModel(
        ratingId: ratingId,
        userId: userId,
        username: username,
        menuItemId: menuItemId,
        menuItemName: menuItemName,
        photoUrl: photoUrl,
        reviewPhotoUrl: reviewPhotoUrl,
        restaurantId: restaurantId,
        restaurantName: restaurantName,
        categoryName: categoryName,
        score: score ?? this.score,
        comment: comment,
        ratedAt: ratedAt,
      );
}

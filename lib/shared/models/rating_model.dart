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

  /// Restoranın ilçesi ve ili; adisyondaki favori yemeklerde yazar (1.9).
  final String? restaurantDistrict;
  final String? restaurantCity;
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
    this.restaurantDistrict,
    this.restaurantCity,
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
      restaurantDistrict: json['restaurantDistrict'] as String?,
      restaurantCity: json['restaurantCity'] as String?,
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
        restaurantDistrict: restaurantDistrict,
        restaurantCity: restaurantCity,
        categoryName: categoryName,
        score: score ?? this.score,
        comment: comment,
        ratedAt: ratedAt,
      );

  /// "İlçe, İl"; biri eksikse olanı, ikisi de yoksa null.
  String? get restaurantLocation {
    final parts = [restaurantDistrict, restaurantCity]
        .whereType<String>()
        .where((p) => p.trim().isNotEmpty)
        .toList();
    return parts.isEmpty ? null : parts.join(', ');
  }
}

/// En yüksek puanlı değerlendirmeler (favori yemekler). Profildeki "Favori
/// yemekler" paneli ve kullanıcı adisyonu aynı sırayı göstersin diye tek yer.
List<RatingModel> topFavorites(List<RatingModel> ratings, {int count = 5}) {
  final sorted = [...ratings]..sort((a, b) => b.score.compareTo(a.score));
  return sorted.take(count).toList();
}

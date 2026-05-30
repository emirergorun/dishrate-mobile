class RatingModel {
  final int ratingId;
  final int userId;
  final String username;
  final int menuItemId;
  final String menuItemName;
  final double score;
  final String? comment;

  const RatingModel({
    required this.ratingId,
    required this.userId,
    required this.username,
    required this.menuItemId,
    required this.menuItemName,
    required this.score,
    this.comment,
  });

  factory RatingModel.fromJson(Map<String, dynamic> json) {
    return RatingModel(
      ratingId: json['ratingId'] as int,
      userId: json['userId'] as int,
      username: json['username'] as String,
      menuItemId: json['menuItemId'] as int,
      menuItemName: json['menuItemName'] as String,
      score: (json['score'] as num).toDouble(),
      comment: json['comment'] as String?,
    );
  }
}

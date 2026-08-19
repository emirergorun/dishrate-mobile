class MenuItemReviewModel {
  final int ratingId;
  final String reviewerName; // maskeli (başkası) veya gerçek (kendi yorumu)
  final bool mine;
  final double score;
  final String? comment;
  final DateTime? ratedAt;

  const MenuItemReviewModel({
    required this.ratingId,
    required this.reviewerName,
    required this.mine,
    required this.score,
    this.comment,
    this.ratedAt,
  });

  factory MenuItemReviewModel.fromJson(Map<String, dynamic> json) {
    return MenuItemReviewModel(
      ratingId: json['ratingId'] as int,
      reviewerName: json['reviewerName'] as String? ?? '***',
      mine: json['mine'] as bool? ?? false,
      score: (json['score'] as num).toDouble(),
      comment: json['comment'] as String?,
      ratedAt: json['ratedAt'] != null
          ? DateTime.tryParse(json['ratedAt'].toString())
          : null,
    );
  }
}

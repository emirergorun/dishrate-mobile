class RatingRequestModel {
  final int userId;
  final int menuItemId;
  final double score;
  final String? comment;

  const RatingRequestModel({
    required this.userId,
    required this.menuItemId,
    required this.score,
    this.comment,
  });

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'menuItemId': menuItemId,
        'score': score,
        if (comment != null && comment!.isNotEmpty) 'comment': comment,
      };
}

class RatingRequestModel {
  final int userId;
  final int menuItemId;
  final double score;
  final String? comment;

  /// `null` → sunucudaki fotoğrafa dokunulmaz (günlükten yalnızca puanı
  /// düzenlemek fotoğrafı silmesin). Boş metin → fotoğraf kaldırılır.
  final String? photoUrl;

  const RatingRequestModel({
    required this.userId,
    required this.menuItemId,
    required this.score,
    this.comment,
    this.photoUrl,
  });

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'menuItemId': menuItemId,
        'score': score,
        if (comment != null && comment!.isNotEmpty) 'comment': comment,
        if (photoUrl != null) 'photoUrl': photoUrl,
      };
}

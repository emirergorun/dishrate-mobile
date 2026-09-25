import 'dio_client.dart';

/// Değerlendirmenin bildirilme sebebi. Sunucudaki `ReportReason` ile aynı
/// adlar ve sıra.
enum ReportReason {
  spam('SPAM', 'Spam ya da reklam'),
  harassment('HARASSMENT', 'Hakaret ya da nefret söylemi'),
  sexualOrViolent('SEXUAL_OR_VIOLENT', 'Cinsel ya da şiddet içeren içerik'),
  offTopic('OFF_TOPIC', 'Yemekle ilgisi yok'),
  personalInfo('PERSONAL_INFO', 'Kişisel bilgi paylaşılmış'),
  other('OTHER', 'Başka bir sebep');

  const ReportReason(this.apiValue, this.label);
  final String apiValue;
  final String label;
}

/// Engellenenler listesindeki bir kişi. Ad "@kullanıcıadı".
class BlockedUser {
  const BlockedUser({
    required this.blockId,
    required this.name,
    this.blockedAt,
  });

  final int blockId;
  final String name;
  final DateTime? blockedAt;

  factory BlockedUser.fromJson(Map<String, dynamic> json) => BlockedUser(
        blockId: json['blockId'] as int,
        name: json['name'] as String? ?? '***',
        blockedAt: DateTime.tryParse(json['blockedAt'] as String? ?? ''),
      );
}

/// Bildirme ve engelleme (1.7). Yorumcunun kimliği uygulamaya gelmediği için
/// engelleme değerlendirme kimliğiyle yapılır; yazarı sunucu bulur.
class ModerationRepository {
  ModerationRepository._();
  static final ModerationRepository instance = ModerationRepository._();

  final _dio = DioClient.instance;

  /// [note]: "Başka bir sebep"teki isteğe bağlı açıklama (en fazla 300).
  Future<void> report(int ratingId, ReportReason reason, {String? note}) =>
      _dio.post('/ratings/$ratingId/reports', data: {
        'reason': reason.apiValue,
        if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
      });

  /// Şeritteki "Geri al": bildirim silinir.
  Future<void> undoReport(int ratingId) =>
      _dio.delete('/ratings/$ratingId/reports');

  Future<void> blockAuthor(int ratingId) =>
      _dio.post('/ratings/$ratingId/block-author');

  /// Şeritteki "Geri al": engel kalkar (kimlik yine değerlendirmeden).
  Future<void> unblockAuthor(int ratingId) =>
      _dio.delete('/ratings/$ratingId/block-author');

  Future<List<BlockedUser>> blocks() async {
    final response = await _dio.get('/users/me/blocks');
    return (response.data as List<dynamic>)
        .map((e) => BlockedUser.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> unblock(int blockId) => _dio.delete('/users/me/blocks/$blockId');
}

/// Türkçe tarih biçimleri.
///
/// `intl`'in Türkçe verisi uygulama açılışında yüklenmiyor; yalnızca iki
/// biçim için yerel veri başlatmak yerine ay adları burada tutuluyor.
abstract final class RelativeDate {
  static const _months = [
    'Oca',
    'Şub',
    'Mar',
    'Nis',
    'May',
    'Haz',
    'Tem',
    'Ağu',
    'Eyl',
    'Eki',
    'Kas',
    'Ara',
  ];

  /// "bugün", "3 gün önce", "2 hafta önce"; bir aydan eskiyse "12 Eyl 2026".
  ///
  /// Yorumlarda saat/dakika gösterilmiyor: bir yemek yorumunun 14 dk mı
  /// 2 sa mı önce yazıldığı okuyana bir şey söylemiyor, gün yetiyor.
  static String timeAgo(DateTime date, {DateTime? clock}) {
    final now = clock ?? DateTime.now();
    final t = date.toLocal();
    final today = DateTime(now.year, now.month, now.day);
    final days = today.difference(DateTime(t.year, t.month, t.day)).inDays;

    if (days <= 0) return 'bugün';
    if (days == 1) return 'dün';
    if (days < 7) return '$days gün önce';
    if (days < 30) return '${days ~/ 7} hafta önce';
    return RelativeDate.date(t);
  }

  /// "12 Eyl 2026". Günlük kartları ve eski yorumlar aynı biçimi kullanır.
  static String date(DateTime d) =>
      '${d.day} ${_months[d.month - 1]} ${d.year}';
}

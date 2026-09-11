/// Türkçe tarih biçimleri.
///
/// `intl`'in Türkçe verisi uygulama açılışında yüklenmiyor; yalnızca iki
/// biçim için yerel veri başlatmak yerine ay adları burada tutuluyor.
abstract final class Tarih {
  static const _aylar = [
    'Oca', 'Şub', 'Mar', 'Nis', 'May', 'Haz',
    'Tem', 'Ağu', 'Eyl', 'Eki', 'Kas', 'Ara',
  ];

  /// "bugün", "3 gün önce", "2 hafta önce"; bir aydan eskiyse "12 Eyl 2026".
  ///
  /// Yorumlarda saat/dakika gösterilmiyor: bir yemek yorumunun 14 dk mı
  /// 2 sa mı önce yazıldığı okuyana bir şey söylemiyor, gün yetiyor.
  static String gecenSure(DateTime tarih, {DateTime? simdi}) {
    final now = simdi ?? DateTime.now();
    final t = tarih.toLocal();
    final bugun = DateTime(now.year, now.month, now.day);
    final gun = bugun.difference(DateTime(t.year, t.month, t.day)).inDays;

    if (gun <= 0) return 'bugün';
    if (gun == 1) return 'dün';
    if (gun < 7) return '$gun gün önce';
    if (gun < 30) return '${gun ~/ 7} hafta önce';
    return '${t.day} ${_aylar[t.month - 1]} ${t.year}';
  }
}

/// Türkçe metin işlemleri.
///
/// Dart'ın `toUpperCase()` / `toLowerCase()` metodları İngilizce kurallarına
/// göre çalışır: `'Diğer'.toUpperCase()` → `DIĞER` (İ yerine I),
/// `'IĞDIR'.toLowerCase()` → `iğdir` (ı yerine i). Türkçe metin gösterilen
/// hiçbir yerde bunlar kullanılmamalı; bu sınıf yerlerine geçer.
abstract final class Turkce {
  /// Türkçe küçük harf. `I → ı`, `İ → i`.
  static String kucuk(String s) {
    const map = {
      'I': 'ı', 'İ': 'i', 'Ş': 'ş', 'Ğ': 'ğ',
      'Ü': 'ü', 'Ö': 'ö', 'Ç': 'ç',
    };
    return s.split('').map((c) => map[c] ?? c.toLowerCase()).join();
  }

  /// Türkçe büyük harf. `i → İ`, `ı → I`.
  static String buyuk(String s) {
    const map = {
      'i': 'İ', 'ı': 'I', 'ş': 'Ş', 'ğ': 'Ğ',
      'ü': 'Ü', 'ö': 'Ö', 'ç': 'Ç',
    };
    return s.split('').map((c) => map[c] ?? c.toUpperCase()).join();
  }

  /// Aksan/işaret farkını yok sayan arama anahtarı — "sisli" ile "Şişli"
  /// eşleşsin diye.
  static String aramaAnahtari(String s) {
    const map = {
      'ı': 'i', 'ş': 's', 'ğ': 'g', 'ü': 'u', 'ö': 'o', 'ç': 'c',
    };
    return kucuk(s).split('').map((c) => map[c] ?? c).join();
  }

  // ── Alfabetik sıralama ─────────────────────────────────────────────────────
  // Türkçe alfabede ç harfi c'den, ğ g'den, ı i'DEN ÖNCE, ö o'dan, ş s'den,
  // ü u'dan sonra gelir. Unicode kod noktası sıralaması bunların hiçbirini
  // doğru vermez: 'Ç' (0xC7) tüm Latin harflerden sonra gelir, yani
  // `list.sort()` "Çankaya"yı "Zeytinburnu"nun ardına atar.

  static const String _alfabe = 'abcçdefgğhıijklmnoöprsştuüvyz';

  /// Türkçe alfabeye göre karşılaştırma — `sort()` için.
  static int karsilastir(String a, String b) {
    final x = kucuk(a.trim());
    final y = kucuk(b.trim());
    final uzunluk = x.length < y.length ? x.length : y.length;

    for (var i = 0; i < uzunluk; i++) {
      final fark = _harfSirasi(x[i]) - _harfSirasi(y[i]);
      if (fark != 0) return fark;
    }
    return x.length - y.length;
  }

  /// Alfabede olmayan karakterler (boşluk, tire, rakam) harflerden önce
  /// gelsin diye negatif sıra alır; kendi aralarında kod noktasına göre.
  static int _harfSirasi(String harf) {
    final index = _alfabe.indexOf(harf);
    return index >= 0 ? index : harf.codeUnitAt(0) - 0x10000;
  }

  /// Listeyi Türkçe alfabeye göre sıralayıp yeni liste döndürür.
  static List<String> sirala(Iterable<String> liste) =>
      liste.toList()..sort(karsilastir);
}

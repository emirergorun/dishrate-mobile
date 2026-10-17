import 'package:flutter/material.dart' show FontWeight;

/// Uygulamanın font aileleri.
///
/// Uygulamadaki **tek** font tanımı burasıdır. `AppTextStyles` ve `AppTheme`
/// bu sınıfı okur; hiçbir yerde font adı elle yazılmaz.
///
/// Arayüz fontu [active]. Logo yazısı ("decouva") font değil, SVG
/// (`shared/widgets/brand_logo.dart`, 17 Ekim).
///
/// Kalıcı olarak değiştirmek: [active] içindeki `defaultValue`.
/// Kodu değiştirmeden karşılaştırmak:
/// ```
/// flutter run --dart-define=APP_FONT=Poppins
/// ```
abstract final class AppFonts {
  /// Arayüz fontu. Türkçe harflerin tamamı var (Ç Ğ İ Ö Ş Ü ı) ve fi/fl
  /// bitişik harfi yok — "Profil", "fit" gibi kelimelerde i'nin noktası
  /// f'nin kancasına yapışıp "ı" gibi okunmuyor.
  static const String urbanist = 'Urbanist';

  /// Karşılaştırma için ikinci aile (`APP_FONT=Poppins`).
  static const String poppins = 'Poppins';

  /// Arayüzün kullandığı aktif font ailesi.
  static const String active = String.fromEnvironment(
    'APP_FONT',
    defaultValue: urbanist,
  );

  /// Adisyonun fiş yazısı (1.9), sabit genişlikli. Yalnız adisyonda.
  static const String receipt = 'IBMPlexMono';

  // ── Ağırlık skalası ────────────────────────────────────────────────────────
  // Ekranlarda `FontWeight.w600` yerine bu adlar yazılır ki skala tek yerden
  // kaysın. Poppins aynı sayıda Urbanist'ten belirgin kalın çizdiği için skala
  // fonta göre seçiliyor; `APP_FONT=Poppins` ile karşılaştırırken "fazla kalın"
  // hissi geri gelmesin.
  //
  // 900 (Black) ve 700 skalada yok: 26px'lik başlıkların Black olması "fazla
  // kalın" şikâyetinin asıl kaynağıydı. Hiyerarşi artık ağırlıkla değil boyut
  // ve renkle kuruluyor.
  static const bool _poppins = active == poppins;

  /// Büyük başlıklar ("Nerede yedin?", yemek adı).
  static const FontWeight display =
      _poppins ? FontWeight.w500 : FontWeight.w600;

  /// Ekran ve bölüm başlıkları.
  static const FontWeight heading =
      _poppins ? FontWeight.w500 : FontWeight.w600;

  /// Liste öğesi adları, buton yazıları, sayılar.
  static const FontWeight title = FontWeight.w500;

  /// Gövde metni.
  static const FontWeight body = FontWeight.w400;
}

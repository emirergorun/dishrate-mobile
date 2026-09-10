import 'package:flutter/material.dart' show FontWeight;

/// Dishrate font aileleri.
///
/// Uygulamadaki **tek** font tanımı burasıdır. `AppTextStyles` ve `AppTheme`
/// bu sınıfı okur; hiçbir yerde font adı elle yazılmaz. Font değiştirmek için
/// tek yapman gereken [active] değerini değiştirmektir.
///
/// Her iki aile de `pubspec.yaml` içinde aynı ağırlık skalasıyla tanımlıdır:
///   300 Light · 400 Regular (+italic) · 500 Medium (+italic)
///   600 SemiBold · 700 Bold (+italic) · 900 Black
///
/// Kalıcı olarak değiştirmek: aşağıdaki `defaultValue` değerini düzenle.
/// Geçici olarak denemek (kodu değiştirmeden):
/// ```
/// flutter run --dart-define=APP_FONT=Urbanist
/// ```
abstract final class AppFonts {
  /// Logo kelime markasıyla aynı aile (logo "dishrate" yazısı Poppins SemiBold).
  static const String poppins = 'Poppins';

  /// Önceki font — karşılaştırma için duruyor.
  static const String urbanist = 'Urbanist';

  /// Uygulamanın kullandığı aktif font ailesi.
  static const String active = String.fromEnvironment(
    'APP_FONT',
    defaultValue: poppins,
  );

  // ── Ağırlık skalası ────────────────────────────────────────────────────────
  // Poppins aynı sayıda Urbanist'ten belirgin daha kalın çizer; aynı skala
  // iki fontta aynı ağırlıkta durmaz. Bu yüzden ağırlıklar sabit sayı olarak
  // değil, buradaki adlar üzerinden veriliyor.
  //
  // İnce skalayı denemek (kodu değiştirmeden):
  //   flutter run --dart-define=LIGHT_WEIGHTS=true
  static const bool _light = bool.fromEnvironment('LIGHT_WEIGHTS');

  /// En ağır seviye — büyük başlıklar.
  static const FontWeight display = _light ? FontWeight.w700 : FontWeight.w900;

  /// Ekran başlıkları.
  static const FontWeight heading = _light ? FontWeight.w600 : FontWeight.w700;

  /// Kart/bölüm başlıkları, buton yazıları.
  static const FontWeight title = _light ? FontWeight.w500 : FontWeight.w600;

  /// Gövde metni — zaten hafif, iki skalada da aynı.
  static const FontWeight body = FontWeight.w400;
}

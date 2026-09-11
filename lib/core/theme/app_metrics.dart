import 'package:flutter/animation.dart';

/// Köşe yuvarlaklığı ölçeği.
///
/// Kod tabanında 2 ile 20 arasında 11 farklı değer vardı; yan yana duran
/// öğeler farklı yuvarlanınca düzen parça parça görünüyordu. Kural:
///
///   sm   → küçük görseller (menü satırı fotoğrafı, harf kutusu)
///   md   → fotoğraflar, butonlar, giriş alanları
///   lg   → alt panellerin üst köşeleri
///   pill → yalnızca filtre çipleri
///
/// İç öğe dış öğeden daha az yuvarlanır; tersi kenarları "şişkin" gösteriyor.
abstract final class AppRadius {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 20;
  static const double pill = 999;
}

/// Boşluk ölçeği — 4'ün katları. Ekran kenarı her yerde [screen].
abstract final class AppSpace {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double screen = 20;
  static const double xl = 24;
  static const double xxl = 32;

  /// Keşfet'teki bölümler arası. Başlıklar bölümü ayırmaya yetmediği için
  /// kutu/çizgi yerine boşlukla ayrılıyor.
  static const double section = 40;
}

/// Hareket süreleri. Uzun animasyon puanlama gibi hızlı bir döngüyü
/// yavaşlatıyor; hepsi 250 ms altında.
abstract final class AppMotion {
  static const Duration fast = Duration(milliseconds: 120);
  static const Duration base = Duration(milliseconds: 220);
  static const Curve curve = Curves.easeOutCubic;
}

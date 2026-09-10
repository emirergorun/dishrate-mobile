import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Dishrate marka görselleri.
///
/// Kaynak: `Dishrate logo/claude küçük yıldız.html` içindeki **A — yan tabak
/// (tek kalınlıkta yay)** tasarımı. Seçilen varyantlar:
///   • [DishrateWordmark] → "Logo + dishrate yazısı" 1 numara
///     (turuncu işaret + beyaz yazı; burada zemin şeffaf tutulur)
///   • [DishrateMark]     → "Uygulama ikonu" 1 numara
///     (tabak ve yıldız turuncu; yalnızca işaret)
///
/// Yazı rengi temaya göre değişir: koyu temada beyaz, açık temada siyah.
/// İşaretin turuncusu her iki temada da aynıdır.

/// İşaret + "dishrate" yazısından oluşan yatay logo kilidi.
///
/// [width] logonun genişliğidir; yükseklik oranı korunarak hesaplanır.
/// Marka kılavuzu 120 px altına inilmemesini söylüyor — altında tabak inceliyor.
class DishrateWordmark extends StatelessWidget {
  const DishrateWordmark({super.key, this.width = 180});

  /// Kaynak görselin en-boy oranı (1070 × 242).
  static const double _aspectRatio = 1070 / 242;

  final double width;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      context.isDark
          ? 'assets/branding/logo_wordmark_dark.png'
          : 'assets/branding/logo_wordmark_light.png',
      width: width,
      height: width / _aspectRatio,
      fit: BoxFit.contain,
      semanticLabel: 'Dishrate',
    );
  }
}

/// Yazısız işaret — tabak + yıldız. Dar alanlar için (AppBar, avatar, rozet).
class DishrateMark extends StatelessWidget {
  const DishrateMark({super.key, this.size = 72});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/branding/icon_foreground.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
      semanticLabel: 'Dishrate',
    );
  }
}

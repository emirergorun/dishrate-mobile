import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Dishrate marka görselleri.
///
/// Kaynak: `DISHRATE EN SON LOGO` paketi (22 Eylül 2026) — geometrik küçük
/// `d` işareti + Poppins Bold "dishrate" kelime markası. Kullanılan dosyalar
/// paketin zeminsiz ("extra") sürümleri:
///   • [DishrateWordmark] → işaret + yazı; yazı rengi temaya göre değişir
///   • [DishrateMark]     → yalnız işaret (turuncu `d`)
///
/// İşaretin turuncusu her iki temada da aynı: koyu temada beyaz, açık temada
/// siyah olan yalnızca yazıdır. İşaretin oranları ve kilidin boşluğu paketin
/// kılavuzunda sabit — görselleri yeniden ölçeklemek dışında değiştirme.

/// İşaret + "dishrate" yazısından oluşan yatay logo kilidi.
///
/// [width] logonun genişliğidir; yükseklik oranı korunarak hesaplanır.
class DishrateWordmark extends StatelessWidget {
  const DishrateWordmark({super.key, this.width = 180, this.onBrand = false});

  /// Kaynak görselin en-boy oranı (2400 × 989). Dosya değişirse burası da
  /// değişmeli; oran tutmazsa logo ezilir.
  static const double aspectRatio = 2400 / 989;

  /// Görselin kaç piksel genişlikte çözüleceği.
  ///
  /// Kaynak 2400 px; tam boy çözmek açılışta birkaç kare sürüyor ve logo
  /// gecikmeli beliriyordu. 900 px, 3x ekranda 300 pt'lik en büyük
  /// kullanımımıza yetiyor. Tek değer: açılış ve giriş ekranı aynı önbellek
  /// kaydını paylaşsın, ikisi arasında yeniden çözme olmasın.
  static const int decodeWidth = 900;

  /// Önceden çözmek için (bkz. `main.dart`).
  static ImageProvider provider(bool dark) => ResizeImage(
        AssetImage(dark ? darkAsset : lightAsset),
        width: decodeWidth,
      );

  /// Turuncu zemin üstündeki sürüm (açılış karesi).
  static ImageProvider get brandProvider =>
      const ResizeImage(AssetImage(brandAsset), width: decodeWidth);

  static const String darkAsset = 'assets/branding/logo_wordmark_dark.png';
  static const String lightAsset = 'assets/branding/logo_wordmark_light.png';

  /// Tamamı beyaz sürüm; yalnızca turuncu zemin üstünde kullanılır. Üç dosyada
  /// da logo aynı yerde ve aynı ölçüde — aralarında geçiş yaparken kaymaz.
  static const String brandAsset = 'assets/branding/logo_wordmark_brand.png';

  final double width;

  /// Turuncu zemin üstünde mi duruyor: öyleyse işaret de yazı da beyaz.
  final bool onBrand;

  @override
  Widget build(BuildContext context) {
    return Image(
      image: onBrand ? brandProvider : provider(context.isDark),
      width: width,
      height: width / aspectRatio,
      fit: BoxFit.contain,
      semanticLabel: 'Dishrate',
    );
  }
}

/// Yazısız işaret — turuncu `d`. Dar alanlar için (AppBar, avatar, rozet).
class DishrateMark extends StatelessWidget {
  const DishrateMark({super.key, this.size = 72});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/branding/mark.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
      semanticLabel: 'Dishrate',
    );
  }
}

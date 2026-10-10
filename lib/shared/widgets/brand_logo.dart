import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/app_brand.dart';

/// Marka görselleri (Decouva; ad `AppBrand`'da).
///
/// Kaynak: `DISHRATE KESİN LOGO` paketinin `d` işareti (23 Eylül 2026;
/// gövdesi dikeyden 9° sağa yatık) + Poppins Bold kelime markası. Ad
/// Decouva olunca (Ekim 2026) yazı "decouva" ile yeniden üretildi (Poppins
/// Bold 355 pt, harf aralığı -7 — eskisiyle aynı ayar), işaret ve tuval aynı;
/// kalıcı logo gelene kadar geçici. Kullanılan dosyalar paketin zeminsiz ("extra") sürümleri:
///   • [BrandWordmark] → işaret + yazı; yazı rengi temaya göre değişir
///   • [BrandMark]     → yalnız işaret (turuncu `d`)
///
/// İşaretin turuncusu her iki temada da aynı: koyu temada beyaz, açık temada
/// siyah olan yalnızca yazıdır. İşaretin oranları ve kilidin boşluğu paketin
/// kılavuzunda sabit — görselleri yeniden ölçeklemek dışında değiştirme.

/// İşaret + "decouva" yazısından oluşan yatay logo kilidi.
///
/// [width] logonun genişliğidir; yükseklik oranı korunarak hesaplanır.
class BrandWordmark extends StatelessWidget {
  const BrandWordmark({super.key, this.width = 180, this.onBrand = false});

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
      semanticLabel: AppBrand.name,
    );
  }
}

/// Yazısız işaret — turuncu `d`. Dar alanlar için (AppBar, avatar, rozet).
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 72});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/branding/mark.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
      semanticLabel: AppBrand.name,
    );
  }
}

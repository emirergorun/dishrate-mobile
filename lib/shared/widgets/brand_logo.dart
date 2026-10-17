import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/constants/app_brand.dart';
import '../../core/theme/app_colors.dart';

/// Marka görselleri (Decouva; ad `AppBrand`'da).
///
/// Logo 17 Ekim 2026: üç pul üst üste (altta iki sarı, üstte "d"li turuncu)
/// + özel "d" ile başlayan "decouva" yazısı. Kaynak repo dışındaki
/// `decouva-logo-paketi/` (üst klasör); dosyalar `assets/brand/svg/`'de,
/// paketteki Türkçe adların İngilizcesiyle.
///
/// Logo yazısı bir görseldir, fontla yazılmaz. Paketin kuralları: oranlar
/// korunur, renk/efekt değişmez; pul yığını 40 px'ten, yazı 14 px'ten küçük
/// kullanılmaz.
abstract final class BrandAssets {
  static const _dir = 'assets/brand/svg';

  /// "decouva" yazısı, tek renk (çizerken boyanır).
  static const wordmark = '$_dir/wordmark.svg';

  /// Amblem + yazı, yan yana. `onDark`: koyu zemin için (beyaz yazı).
  static const horizontalOnDark = '$_dir/logo_horizontal_on_dark.svg';
  static const horizontalOnLight = '$_dir/logo_horizontal_on_light.svg';

  /// Yatay logo, tamamı siyah (amblem dahil). Adisyon: termal fiş gibi
  /// basılmış görünsün, kağıttaki tek renk damga olsun (Emir, 17 Ekim).
  /// Pakete sonradan eklendi (`logo-yatay-siyah.svg`).
  static const horizontalMono = '$_dir/logo_horizontal_mono.svg';

  /// Amblem üstte, yazı altta (açılış ekranı).
  static const verticalOnDark = '$_dir/logo_vertical_on_dark.svg';
  static const verticalOnLight = '$_dir/logo_vertical_on_light.svg';

  /// SVG'ler önceden çözülür; açılışta ve girişte logo gecikmeli belirmesin
  /// (bkz. `main.dart`).
  static Future<void> precache() => Future.wait([
        for (final path in [
          wordmark,
          horizontalOnDark,
          horizontalOnLight,
          horizontalMono,
          verticalOnDark,
          verticalOnLight,
        ])
          () {
            final loader = SvgAssetLoader(path);
            return svg.cache.putIfAbsent(
                loader.cacheKey(null), () => loader.loadBytes(null));
          }(),
      ]);
}

/// Yalnız "decouva" yazısı; varsayılan turuncu (Keşfet başlığı).
class BrandWordmark extends StatelessWidget {
  const BrandWordmark({super.key, this.height = 18, this.color});

  /// Kaynağın en-boy oranı (viewBox 4404.84 × 748).
  static const double aspectRatio = 4404.84 / 748;

  final double height;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      BrandAssets.wordmark,
      height: height,
      width: height * aspectRatio,
      colorFilter:
          ColorFilter.mode(color ?? AppColors.primary, BlendMode.srcIn),
      semanticsLabel: AppBrand.name,
    );
  }
}

/// Amblem + yazı. [onDark] verilmezse temaya göre seçilir: koyu temada beyaz,
/// açık temada siyah yazılı sürüm. Amblem iki sürümde de aynı.
class BrandLogo extends StatelessWidget {
  const BrandLogo({
    super.key,
    required this.width,
    this.vertical = false,
    this.onDark,
  });

  /// Tamamı siyah yatay logo (adisyon).
  static Widget mono({Key? key, required double width}) => SvgPicture.asset(
        BrandAssets.horizontalMono,
        key: key,
        width: width,
        height: width / horizontalAspectRatio,
        semanticsLabel: AppBrand.name,
      );

  /// Kaynakların en-boy oranları (viewBox).
  static const double horizontalAspectRatio = 3853.52 / 1000;
  static const double verticalAspectRatio = 1213.48 / 1337.22;

  final double width;
  final bool vertical;
  final bool? onDark;

  @override
  Widget build(BuildContext context) {
    final dark = onDark ?? context.isDark;
    final String asset;
    final double ratio;
    if (vertical) {
      asset = dark ? BrandAssets.verticalOnDark : BrandAssets.verticalOnLight;
      ratio = verticalAspectRatio;
    } else {
      asset =
          dark ? BrandAssets.horizontalOnDark : BrandAssets.horizontalOnLight;
      ratio = horizontalAspectRatio;
    }
    return SvgPicture.asset(
      asset,
      width: width,
      height: width / ratio,
      semanticsLabel: AppBrand.name,
    );
  }
}

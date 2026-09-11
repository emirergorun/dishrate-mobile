import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';

import '../../core/theme/app_colors.dart';

/// Yemek fotoğrafı — yemek görseli gösteren her yer bunu kullanır.
///
/// `Image.network` önbelleğe almıyordu: keşfet şeritleri kaydırıldıkça aynı
/// görseller yeniden iniyor, her seferinde boş kutu yanıp sönüyordu.
/// Bellekte ekrandaki boyutta kopya tutuluyor; 160 px'lik kart için tam boy
/// fotoğrafı açmak yatay şeritlerde takılmaya yol açıyor.
class DishPhoto extends StatelessWidget {
  const DishPhoto({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.radius = 0,
    this.iconSize = 24,
  });

  final String? url;
  final double? width;
  final double? height;
  final double radius;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final hasUrl = url != null && url!.isNotEmpty;
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final cacheWidth =
        width != null && width!.isFinite ? (width! * dpr).round() : null;

    Widget child = hasUrl
        ? CachedNetworkImage(
            imageUrl: url!,
            width: width,
            height: height,
            fit: BoxFit.cover,
            memCacheWidth: cacheWidth,
            fadeInDuration: const Duration(milliseconds: 180),
            fadeOutDuration: Duration.zero,
            // Yüklenirken ikon yok: şerit dolusu çatal-bıçak ikonu, fotoğraf
            // gelmeden "burada görsel yok" diyormuş gibi okunuyordu.
            placeholder: (_, __) => const _Placeholder(iconSize: null),
            errorWidget: (_, __, ___) => _Placeholder(iconSize: iconSize),
          )
        : _Placeholder(iconSize: iconSize);

    child = SizedBox(width: width, height: height, child: child);
    if (radius > 0) {
      child = ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: child,
      );
    }
    return child;
  }
}

/// Fotoğraf yokken yüzey tonu. Önceki yer tutucular palet dışı mor ve lacivert
/// zeminler kullanıyordu; ekrandaki tek "yabancı" renk onlardı.
class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.iconSize});

  /// `null` → ikonsuz (yükleniyor).
  final double? iconSize;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      // Sabit "elevated" ton koyu temada panel zeminiyle aynı olduğu için kutu
      // kayboluyor, ortada yalnızca ikon kalıyordu.
      color: context.fillColor,
      child: iconSize == null
          ? const SizedBox.expand()
          : Center(
              child: Icon(
                TablerIcons.tools_kitchen_2,
                size: iconSize,
                color: context.textTertiaryColor,
              ),
            ),
    );
  }
}

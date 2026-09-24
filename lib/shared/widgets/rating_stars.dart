import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// Puanın sözlü karşılığı; puan girilen her yerde aynı ölçek (1.5 turu).
///
/// Her yarım yıldızın kendi etiketi var: yarım yıldız seçen kullanıcı
/// değişikliği yazıda da görsün. Önceden değerlendirme ekranı ile günlükteki
/// düzenleme paneli ayrı listeler kullanıyordu ve aynı puana farklı yazı
/// çıkıyordu (2 yıldız: "Kötü" / "İdare eder").
String ratingLabel(double score) {
  if (score <= 1.0) return 'Berbat';
  if (score <= 1.5) return 'Çok kötü';
  if (score <= 2.0) return 'Kötü';
  if (score <= 2.5) return 'İdare eder';
  if (score <= 3.0) return 'Fena değil';
  if (score <= 3.5) return 'İyi';
  if (score <= 4.0) return 'Çok iyi';
  if (score <= 4.5) return 'Harika';
  return 'Mükemmel';
}

/// Tek yıldız: dolu, yarım ya da boş.
///
/// Boş yıldız soluk dolgu değil ÇERÇEVE. Koyu temada soluk dolgu zeminle
/// karışıp kayboluyordu (bkz. FRONTEND-DEVIR, "Boş yıldızın çerçeveli olması").
/// Yarım yıldız da çerçevenin üstüne sol yarısı dolu yıldız bindirilerek
/// çiziliyor; ikon setinin kendi "yarım yıldız"ı sağ yarıyı hiç çizmiyor ve
/// yıldızın biçimi bozuluyordu.
class StarGlyph extends StatelessWidget {
  const StarGlyph({
    super.key,
    required this.fill,
    required this.size,
    this.color,
    this.emptyColor,
  });

  /// 0 → boş, 0.5 → yarım, 1 → dolu.
  final double fill;
  final double size;
  final Color? color;
  final Color? emptyColor;

  @override
  Widget build(BuildContext context) {
    final on = color ?? context.starColor;
    final off = emptyColor ?? context.textTertiaryColor;

    if (fill >= 1) {
      return Icon(TablerIcons.star_filled, size: size, color: on);
    }
    if (fill <= 0) return Icon(TablerIcons.star, size: size, color: off);

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          Icon(TablerIcons.star, size: size, color: off),
          ClipRect(
            child: Align(
              alignment: Alignment.centerLeft,
              widthFactor: 0.5,
              child: Icon(TablerIcons.star_filled, size: size, color: on),
            ),
          ),
        ],
      ),
    );
  }
}

/// Salt okunur beş yıldız. Puan GİRİŞİ değil — o değerlendirme adımında.
class StarRow extends StatelessWidget {
  const StarRow({super.key, required this.rating, this.size = 12});

  final double rating;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '5 üzerinden ${rating.toStringAsFixed(1).replaceAll('.', ',')} yıldız',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < 5; i++) ...[
            if (i > 0) SizedBox(width: size * 0.12),
            StarGlyph(
              // 0.25 / 0.75 eşikleri en yakın yarıma yuvarlıyor: 4.2 dört
              // yıldız, 4.3 dört buçuk görünür. Aşağı yuvarlamak 4.7'yi dört
              // buçuk gösterip rakamla çelişiyordu.
              fill: (rating - i) >= 0.75
                  ? 1
                  : (rating - i) >= 0.25
                      ? 0.5
                      : 0,
              size: size,
            ),
          ],
        ],
      ),
    );
  }
}

/// Satır içi puan: tek dolu yıldız + rakam. Puan yoksa açıkça söyler; "0.0"
/// göstermek "kötü puan almış" gibi okunuyordu.
class RatingInline extends StatelessWidget {
  const RatingInline({
    super.key,
    required this.rating,
    this.emptyText = 'Henüz puan yok',
  });

  final double rating;
  final String emptyText;

  @override
  Widget build(BuildContext context) {
    if (rating <= 0) {
      return Text(
        emptyText,
        style: AppTextStyles.caption.copyWith(color: context.textTertiaryColor),
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(TablerIcons.star_filled, size: 13, color: context.starColor),
        const SizedBox(width: 4),
        Text(
          rating.toStringAsFixed(1),
          style: AppTextStyles.ratingSmall
              .copyWith(color: context.textPrimaryColor),
        ),
      ],
    );
  }
}

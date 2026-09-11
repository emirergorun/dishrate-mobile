import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_metrics.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/pressable.dart';

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.onSeeAll,
  });

  final String title;
  final String? subtitle;
  final VoidCallback? onSeeAll;

  /// Başlığın üstünde, dokunma alanına katılan boşluk. Bölümler arası boşluk
  /// bunu düşerek veriliyor; başlık görünüşte yerinden oynamıyor.
  static const double tapInset = AppSpace.sm;

  @override
  Widget build(BuildContext context) {
    final header = Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpace.screen, tapInset, AppSpace.screen, AppSpace.md),
      // "Tümünü gör" başlığın satırına hizalı. Önceden son satıra (alt
      // başlığa) hizalıydı; alt başlığı olan ve olmayan bölümler yan yana
      // gelince bağlantı her bölümde başka yükseklikte duruyordu.
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          // Başlık bloğu genişleyebilir alanda: uzun alt başlık önceden
          // "Tümünü gör" ile çakışıyordu.
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.titleLarge
                      .copyWith(color: context.textPrimaryColor),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: AppSpace.xxs),
                  Text(
                    subtitle!,
                    style: AppTextStyles.caption
                        .copyWith(color: context.textSecondaryColor),
                  ),
                ],
              ],
            ),
          ),
          if (onSeeAll != null) ...[
            const SizedBox(width: AppSpace.md),
            // Turuncu yalnızca ana eylemde; altı bölümde altı turuncu
            // bağlantı ekranın vurgusunu dağıtıyordu.
            Text(
              'Tümünü gör',
              style: AppTextStyles.label
                  .copyWith(color: context.textSecondaryColor),
            ),
          ],
        ],
      ),
    );

    if (onSeeAll == null) return header;

    // Dokunma hedefi yalnızca "Tümünü gör" yazısı değil, başlığın tamamı.
    // Yazı 36 pt'lik bir butondu; onu 44'e büyütmek başlık satırını uzatıp
    // alt başlıksız bölümlerde ritmi bozuyordu.
    return Pressable(
      onTap: onSeeAll,
      scale: 1,
      semanticLabel: '$title, tümünü gör',
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: AppSize.minTap),
        child: header,
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_metrics.dart';
import '../../../core/theme/app_text_styles.dart';

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

  @override
  Widget build(BuildContext context) {
    return Padding(
      // Sağ boşluk küçük: "Tümünü gör" butonunun kendi dokunma alanı var,
      // yazısı yine de ekran kenarıyla hizalı duruyor.
      padding: const EdgeInsets.fromLTRB(
          AppSpace.screen, 0, AppSpace.sm, AppSpace.md + 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
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
                  const SizedBox(height: 3),
                  Text(
                    subtitle!,
                    style: AppTextStyles.caption
                        .copyWith(color: context.textSecondaryColor),
                  ),
                ],
              ],
            ),
          ),
          if (onSeeAll != null)
            TextButton(
              onPressed: onSeeAll,
              style: TextButton.styleFrom(
                // Turuncu yalnızca ana eylemde; altı bölümde altı turuncu
                // bağlantı ekranın vurgusunu dağıtıyordu.
                foregroundColor: context.textSecondaryColor,
                textStyle: AppTextStyles.label,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                minimumSize: const Size(0, 36),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('Tümünü gör'),
            ),
        ],
      ),
    );
  }
}

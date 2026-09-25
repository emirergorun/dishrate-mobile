import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_metrics.dart';
import '../../core/theme/app_text_styles.dart';

/// Panelin içindeki hata kutusu. Panellerde SnackBar kullanılmaz:
/// ScaffoldMessenger panelin altındaki Scaffold'a bağlı, mesaj panelin
/// arkasında kalıyor.
class SheetError extends StatelessWidget {
  const SheetError(this.message, {super.key});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Container(
        width: double.infinity,
        padding:
            const EdgeInsets.symmetric(horizontal: AppSpace.md, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.error.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            const Icon(TablerIcons.alert_circle,
                color: AppColors.error, size: 18),
            const SizedBox(width: AppSpace.sm),
            Expanded(
              child: Text(message,
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.error)),
            ),
          ],
        ),
      ),
    );
  }
}

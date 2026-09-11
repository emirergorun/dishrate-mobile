import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_metrics.dart';
import '../../features/rating/screens/add_rating_screen.dart';

/// Değerlendirme akışını taşıyan alt panel.
///
/// Akış üç ayrı yerden açılıyor: alt menüdeki "+", keşfet ekranındaki yemek
/// kartı ve harita üzerindeki restoran menüsü. Üçü de aynı klavye
/// davranışına ihtiyaç duyduğu için panel burada tek yerde duruyor —
/// daha önce yalnızca "+" akışı düzeltilmiş, diğer ikisinde yorum alanı
/// klavyenin altında kalmaya devam etmişti.
class RatingSheet extends StatelessWidget {
  const RatingSheet({super.key});

  /// Panelin nasıl açılacağı da paylaşılıyor: `isScrollControlled` olmadan
  /// klavye hesabı çalışmaz.
  static Future<T?> show<T>(BuildContext context) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const RatingSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final keyboard = media.viewInsets.bottom;

    // Klavye açılınca panel yukarı kayar ve boyu küçülür. Sabit yükseklikte
    // bırakılırsa yorum alanı klavyenin altında kalıyor.
    final available = media.size.height - media.padding.top - keyboard;
    final height = math.min(media.size.height * 0.92, available);

    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: keyboard),
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: context.sheetColor,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 8),
            // Tutma çubuğu — yemek panelindekiyle aynı ölçü.
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: context.dividerColor,
                borderRadius: BorderRadius.circular(AppRadius.xs),
              ),
            ),
            const SizedBox(height: 8),
            const Expanded(child: AddRatingScreen()),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_metrics.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/relative_date.dart';
import '../models/menu_item_review_model.dart';
import 'dish_photo.dart';
import 'photo_viewer.dart';
import 'pressable.dart';
import 'rating_stars.dart';

/// Tek bir değerlendirme. Yemek paneli önizlemesi ve tüm yorumlar ekranı aynı
/// satırı kullanıyor.
///
/// Hiyerarşi bilerek çevrildi: önceden yorum metni 12px italik gri ve tırnak
/// içindeydi, isim kalın, yıldızlar sarıydı. Bu uygulamada ürün yorumun
/// kendisi; en okunur şey o olmalı.
class ReviewTile extends StatelessWidget {
  const ReviewTile({super.key, required this.review, this.maxLines});

  final MenuItemReviewModel review;

  /// Önizlemede uzun yorum kısaltılır; tüm yorumlar ekranında sınırsız.
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    final comment = review.comment?.trim() ?? '';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Initials(name: review.reviewerName),
        const SizedBox(width: AppSpace.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // İsim bloğu kalan genişliğin tamamını alıyor. Önceden isim
                  // ile Spacer alanı yarı yarıya paylaşıyor, tarih sağ kenar
                  // yerine satırın ortasına düşüyordu.
                  Expanded(
                    child: Row(
                      children: [
                        Flexible(
                          child: Text(
                            review.reviewerName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.label
                                .copyWith(color: context.textPrimaryColor),
                          ),
                        ),
                        if (review.mine) ...[
                          const SizedBox(width: 6),
                          Text(
                            'Sen',
                            style: AppTextStyles.label
                                .copyWith(color: context.accentTextColor),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpace.sm),
                  if (review.ratedAt != null)
                    Text(
                      RelativeDate.timeAgo(review.ratedAt!),
                      style: AppTextStyles.caption
                          .copyWith(color: context.textTertiaryColor),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              StarRow(rating: review.score, size: 12),
              if (comment.isNotEmpty) ...[
                const SizedBox(height: AppSpace.sm),
                Text(
                  comment,
                  maxLines: maxLines,
                  overflow: maxLines == null ? null : TextOverflow.ellipsis,
                  style: AppTextStyles.bodyMedium
                      .copyWith(color: context.textPrimaryColor),
                ),
              ],
              if ((review.photoUrl ?? '').isNotEmpty) ...[
                const SizedBox(height: AppSpace.sm),
                Pressable(
                  onTap: () => PhotoViewer.open(context, review.photoUrl!),
                  semanticLabel: 'Değerlendirme fotoğrafını büyüt',
                  child: DishPhoto(
                    url: review.photoUrl,
                    width: 96,
                    height: 96,
                    radius: AppRadius.sm,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Baş harfler. Her yorumcuya aynı "kişi" ikonunu koymak herkesi aynı kişi
/// gibi gösteriyordu; maskeli isimden ("D*** A***") bile iki harf ayırt edici.
class _Initials extends StatelessWidget {
  const _Initials({required this.name});
  final String name;

  String get _letters {
    final parts = name
        .split(RegExp(r'\s+'))
        .map((p) => p.replaceAll(RegExp(r'[^A-Za-zÇĞİÖŞÜçğıöşü]'), ''))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    return parts.take(2).map((p) => p.characters.first).join();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: context.fillColor,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Text(
        _letters,
        style: AppTextStyles.label.copyWith(
          fontSize: 12,
          color: context.textSecondaryColor,
        ),
      ),
    );
  }
}

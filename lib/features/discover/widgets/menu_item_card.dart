import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_metrics.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/models/menu_item_model.dart';
import '../../../shared/widgets/dish_photo.dart';
import '../../../shared/widgets/pressable.dart';
import '../../../shared/widgets/rating_stars.dart';

/// Yemek kartı: fotoğraf üstte, bilgiler altta.
///
/// Önceki kartta fotoğrafın üstüne beş bilgi yığılmıştı (kategori rozeti, puan
/// rozeti, restoran, ad, ilçe). Fotoğrafın üstünde artık hiçbir şey yok —
/// yemek görünüyor, bilgiler altta okunma sırasıyla duruyor.
///
/// Keşfet'teki bütün kartlar bu kart; bölümler birbirinden [photoAspect] ve
/// dizilişle ayrılıyor. Önceden iki bölüm yazıyı fotoğrafın üstüne koyu
/// degradeyle yazıyordu: yemeğin alt kısmı kararıyor, aynı ekranda iki ayrı
/// kart dili konuşuyordu.
///
/// Genişliği dışarıdan gelir (şeritte sabit, ızgarada sütun kadar).
class MenuItemCard extends StatelessWidget {
  const MenuItemCard({
    super.key,
    required this.item,
    this.onTap,
    this.photoAspect = posterAspect,
  });

  final MenuItemModel item;
  final VoidCallback? onTap;

  /// Fotoğraf oranı (en / boy).
  final double photoAspect;

  /// Dikey şeridin ve "Tümünü gör" ızgarasının oranı. Yemek fotoğrafları yatay
  /// çekiliyor ama dikey kırpım şeritte daha çok kart gösteriyor; 5:6 tabağı
  /// kesmeyecek kadar geniş.
  static const double posterAspect = 5 / 6;

  /// Fotoğrafın altındaki metin bloğunun yüksekliği (yazı ölçeği uygulanmadan).
  /// Şerit ve ızgara yüksekliği bununla hesaplanıyor; ad iki satıra taşsa da
  /// kartlar kesilmesin.
  static const double textBlockHeight = 84;

  /// Verilen genişlikteki kartın toplam yüksekliği.
  static double heightFor(
    BuildContext context,
    double width, {
    double photoAspect = posterAspect,
  }) =>
      width / photoAspect +
      AppSpace.md +
      MediaQuery.textScalerOf(context).scale(textBlockHeight);

  @override
  Widget build(BuildContext context) {
    final meta = [item.restaurantName, item.district]
        .where((e) => e != null && e.isNotEmpty)
        .join(' · ');

    return Pressable(
      onTap: onTap,
      semanticLabel: item.name,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          AspectRatio(
            aspectRatio: photoAspect,
            child: DishPhoto(
              url: item.photoUrl,
              radius: AppRadius.md,
              iconSize: 28,
            ),
          ),
          const SizedBox(height: AppSpace.md),
          Text(
            item.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style:
                AppTextStyles.titleSmall.copyWith(color: context.textPrimaryColor),
          ),
          const SizedBox(height: AppSpace.xxs),
          Text(
            meta,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style:
                AppTextStyles.caption.copyWith(color: context.textSecondaryColor),
          ),
          const SizedBox(height: AppSpace.xs),
          RatingInline(rating: item.averageRating),
        ],
      ),
    );
  }
}

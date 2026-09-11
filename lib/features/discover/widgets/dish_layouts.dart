import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_metrics.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/models/menu_item_model.dart';
import '../../../shared/widgets/dish_photo.dart';
import '../../../shared/widgets/pressable.dart';
import '../../../shared/widgets/rating_stars.dart';
import 'menu_item_card.dart';

// Keşfet bölümlerinin düzenleri.
//
// Altı bölümün hepsi aynı yatay kart şeridiyle dizilince ekranda göze ilk
// çarpan bir yer kalmıyor ve her bölüm bir öncekinin kopyası gibi okunuyordu.
// Bölümlerin sayısı ve verisi aynı; yalnızca kompozisyon değişiyor.

typedef DishTap = void Function(MenuItemModel item);

String _meta(MenuItemModel item) => [item.restaurantName, item.district]
    .where((e) => e != null && e.isNotEmpty)
    .join(' · ');

// ── Sıralı liste ──────────────────────────────────────────────────────────────

/// Numaralı liste. Bölümler zaten puana göre sıralı; sıra numarası bunu
/// görünür kılıyor. [withLead] açıkken birinci yemek büyük fotoğrafla açılıyor
/// — ekranın bir giriş noktası olsun diye.
class DishRankedList extends StatelessWidget {
  const DishRankedList({
    super.key,
    required this.items,
    required this.onTap,
    this.withLead = false,
  });

  final List<MenuItemModel> items;
  final DishTap onTap;
  final bool withLead;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.screen),
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++)
            if (i == 0 && withLead)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpace.sm),
                child: _LeadItem(item: items[0], onTap: () => onTap(items[0])),
              )
            else
              DishRankRow(
                rank: i + 1,
                item: items[i],
                onTap: () => onTap(items[i]),
              ),
        ],
      ),
    );
  }
}

class _LeadItem extends StatelessWidget {
  const _LeadItem({required this.item, required this.onTap});
  final MenuItemModel item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      scale: 0.985,
      semanticLabel: '1. ${item.name}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 16 / 10,
            child: DishPhoto(
              url: item.photoUrl,
              radius: AppRadius.md,
              iconSize: 36,
            ),
          ),
          const SizedBox(height: AppSpace.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _RankNumber(rank: 1),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.titleMedium
                          .copyWith(color: context.textPrimaryColor),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _meta(item),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption
                          .copyWith(color: context.textSecondaryColor),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpace.md),
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: RatingInline(rating: item.averageRating),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Sıralı listenin tek satırı. Restoran menüsü de aynı satırı kullanıyor.
class DishRankRow extends StatelessWidget {
  const DishRankRow({
    super.key,
    required this.rank,
    required this.item,
    required this.onTap,
    this.showRestaurant = true,
    this.note,
  });

  /// Sıra. Puanı olmayan yemeklerde boş: puansız yemeğe sıra numarası
  /// vermek "12. en iyi" gibi okunuyor.
  final int? rank;
  final MenuItemModel item;
  final VoidCallback onTap;

  /// Restoran sayfasında restoran adını her satırda tekrarlamaya gerek yok.
  final bool showRestaurant;

  /// Adın üstünde küçük vurgulu not ("Önerilen" gibi).
  final String? note;

  @override
  Widget build(BuildContext context) {
    final meta = showRestaurant ? _meta(item) : (item.categoryName ?? '');

    return Pressable(
      onTap: onTap,
      semanticLabel: rank == null ? item.name : '$rank. ${item.name}',
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            _RankNumber(rank: rank),
            DishPhoto(
              url: item.photoUrl,
              width: 56,
              height: 56,
              radius: AppRadius.sm,
              iconSize: 20,
            ),
            const SizedBox(width: AppSpace.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (note != null) ...[
                    Text(
                      note!,
                      style: AppTextStyles.label.copyWith(
                        fontSize: 12,
                        color: context.accentTextColor,
                      ),
                    ),
                    const SizedBox(height: 1),
                  ],
                  Text(
                    item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.titleSmall
                        .copyWith(color: context.textPrimaryColor),
                  ),
                  if (meta.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      meta,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption
                          .copyWith(color: context.textSecondaryColor),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: AppSpace.md),
            RatingInline(rating: item.averageRating, emptyText: 'Puan yok'),
          ],
        ),
      ),
    );
  }
}

class _RankNumber extends StatelessWidget {
  const _RankNumber({required this.rank});
  final int? rank;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 28,
      child: Text(
        rank == null ? '' : '$rank',
        style: AppTextStyles.titleMedium.copyWith(
          fontWeight: FontWeight.w500,
          fontFeatures: AppTextStyles.tabular,
          color: context.textTertiaryColor,
        ),
      ),
    );
  }
}

// ── Dikey kart şeridi ─────────────────────────────────────────────────────────

class DishPosterCarousel extends StatelessWidget {
  const DishPosterCarousel({
    super.key,
    required this.items,
    required this.onTap,
  });

  final List<MenuItemModel> items;
  final DishTap onTap;

  static const double _cardWidth = 148;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MenuItemCard.heightFor(context, _cardWidth),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: AppSpace.screen),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpace.md),
        itemBuilder: (context, i) => SizedBox(
          width: _cardWidth,
          child: MenuItemCard(item: items[i], onTap: () => onTap(items[i])),
        ),
      ),
    );
  }
}

// ── Geniş kart şeridi ─────────────────────────────────────────────────────────

class DishWideCarousel extends StatelessWidget {
  const DishWideCarousel({
    super.key,
    required this.items,
    required this.onTap,
  });

  final List<MenuItemModel> items;
  final DishTap onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 176,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: AppSpace.screen),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpace.md),
        itemBuilder: (context, i) => SizedBox(
          width: 264,
          child: DishOverlayCard(item: items[i], onTap: () => onTap(items[i])),
        ),
      ),
    );
  }
}

// ── Kare ızgara ───────────────────────────────────────────────────────────────

/// 2×2 ızgara. Hücre sayısı eldeki yemek kadar: tek sayıda yemek varsa
/// boş hücre bırakmak yerine çift sayıya iniliyor.
class DishTileGrid extends StatelessWidget {
  const DishTileGrid({
    super.key,
    required this.items,
    required this.onTap,
  });

  final List<MenuItemModel> items;
  final DishTap onTap;

  @override
  Widget build(BuildContext context) {
    final count = items.length >= 4 ? 4 : (items.length >= 2 ? 2 : 1);
    final shown = items.take(count).toList();

    Widget tile(MenuItemModel item, double aspect) => AspectRatio(
          aspectRatio: aspect,
          child: DishOverlayCard(item: item, onTap: () => onTap(item)),
        );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.screen),
      child: count == 1
          ? tile(shown[0], 16 / 10)
          : Column(
              children: [
                for (var r = 0; r < count; r += 2) ...[
                  if (r > 0) const SizedBox(height: AppSpace.md),
                  Row(
                    children: [
                      Expanded(child: tile(shown[r], 1)),
                      const SizedBox(width: AppSpace.md),
                      Expanded(child: tile(shown[r + 1], 1)),
                    ],
                  ),
                ],
              ],
            ),
    );
  }
}

// ── Görsel üstü yazılı kart ───────────────────────────────────────────────────

/// Fotoğrafın üzerine koyu degradeyle ad ve puan yazılan kart. Rozet yok:
/// fotoğrafın köşelerine yapışan kutucuklar yemeği örtüyordu.
class DishOverlayCard extends StatelessWidget {
  const DishOverlayCard({super.key, required this.item, required this.onTap});

  final MenuItemModel item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      semanticLabel: item.name,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Stack(
          fit: StackFit.expand,
          children: [
            DishPhoto(url: item.photoUrl, iconSize: 28),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(12, 36, 12, 12),
                decoration: const BoxDecoration(
                  // Degrade her iki temada da koyu — üstündeki yazılar bu
                  // yüzden AppTextStyles.onImage* ile sabit renkte.
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Color(0xE60D0D0D), Color(0x000D0D0D)],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      item.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.onImageTitle,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.restaurantName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.onImageCaption,
                          ),
                        ),
                        if (item.averageRating > 0) ...[
                          const SizedBox(width: AppSpace.sm),
                          const Icon(TablerIcons.star_filled,
                              size: 12, color: AppColors.star),
                          const SizedBox(width: 3),
                          Text(
                            item.averageRating.toStringAsFixed(1),
                            style: AppTextStyles.ratingSmall
                                .copyWith(color: Colors.white),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

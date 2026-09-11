import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
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
//
// Kart dili ise değişmiyor: şeritler de ızgara da aynı [MenuItemCard]'ı
// kullanıyor, fark fotoğraf oranında ve dizilişte.

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
                    const SizedBox(height: AppSpace.xxs),
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
                padding: const EdgeInsets.only(top: AppSpace.xxs),
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

  /// Sıra numarası sütununun genişliği ve satır fotoğrafının kenarı. Keşfet
  /// iskeleti de bunları okuyor; ayrı ayrı yazılınca biri değişip öbürü
  /// geride kalıyor, içerik gelince liste zıplıyordu.
  static const double rankWidth = 28;
  static const double photoSize = 56;

  @override
  Widget build(BuildContext context) {
    final meta = showRestaurant ? _meta(item) : (item.categoryName ?? '');

    return Pressable(
      onTap: onTap,
      semanticLabel: rank == null ? item.name : '$rank. ${item.name}',
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpace.md),
        child: Row(
          children: [
            _RankNumber(rank: rank),
            DishPhoto(
              url: item.photoUrl,
              width: photoSize,
              height: photoSize,
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
                    const SizedBox(height: AppSpace.xxs),
                  ],
                  Text(
                    item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.titleSmall
                        .copyWith(color: context.textPrimaryColor),
                  ),
                  if (meta.isNotEmpty) ...[
                    const SizedBox(height: AppSpace.xxs),
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
      width: DishRankRow.rankWidth,
      child: Text(
        rank == null ? '' : '$rank',
        style: AppTextStyles.titleMedium.copyWith(
          // Numara yemek adının önüne geçmesin: başlık değil liste ağırlığı.
          fontWeight: AppFonts.title,
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

/// Yatay fotoğraflı şerit. Dikey poster şeridinden kartın kendisiyle değil,
/// oran ve genişlikle ayrılıyor.
class DishWideCarousel extends StatelessWidget {
  const DishWideCarousel({
    super.key,
    required this.items,
    required this.onTap,
  });

  final List<MenuItemModel> items;
  final DishTap onTap;

  static const double _cardWidth = 264;
  static const double _photoAspect = 16 / 10;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MenuItemCard.heightFor(
        context,
        _cardWidth,
        photoAspect: _photoAspect,
      ),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: AppSpace.screen),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpace.md),
        itemBuilder: (context, i) => SizedBox(
          width: _cardWidth,
          child: MenuItemCard(
            item: items[i],
            onTap: () => onTap(items[i]),
            photoAspect: _photoAspect,
          ),
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

    Widget card(MenuItemModel item, double aspect) => MenuItemCard(
          item: item,
          onTap: () => onTap(item),
          photoAspect: aspect,
        );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.screen),
      child: count == 1
          ? card(shown[0], 16 / 10)
          : Column(
              children: [
                for (var r = 0; r < count; r += 2) ...[
                  // Satır arası sütun arasından geniş: bilgi fotoğrafın
                  // altında, sıkı dursa üst kartın puan satırı alttaki kartın
                  // fotoğrafına yapışır. "Tümünü gör" ızgarasıyla aynı değer.
                  if (r > 0) const SizedBox(height: AppSpace.xl),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: card(shown[r], 1)),
                      const SizedBox(width: AppSpace.md),
                      Expanded(child: card(shown[r + 1], 1)),
                    ],
                  ),
                ],
              ],
            ),
    );
  }
}

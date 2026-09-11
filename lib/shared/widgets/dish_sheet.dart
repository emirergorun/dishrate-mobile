import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';

import '../../core/auth/token_storage.dart';
import '../../core/network/rating_repository.dart';
import '../../core/network/wishlist_repository.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_metrics.dart';
import '../../core/theme/app_text_styles.dart';
import '../../features/rating/providers/rating_flow_provider.dart';
import '../../features/restaurant/screens/restaurant_detail_screen.dart';
import '../../features/reviews/screens/menu_item_reviews_screen.dart';
import '../models/menu_item_model.dart';
import '../models/menu_item_review_model.dart';
import '../models/restaurant_model.dart';
import 'dish_photo.dart';
import 'pressable.dart';
import 'rating_sheet.dart';
import 'rating_stars.dart';
import 'review_tile.dart';
import 'skeleton.dart';

/// Bir yemeğe dokununca açılan panel: fotoğraf, puan, son yorumlar, eylemler.
///
/// Keşfet, "Tümünü gör" ve restoran menüsü aynı paneli açıyor. Önceden panel
/// keşfet ekranının içindeydi; restoran menüsünden bir yemeğe dokununca
/// doğrudan yorum listesine gidiliyor ve oradan puan vermenin yolu yoktu.
abstract final class DishSheet {
  /// Paneli açar; kullanıcı "Değerlendir"e basarsa puanlama akışını başlatır.
  ///
  /// [showRestaurantLink] restoran detayından açılınca kapatılır: kullanıcı
  /// zaten o restoranın sayfasında, bağlantı aynı sayfanın bir kopyasını
  /// üstüne açardı.
  ///
  /// Puanlama akışı açıldıysa `true` döner: çağıran ekran ortalamalar
  /// değişmiş olabileceği için verisini tazeleyebilsin.
  static Future<bool> open(
    BuildContext context,
    WidgetRef ref,
    MenuItemModel item, {
    bool showRestaurantLink = true,
  }) async {
    final shouldRate = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          _DishSheetBody(item: item, showRestaurantLink: showRestaurantLink),
    );
    if (shouldRate != true || !context.mounted) return false;

    final restaurant = RestaurantModel(
      restaurantId: item.restaurantId,
      name: item.restaurantName,
      city: item.city ?? 'İstanbul',
      district: item.district,
      fullAddress:
          '${item.restaurantName}, ${item.district ?? item.city ?? "İstanbul"}',
      latitude: item.restaurantLatitude,
      longitude: item.restaurantLongitude,
      categoryName: item.categoryName,
    );
    ref.read(ratingFlowProvider.notifier).jumpToRateItem(restaurant, item);
    if (!context.mounted) return false;
    await RatingSheet.show(context);
    return true;
  }
}

/// Önizlemede gösterilen en fazla yorum sayısı. Üçten fazlası paneli
/// yorum listesine çeviriyor ve "Değerlendir" ekranın dışına itiliyordu.
const int _previewCount = 3;

class _DishSheetBody extends StatefulWidget {
  const _DishSheetBody({required this.item, required this.showRestaurantLink});

  final MenuItemModel item;
  final bool showRestaurantLink;

  @override
  State<_DishSheetBody> createState() => _DishSheetBodyState();
}

class _DishSheetBodyState extends State<_DishSheetBody> {
  bool _inWishlist = false;
  bool _wishlistLoading = true;

  List<MenuItemReviewModel>? _reviews;
  bool _reviewsFailed = false;

  @override
  void initState() {
    super.initState();
    _checkWishlist();
    _loadReviews();
  }

  Future<void> _checkWishlist() async {
    try {
      final userId = await TokenStorage.instance.getUserId();
      if (userId == null) {
        if (mounted) setState(() => _wishlistLoading = false);
        return;
      }
      final list = await WishlistRepository.instance.getWishlist(userId);
      if (!mounted) return;
      setState(() {
        _inWishlist =
            list.any((w) => w.menuItemId == widget.item.menuItemId);
        _wishlistLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _wishlistLoading = false);
    }
  }

  Future<void> _toggleWishlist() async {
    setState(() => _wishlistLoading = true);
    try {
      final userId = await TokenStorage.instance.getUserId();
      if (userId == null) {
        if (mounted) setState(() => _wishlistLoading = false);
        return;
      }
      if (_inWishlist) {
        await WishlistRepository.instance
            .removeByMenuItemId(userId, widget.item.menuItemId);
      } else {
        await WishlistRepository.instance
            .addToWishlist(userId, widget.item.menuItemId);
      }
      if (!mounted) return;
      HapticFeedback.lightImpact();
      setState(() {
        _inWishlist = !_inWishlist;
        _wishlistLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _wishlistLoading = false);
    }
  }

  Future<void> _loadReviews() async {
    setState(() => _reviewsFailed = false);
    try {
      final reviews = await RatingRepository.instance
          .getMenuItemReviews(widget.item.menuItemId);
      // En yeni önce — tüm yorumlar ekranıyla aynı sıra.
      reviews.sort((a, b) => b.ratingId.compareTo(a.ratingId));
      if (mounted) setState(() => _reviews = reviews);
    } catch (_) {
      if (mounted) setState(() => _reviewsFailed = true);
    }
  }

  void _openRestaurant() {
    final item = widget.item;
    final loc = [item.district, item.city]
        .where((e) => e != null && e.isNotEmpty)
        .join(', ');
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RestaurantDetailScreen(
          restaurantId: item.restaurantId,
          restaurantName: item.restaurantName,
          locationText: loc,
        ),
      ),
    );
  }

  void _openAllReviews() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MenuItemReviewsScreen(
          menuItemId: widget.item.menuItemId,
          menuItemName: widget.item.name,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final media = MediaQuery.of(context);
    final hasPhoto = item.photoUrl != null && item.photoUrl!.isNotEmpty;

    final meta = [item.district, item.categoryName]
        .where((e) => e != null && e.isNotEmpty)
        .join(' · ');

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: media.size.height * 0.9),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: context.sheetColor,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
        ),
        child: ClipRRect(
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Fotoğraf — panelin kenarına kadar ─────────────────
                      // Önceden fotoğraf panelin içinde, kenar boşluklu ayrı
                      // bir kutudaydı; yemek küçülüyor, panel kutu içinde
                      // kutu gibi görünüyordu.
                      Stack(
                        children: [
                          hasPhoto
                              ? AspectRatio(
                                  aspectRatio: 4 / 3,
                                  child: DishPhoto(
                                      url: item.photoUrl, iconSize: 40),
                                )
                              : const SizedBox(height: 28),
                          Positioned(
                            top: 8,
                            left: 0,
                            right: 0,
                            child: Center(
                              child: Container(
                                width: 36,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: hasPhoto
                                      ? Colors.white.withValues(alpha: 0.7)
                                      : context.dividerColor,
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.xs),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                            AppSpace.screen, AppSpace.screen, AppSpace.screen, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.name,
                              style: AppTextStyles.headlineLarge
                                  .copyWith(color: context.textPrimaryColor),
                            ),
                            const SizedBox(height: AppSpace.sm),
                            _RestaurantLine(
                              name: item.restaurantName,
                              onTap: widget.showRestaurantLink
                                  ? _openRestaurant
                                  : null,
                            ),
                            if (meta.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                meta,
                                style: AppTextStyles.caption.copyWith(
                                    color: context.textSecondaryColor),
                              ),
                            ],
                            const SizedBox(height: AppSpace.xl),
                            _RatingSummary(
                              rating: item.averageRating,
                              count: _reviews?.length,
                            ),
                            const SizedBox(height: AppSpace.xl),
                            _buildReviews(),
                            const SizedBox(height: AppSpace.lg),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Eylemler — kaydırmadan bağımsız, hep görünür ──────────────
              // "Değerlendir" uygulamanın bir numaralı eylemi; istek listesiyle
              // eşit genişlikte yan yana durunca ikisi aynı önemde okunuyordu
              // (ve "İstek Listesi'ne Ekle" iki satıra taşıyordu). İstek
              // listesi artık ikon butonu.
              Padding(
                padding: EdgeInsets.fromLTRB(AppSpace.screen, AppSpace.md,
                    AppSpace.screen, media.padding.bottom + AppSpace.md),
                child: Row(
                  children: [
                    _WishlistButton(
                      active: _inWishlist,
                      loading: _wishlistLoading,
                      onTap: _toggleWishlist,
                    ),
                    const SizedBox(width: AppSpace.md),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Değerlendir'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReviews() {
    final titleStyle =
        AppTextStyles.titleMedium.copyWith(color: context.textPrimaryColor);

    if (_reviewsFailed) {
      return Row(
        children: [
          Expanded(
            child: Text(
              'Yorumlar yüklenemedi.',
              style: AppTextStyles.bodyMedium
                  .copyWith(color: context.textSecondaryColor),
            ),
          ),
          TextButton(onPressed: _loadReviews, child: const Text('Tekrar dene')),
        ],
      );
    }

    final reviews = _reviews;
    if (reviews == null) {
      return const SkeletonPulse(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SkeletonBox(width: 120, height: 16),
            SizedBox(height: AppSpace.lg),
            SkeletonBox(height: 14),
            SizedBox(height: AppSpace.sm),
            SkeletonBox(width: 220, height: 14),
          ],
        ),
      );
    }

    // Önizlemede yalnızca yazılı yorumlar: yorumsuz puanlar zaten üstteki
    // ortalamada; beş yıldız satırını yazısız alt alta dizmek bilgi taşımıyor.
    final written =
        reviews.where((r) => (r.comment ?? '').trim().isNotEmpty).toList();

    if (written.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Yorumlar', style: titleStyle),
          const SizedBox(height: 6),
          Text(
            reviews.isEmpty
                ? 'Henüz yorum yok. İlk yorumu sen yaz.'
                : 'Henüz yazılı yorum yok.',
            style: AppTextStyles.bodyMedium
                .copyWith(color: context.textSecondaryColor),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Son yorumlar', style: titleStyle),
        const SizedBox(height: AppSpace.lg),
        for (final r in written.take(_previewCount)) ...[
          ReviewTile(review: r, maxLines: 4),
          const SizedBox(height: AppSpace.xl),
        ],
        TextButton(
          onPressed: _openAllReviews,
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: const Size(0, 36),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text('Tüm değerlendirmeler (${reviews.length})'),
        ),
      ],
    );
  }
}

// ── Restoran satırı ───────────────────────────────────────────────────────────

class _RestaurantLine extends StatelessWidget {
  const _RestaurantLine({required this.name, required this.onTap});

  final String name;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final text = Text(
      name,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: AppTextStyles.titleSmall.copyWith(
        color: onTap == null
            ? context.textSecondaryColor
            : context.textPrimaryColor,
      ),
    );
    if (onTap == null) return text;

    // Ok, adın hemen yanında: önceden satırın öbür ucunda ilçenin yanına
    // düşüyor ve neyin dokunulabilir olduğu belirsizleşiyordu.
    return Pressable(
      onTap: onTap,
      semanticLabel: '$name restoran sayfası',
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(child: text),
            const SizedBox(width: 2),
            Icon(TablerIcons.chevron_right,
                size: 14, color: context.textSecondaryColor),
          ],
        ),
      ),
    );
  }
}

// ── Puan özeti ────────────────────────────────────────────────────────────────

class _RatingSummary extends StatelessWidget {
  const _RatingSummary({required this.rating, required this.count});

  final double rating;

  /// `null` → yorumlar henüz yüklenmedi.
  final int? count;

  @override
  Widget build(BuildContext context) {
    if (rating <= 0) {
      return Text(
        'Henüz puanlanmamış',
        style:
            AppTextStyles.titleSmall.copyWith(color: context.textSecondaryColor),
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          rating.toStringAsFixed(1),
          style:
              AppTextStyles.ratingLarge.copyWith(color: context.textPrimaryColor),
        ),
        const SizedBox(width: AppSpace.md),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            StarRow(rating: rating, size: 14),
            const SizedBox(height: 4),
            AnimatedOpacity(
              opacity: count == null ? 0 : 1,
              duration: AppMotion.base,
              child: Text(
                '${count ?? 0} değerlendirme',
                style: AppTextStyles.caption
                    .copyWith(color: context.textSecondaryColor),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ── İstek listesi butonu ──────────────────────────────────────────────────────

class _WishlistButton extends StatelessWidget {
  const _WishlistButton({
    required this.active,
    required this.loading,
    required this.onTap,
  });

  final bool active;
  final bool loading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final label =
        active ? 'İstek listesinden çıkar' : 'İstek listesine ekle';

    return Tooltip(
      message: label,
      child: Pressable(
        onTap: loading ? null : onTap,
        semanticLabel: label,
        child: Container(
          width: 52,
          height: 52,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: context.dividerColor),
          ),
          child: loading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : AnimatedSwitcher(
                  duration: AppMotion.base,
                  transitionBuilder: (child, a) =>
                      ScaleTransition(scale: a, child: child),
                  child: Icon(
                    active
                        ? TablerIcons.bookmark_filled
                        : TablerIcons.bookmark,
                    key: ValueKey(active),
                    size: 22,
                    color: active
                        ? AppColors.primary
                        : context.textPrimaryColor,
                  ),
                ),
        ),
      ),
    );
  }
}

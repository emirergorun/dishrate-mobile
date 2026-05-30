import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/models/menu_item_model.dart';

/// Keşfet ekranındaki yatay kaydırma kartı.
/// Boyut: 180×230 px — fotoğraf ağırlıklı, alt gradient üzerinde bilgiler.
class MenuItemCard extends StatelessWidget {
  const MenuItemCard({
    super.key,
    required this.item,
    this.onTap,
  });

  final MenuItemModel item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 180,
        height: 230,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: AppColors.surface,
        ),
        clipBehavior: Clip.hardEdge,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // ── Yemek fotoğrafı ──────────────────────────────────────────
            _FoodImage(photoUrl: item.photoUrl, name: item.name),

            // ── Alt gradient + bilgiler ───────────────────────────────────
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _CardInfo(item: item),
            ),

            // ── Kategori etiketi (sol üst) ────────────────────────────────
            if (item.categoryName != null)
              Positioned(
                top: 10,
                left: 10,
                child: _CategoryBadge(label: item.categoryName!),
              ),

            // ── Puan rozeti (sağ üst) ─────────────────────────────────────
            Positioned(
              top: 10,
              right: 10,
              child: _RatingBadge(rating: item.averageRating),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Fotoğraf bileşeni ──────────────────────────────────────────────────────────

class _FoodImage extends StatelessWidget {
  const _FoodImage({this.photoUrl, required this.name});

  final String? photoUrl;
  final String name;

  @override
  Widget build(BuildContext context) {
    if (photoUrl != null && photoUrl!.isNotEmpty) {
      return Image.network(
        photoUrl!,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _placeholder(name),
      );
    }
    return _placeholder(name);
  }

  Widget _placeholder(String name) {
    // Fotoğraf yokken ismin baş harfini gösteren renkli arka plan
    final colors = [
      const Color(0xFF2D1B69),
      const Color(0xFF1A3A2A),
      const Color(0xFF3A1A1A),
      const Color(0xFF1A2A3A),
      const Color(0xFF2A2A1A),
    ];
    final colorIndex = name.codeUnitAt(0) % colors.length;

    return Container(
      color: colors[colorIndex],
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: const TextStyle(
            fontSize: 56,
            fontWeight: FontWeight.w300,
            color: Colors.white24,
          ),
        ),
      ),
    );
  }
}

// ── Alt bilgi bölümü ──────────────────────────────────────────────────────────

class _CardInfo extends StatelessWidget {
  const _CardInfo({required this.item});
  final MenuItemModel item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 40, 12, 12),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            Color(0xEE0D0D0D),
            Color(0x880D0D0D),
            Colors.transparent,
          ],
          stops: [0.0, 0.6, 1.0],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Restoran adı
          Text(
            item.restaurantName,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
              fontSize: 11,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          // Yemek adı
          Text(
            item.name,
            style: AppTextStyles.titleSmall,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (item.district != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(
                  Icons.location_on_rounded,
                  size: 11,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 2),
                Text(
                  item.district!,
                  style: AppTextStyles.bodySmall.copyWith(fontSize: 11),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ── Kategori rozeti ───────────────────────────────────────────────────────────

class _CategoryBadge extends StatelessWidget {
  const _CategoryBadge({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white12),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

// ── Puan rozeti ───────────────────────────────────────────────────────────────

class _RatingBadge extends StatelessWidget {
  const _RatingBadge({required this.rating});
  final double rating;

  @override
  Widget build(BuildContext context) {
    if (rating == 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, color: AppColors.star, size: 12),
          const SizedBox(width: 3),
          Text(
            rating.toStringAsFixed(1),
            style: AppTextStyles.ratingSmall.copyWith(fontSize: 12),
          ),
        ],
      ),
    );
  }
}

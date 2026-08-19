import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

import '../../../core/network/restaurant_repository.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/models/menu_item_model.dart';
import '../../reviews/screens/menu_item_reviews_screen.dart';

/// Bir restoranın tam ekran detayı: bilgi + menü ("Önerilen" rozetiyle).
/// Bir ürüne tıklayınca o ürünün değerlendirmeleri açılır.
class RestaurantDetailScreen extends StatefulWidget {
  const RestaurantDetailScreen({
    super.key,
    required this.restaurantId,
    required this.restaurantName,
    this.locationText,
  });
  final int restaurantId;
  final String restaurantName;
  final String? locationText;

  @override
  State<RestaurantDetailScreen> createState() => _RestaurantDetailScreenState();
}

class _RestaurantDetailScreenState extends State<RestaurantDetailScreen> {
  List<MenuItemModel> _menu = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final menu = await RestaurantRepository.instance
          .getRestaurantMenu(widget.restaurantId);
      // En yüksek puanlı üstte ("Önerilen")
      menu.sort((a, b) => b.averageRating.compareTo(a.averageRating));
      if (mounted) {
        setState(() {
          _menu = menu;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'Menü yüklenemedi.';
          _loading = false;
        });
      }
    }
  }

  void _openReviews(MenuItemModel item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MenuItemReviewsScreen(
          menuItemId: item.menuItemId,
          menuItemName: item.name,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bgColor,
      appBar: AppBar(
        backgroundColor: context.bgColor,
        elevation: 0,
        title: Text(widget.restaurantName, style: AppTextStyles.titleMedium),
        iconTheme: IconThemeData(color: context.textPrimaryColor),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        color: AppColors.primary,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.primary));
    }
    if (_error != null) {
      return _centered(Icons.cloud_off_rounded, _error!,
          OutlinedButton(onPressed: _load, child: const Text('Tekrar Dene')));
    }
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        // Başlık kartı
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: context.surfaceColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.dividerColor),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child:
                    const Icon(Icons.storefront_rounded, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.restaurantName, style: AppTextStyles.titleSmall),
                    if ((widget.locationText ?? '').isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(widget.locationText!,
                          style: AppTextStyles.bodySmall),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Text('Menü', style: AppTextStyles.titleSmall),
            const SizedBox(width: 8),
            Text('(${_menu.length})',
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.textSecondary)),
          ],
        ),
        const SizedBox(height: 8),
        if (_menu.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Center(
              child: Text('Bu restoranda henüz menü yok.',
                  style: AppTextStyles.bodyMedium
                      .copyWith(color: AppColors.textSecondary)),
            ),
          )
        else
          ..._menu.asMap().entries.map((e) => _DetailMenuRow(
                item: e.value,
                recommended: e.key == 0 && e.value.averageRating > 0,
                onTap: () => _openReviews(e.value),
              )),
      ],
    );
  }

  Widget _centered(IconData icon, String msg, Widget? action) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 52, color: AppColors.textDisabled),
            const SizedBox(height: 16),
            Text(msg,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium
                    .copyWith(color: AppColors.textSecondary)),
            if (action != null) ...[const SizedBox(height: 20), action],
          ],
        ),
      ),
    );
  }
}

class _DetailMenuRow extends StatelessWidget {
  const _DetailMenuRow({
    required this.item,
    required this.recommended,
    required this.onTap,
  });
  final MenuItemModel item;
  final bool recommended;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      width: 52,
      height: 52,
      color: context.surfaceElevatedColor,
      child: const Icon(Icons.fastfood_rounded,
          color: AppColors.textDisabled, size: 22),
    );
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: context.surfaceColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.dividerColor),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: (item.photoUrl != null && item.photoUrl!.isNotEmpty)
                  ? Image.network(item.photoUrl!,
                      width: 52,
                      height: 52,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => placeholder)
                  : placeholder,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (recommended) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.thumb_up_rounded,
                              size: 11, color: AppColors.primary),
                          const SizedBox(width: 4),
                          Text('Önerilen',
                              style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 11)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                  Text(item.name,
                      style: AppTextStyles.titleSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  if (item.averageRating > 0)
                    Row(
                      children: [
                        RatingBarIndicator(
                          rating: item.averageRating,
                          itemSize: 13,
                          itemBuilder: (_, __) => const Icon(
                              Icons.star_rounded, color: AppColors.star),
                        ),
                        const SizedBox(width: 4),
                        Text(item.averageRating.toStringAsFixed(1),
                            style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.star,
                                fontWeight: FontWeight.w600)),
                      ],
                    )
                  else
                    Text('Henüz değerlendirilmemiş',
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.textDisabled)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}

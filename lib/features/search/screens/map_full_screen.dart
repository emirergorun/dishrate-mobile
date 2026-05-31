import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/network/restaurant_repository.dart';
import '../../../core/network/wishlist_repository.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/models/restaurant_model.dart';
import '../../../shared/models/menu_item_model.dart';
import '../../rating/providers/rating_flow_provider.dart';
import '../../rating/screens/add_rating_screen.dart';

class MapFullScreen extends ConsumerStatefulWidget {
  final List<RestaurantModel> initialRestaurants;

  const MapFullScreen({super.key, required this.initialRestaurants});

  @override
  ConsumerState<MapFullScreen> createState() => _MapFullScreenState();
}

class _MapFullScreenState extends ConsumerState<MapFullScreen> {
  static const _istanbul = LatLng(41.0082, 28.9784);

  static const _categories = [
    'Burger', 'Sushi', 'Pizza', 'Döner', 'Noodle', 'Kahve', 'Salata', 'Tatlı',
  ];

  String? _selectedCategory;
  List<RestaurantModel> _visibleRestaurants = [];
  bool _isFiltering = false;

  @override
  void initState() {
    super.initState();
    _visibleRestaurants = widget.initialRestaurants;
  }

  Future<void> _onCategoryTap(String label) async {
    if (_selectedCategory == label) {
      setState(() {
        _selectedCategory = null;
        _visibleRestaurants = widget.initialRestaurants;
      });
      return;
    }

    setState(() {
      _selectedCategory = label;
      _isFiltering = true;
    });

    try {
      final items = await RestaurantRepository.instance.searchMenuItems(label);
      final markers = _itemsToRestaurants(items);
      if (mounted) {
        setState(() {
          _visibleRestaurants = markers;
          _isFiltering = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isFiltering = false);
    }
  }

  List<RestaurantModel> _itemsToRestaurants(List<MenuItemModel> items) {
    final seen = <int>{};
    final result = <RestaurantModel>[];
    for (final item in items) {
      if (!seen.contains(item.restaurantId) &&
          item.restaurantLatitude != null &&
          item.restaurantLongitude != null) {
        seen.add(item.restaurantId);
        final existing = widget.initialRestaurants.where(
          (r) => r.restaurantId == item.restaurantId,
        );
        if (existing.isNotEmpty) {
          result.add(existing.first);
        } else {
          result.add(RestaurantModel(
            restaurantId: item.restaurantId,
            name: item.restaurantName,
            city: item.city ?? '',
            fullAddress: '',
            latitude: item.restaurantLatitude,
            longitude: item.restaurantLongitude,
          ));
        }
      }
    }
    return result;
  }

  static String _categoryEmoji(String? category) {
    switch (category) {
      case 'Burger':
        return '🍔';
      case 'Pizza':
        return '🍕';
      case 'Sushi':
        return '🍣';
      case 'Kebap':
        return '🥙';
      case 'Tavuk':
        return '🍗';
      case 'Kahvaltı':
        return '🍳';
      case 'Tatlı':
        return '🍰';
      case 'İtalyan':
        return '🍝';
      case 'Noodle':
        return '🍜';
      case 'Vegan':
        return '🥗';
      case 'Meze':
        return '🫙';
      case 'Kahve':
        return '☕';
      default:
        return '🍽️';
    }
  }

  List<Marker> _buildMarkers() {
    return _visibleRestaurants
        .where((r) => r.latitude != null && r.longitude != null)
        .map((r) => Marker(
              point: LatLng(r.latitude!, r.longitude!),
              width: 48,
              height: 48,
              child: GestureDetector(
                onTap: () => _showRestaurantMenu(r),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.35),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      _categoryEmoji(r.categoryName),
                      style: const TextStyle(fontSize: 22),
                    ),
                  ),
                ),
              ),
            ))
        .toList();
  }

  /// Restorana ait menüyü göster; kullanıcı "Değerlendir" seçerse
  /// rating ekranına yönlendir.
  Future<void> _showRestaurantMenu(RestaurantModel restaurant) async {
    final selectedItem = await showModalBottomSheet<MenuItemModel?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _RestaurantMenuSheet(restaurant: restaurant),
    );

    if (selectedItem != null && mounted) {
      ref
          .read(ratingFlowProvider.notifier)
          .jumpToRateItem(restaurant, selectedItem);

      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => const AddRatingScreen(),
      );

      ref.read(ratingFlowProvider.notifier).reset();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ── Harita ──────────────────────────────────────────────────
          FlutterMap(
            options: MapOptions(
              initialCenter: _istanbul,
              initialZoom: 12,
            ),
            children: [
              TileLayer(
                urlTemplate: context.isDark
                    ? 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png'
                    : 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png',
                subdomains: const ['a', 'b', 'c', 'd'],
                userAgentPackageName: 'dishrate_mobile',
              ),
              MarkerLayer(markers: _buildMarkers()),
            ],
          ),

          // ── Geri butonu ─────────────────────────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Align(
                alignment: Alignment.topLeft,
                child: _MapButton(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.arrow_back_rounded,
                      color: Colors.white, size: 20),
                ),
              ),
            ),
          ),

          // ── Filtreleme göstergesi ────────────────────────────────────
          if (_isFiltering)
            const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),

          // ── Sağ taraf: kategori butonları ────────────────────────────
          SafeArea(
            child: Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: _categories.map((label) {
                    final isSelected = _selectedCategory == label;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: _CategoryChip(
                        label: label,
                        isSelected: isSelected,
                        onTap: () => _onCategoryTap(label),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Restoran menü sheet'i ──────────────────────────────────────────────────────

class _RestaurantMenuSheet extends StatefulWidget {
  const _RestaurantMenuSheet({required this.restaurant});
  final RestaurantModel restaurant;

  @override
  State<_RestaurantMenuSheet> createState() => _RestaurantMenuSheetState();
}

class _RestaurantMenuSheetState extends State<_RestaurantMenuSheet> {
  List<MenuItemModel>? _items;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchMenu();
  }

  Future<void> _fetchMenu() async {
    try {
      final items = await RestaurantRepository.instance
          .getRestaurantMenu(widget.restaurant.restaurantId);
      if (mounted) {
        setState(() {
          _items = items;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Menü yüklenemedi';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.75;

    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── Restoran başlığı ──────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.storefront_rounded,
                      color: AppColors.textDisabled, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.restaurant.name,
                          style: AppTextStyles.titleSmall),
                      if ((widget.restaurant.district ?? '').isNotEmpty ||
                          widget.restaurant.city.isNotEmpty)
                        Text(
                          [widget.restaurant.district, widget.restaurant.city]
                              .where((s) => s != null && s.isNotEmpty)
                              .join(', '),
                          style: AppTextStyles.bodySmall,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),
          Divider(height: 1, color: AppColors.divider),
          const SizedBox(height: 4),

          // ── Menü içeriği ──────────────────────────────────────────
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(40),
              child: Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            )
          else if (_error != null)
            Padding(
              padding: const EdgeInsets.all(40),
              child: Text(_error!,
                  style: AppTextStyles.bodyMedium
                      .copyWith(color: AppColors.textSecondary)),
            )
          else if (_items == null || _items!.isEmpty)
            Padding(
              padding: const EdgeInsets.all(40),
              child: Column(
                children: [
                  const Icon(Icons.restaurant_menu_rounded,
                      color: AppColors.textDisabled, size: 40),
                  const SizedBox(height: 12),
                  Text('Henüz menü eklenmemiş',
                      style: AppTextStyles.bodyMedium
                          .copyWith(color: AppColors.textSecondary)),
                ],
              ),
            )
          else
            Flexible(
              child: ListView.separated(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                itemCount: _items!.length,
                separatorBuilder: (_, __) =>
                    Divider(height: 1, color: AppColors.divider),
                itemBuilder: (context, i) => _MenuItemRow(
                  item: _items![i],
                  restaurant: widget.restaurant,
                  onRate: () => Navigator.pop(context, _items![i]),
                ),
              ),
            ),

          SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
        ],
      ),
    );
  }
}

// ── Tek menü satırı ───────────────────────────────────────────────────────────

class _MenuItemRow extends StatefulWidget {
  const _MenuItemRow({
    required this.item,
    required this.restaurant,
    required this.onRate,
  });

  final MenuItemModel item;
  final RestaurantModel restaurant;
  final VoidCallback onRate;

  @override
  State<_MenuItemRow> createState() => _MenuItemRowState();
}

class _MenuItemRowState extends State<_MenuItemRow> {
  bool _wishlistLoading = false;
  bool _inWishlist = false;

  Future<void> _toggleWishlist() async {
    if (_wishlistLoading) return;
    setState(() => _wishlistLoading = true);
    try {
      if (_inWishlist) {
        await WishlistRepository.instance
            .removeByMenuItemId(1, widget.item.menuItemId);
        if (mounted) {
          setState(() { _inWishlist = false; _wishlistLoading = false; });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('İstek listesinden çıkarıldı.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        await WishlistRepository.instance
            .addToWishlist(1, widget.item.menuItemId);
        if (mounted) {
          setState(() { _inWishlist = true; _wishlistLoading = false; });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('İstek listene eklendi.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (_) {
      if (mounted) setState(() => _wishlistLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Item bilgisi ──────────────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Fotoğraf
              if (widget.item.photoUrl != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    widget.item.photoUrl!,
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 56,
                      height: 56,
                      color: AppColors.surfaceElevated,
                      child: const Icon(Icons.fastfood_rounded,
                          color: AppColors.textDisabled, size: 22),
                    ),
                  ),
                )
              else
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.fastfood_rounded,
                      color: AppColors.textDisabled, size: 22),
                ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.item.name,
                        style: AppTextStyles.titleSmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    if (widget.item.averageRating > 0)
                      Row(
                        children: [
                          RatingBarIndicator(
                            rating: widget.item.averageRating,
                            itemBuilder: (_, __) => const Icon(
                              Icons.star_rounded,
                              color: AppColors.primary,
                            ),
                            itemCount: 5,
                            itemSize: 13,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            widget.item.averageRating.toStringAsFixed(1),
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // ── Aksiyon butonları ─────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: _ActionButton(
                  label: _inWishlist ? 'Listeden Çıkar' : 'İstek Listesi\'ne Ekle',
                  icon: _inWishlist
                      ? Icons.bookmark_rounded
                      : Icons.bookmark_add_outlined,
                  isLoading: _wishlistLoading,
                  isPrimary: false,
                  onTap: _toggleWishlist,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ActionButton(
                  label: 'Değerlendir',
                  icon: Icons.star_outline_rounded,
                  isLoading: false,
                  isPrimary: true,
                  onTap: widget.onRate,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Aksiyon butonu ─────────────────────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.isLoading,
    required this.isPrimary,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isLoading;
  final bool isPrimary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: isPrimary ? AppColors.primary : AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(10),
        ),
        child: isLoading
            ? const Center(
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.textSecondary,
                  ),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    size: 15,
                    color: isPrimary ? Colors.white : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color:
                          isPrimary ? Colors.white : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

// ── Yardımcı widget'lar ───────────────────────────────────────────────────────

class _MapButton extends StatelessWidget {
  const _MapButton({required this.onTap, required this.child});
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.55),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
        ),
        child: child,
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary
              : Colors.black.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : Colors.white.withValues(alpha: 0.20),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.white,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

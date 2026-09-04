import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/network/restaurant_repository.dart';
import '../../../core/auth/token_storage.dart';
import '../../../core/network/wishlist_repository.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../features/rating/providers/rating_flow_provider.dart';
import '../../../features/rating/screens/add_rating_screen.dart';
import '../../../shared/models/menu_item_model.dart';
import '../../../shared/models/restaurant_model.dart';
import '../../restaurant/screens/restaurant_detail_screen.dart';
import 'map_full_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

// ── Veri modeli: arama sonucu restoran + eşleşen ürünler ─────────────────────

class _RestaurantResult {
  final int restaurantId;
  final String name;
  final String? district;
  final String city;
  final List<MenuItemModel> items;

  _RestaurantResult({
    required this.restaurantId,
    required this.name,
    this.district,
    required this.city,
    required this.items,
  });
}

// ─────────────────────────────────────────────────────────────────────────────

class _SearchScreenState extends State<SearchScreen> {
  static const _istanbul = LatLng(41.0082, 28.9784);

  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  List<RestaurantModel> _allRestaurants = [];
  List<_RestaurantResult> _results = [];
  bool _mapLoading = true;
  bool _searching = false;
  String _query = '';
  String? _selectedCategory;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _loadRestaurants();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _loadRestaurants() async {
    try {
      final list = await RestaurantRepository.instance.getAllRestaurants();
      if (mounted) setState(() => _allRestaurants = list);
    } finally {
      if (mounted) setState(() => _mapLoading = false);
    }
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    setState(() {
      _query = value;
      _selectedCategory = null; // metin araması kategoriden bağımsız
    });

    if (value.trim().isEmpty) {
      setState(() => _results = []);
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 400), () async {
      if (!mounted) return;
      setState(() => _searching = true);
      try {
        final items =
            await RestaurantRepository.instance.searchMenuItems(value.trim());
        if (mounted) setState(() => _results = _groupByRestaurant(items));
      } catch (_) {
        if (mounted) setState(() => _results = []);
      } finally {
        if (mounted) setState(() => _searching = false);
      }
    });
  }

  void _onCategoryTap(String label) {
    final isAlreadySelected = _selectedCategory == label;
    setState(() {
      _selectedCategory = isAlreadySelected ? null : label;
      _controller.clear();
      _query = '';
    });

    if (isAlreadySelected) {
      setState(() => _results = []);
      return;
    }
    _searchByCategory(label);
  }

  Future<void> _searchByCategory(String category) async {
    setState(() => _searching = true);
    try {
      final items =
          await RestaurantRepository.instance.getMenuItemsByCategory(category);
      if (mounted) setState(() => _results = _groupByRestaurant(items));
    } catch (_) {
      if (mounted) setState(() => _results = []);
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  /// Menu item listesini restorana göre grupla
  List<_RestaurantResult> _groupByRestaurant(List<MenuItemModel> items) {
    final map = <int, _RestaurantResult>{};
    for (final item in items) {
      if (map.containsKey(item.restaurantId)) {
        map[item.restaurantId]!.items.add(item);
      } else {
        map[item.restaurantId] = _RestaurantResult(
          restaurantId: item.restaurantId,
          name: item.restaurantName,
          district: item.district,
          city: item.city ?? '',
          items: [item],
        );
      }
    }
    return map.values.toList();
  }

  void _openMap() {
    _focusNode.unfocus();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            MapFullScreen(initialRestaurants: _allRestaurants),
        fullscreenDialog: true,
      ),
    );
  }

  List<Marker> _buildMapMarkers() {
    return _allRestaurants
        .where((r) => r.latitude != null && r.longitude != null)
        .map((r) => Marker(
              point: LatLng(r.latitude!, r.longitude!),
              width: 28,
              height: 28,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha:0.4),
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: const Icon(Icons.restaurant_rounded,
                    color: Colors.white, size: 14),
              ),
            ))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // ── Üst %35: Harita Widget ───────────────────────────────
            Expanded(
              flex: 35,
              child: _MapPreview(
                isLoading: _mapLoading,
                center: _istanbul,
                markers: _buildMapMarkers(),
                onTap: _openMap,
              ),
            ),

            // ── Alt %65: Kategoriler + Arama + Sonuçlar ──────────────
            Expanded(
              flex: 65,
              child: Column(
                children: [
                  // Kategori chips
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: _SearchCategoryChips(
                      selectedCategory: _selectedCategory,
                      onCategoryTap: _onCategoryTap,
                    ),
                  ),
                  // Search Bar
                  _SearchBar(
                    controller: _controller,
                    focusNode: _focusNode,
                    onChanged: _onSearchChanged,
                    isLoading: _searching,
                  ),
                  // Sonuç listesi
                  Expanded(
                    child: _query.isEmpty && _selectedCategory == null
                        ? const _EmptySearch()
                        : _results.isEmpty && !_searching
                            ? const _NoResults()
                            : _ResultsList(results: _results),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Kategori chips ────────────────────────────────────────────────────────────

class _SearchCategoryChips extends StatelessWidget {
  const _SearchCategoryChips({
    required this.selectedCategory,
    required this.onCategoryTap,
  });

  final String? selectedCategory;
  final ValueChanged<String> onCategoryTap;

  static const _categories = [
    'Burger', 'Pizza', 'Kebap', 'Sushi', 'Tavuk',
    'Kahvaltı', 'Tatlı', 'İtalyan', 'Vegan', 'Meze', 'Noodle',
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final label = _categories[i];
          final isSelected = selectedCategory == label;
          return GestureDetector(
            onTap: () => onCategoryTap(label),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary
                    : context.surfaceElevatedColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color:
                      isSelected ? AppColors.primary : context.dividerColor,
                  width: 1,
                ),
              ),
              child: Text(
                label,
                style: AppTextStyles.bodySmall.copyWith(
                  color: isSelected
                      ? Colors.white
                      : context.textPrimaryColor,
                  fontWeight: isSelected
                      ? FontWeight.w600
                      : FontWeight.w400,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Harita önizleme ──────────────────────────────────────────────────────────

class _MapPreview extends StatelessWidget {
  const _MapPreview({
    required this.isLoading,
    required this.center,
    required this.markers,
    required this.onTap,
  });

  final bool isLoading;
  final LatLng center;
  final List<Marker> markers;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: context.dividerColor),
        ),
        child: Stack(
          children: [
            // Harita
            if (isLoading)
              Container(
                color: context.surfaceColor,
                child: const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              )
            else
              FlutterMap(
                options: MapOptions(
                  initialCenter: center,
                  initialZoom: 12,
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.none,
                  ),
                ),
                children: [
                  TileLayer(
                    urlTemplate: context.isDark
                        ? 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png'
                        : 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png',
                    subdomains: const ['a', 'b', 'c', 'd'],
                    userAgentPackageName: 'dishrate_mobile',
                  ),
                  MarkerLayer(markers: markers),
                ],
              ),

            // "Haritada Keşfet" overlay
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withValues(alpha:0.65),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.map_rounded,
                        color: Colors.white, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      'Haritada Keşfet',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    const Icon(Icons.open_in_full_rounded,
                        color: Colors.white54, size: 14),
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

// ── Arama çubuğu ─────────────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.isLoading,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        onChanged: onChanged,
        style: AppTextStyles.bodyMedium,
        decoration: InputDecoration(
          hintText: 'Yemek veya restoran ara...',
          hintStyle:
              AppTextStyles.bodyMedium.copyWith(color: AppColors.textDisabled),
          prefixIcon: const Icon(Icons.search_rounded,
              color: AppColors.textSecondary, size: 22),
          suffixIcon: isLoading
              ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  ),
                )
              : null,
          filled: true,
          fillColor: context.surfaceColor,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: context.dividerColor),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: context.dividerColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide:
                BorderSide(color: AppColors.primary, width: 1.5),
          ),
        ),
      ),
    );
  }
}

// ── Restoran sonuç listesi ────────────────────────────────────────────────────

class _ResultsList extends StatelessWidget {
  const _ResultsList({required this.results});
  final List<_RestaurantResult> results;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      itemCount: results.length,
      itemBuilder: (_, i) => _RestaurantCard(result: results[i]),
    );
  }
}

class _RestaurantCard extends ConsumerWidget {
  const _RestaurantCard({required this.result});
  final _RestaurantResult result;

  Future<void> _showPopup(BuildContext context, WidgetRef ref) async {
    final selectedItem = await showModalBottomSheet<MenuItemModel?>(
      context: context,
      backgroundColor: context.surfaceColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _RestaurantPopup(result: result),
    );

    if (selectedItem == null || !context.mounted) return;

    final restaurant = RestaurantModel(
      restaurantId: selectedItem.restaurantId,
      name: result.name,
      city: result.city,
      district: result.district,
      fullAddress: '',
      latitude: selectedItem.restaurantLatitude,
      longitude: selectedItem.restaurantLongitude,
    );
    ref.read(ratingFlowProvider.notifier).jumpToRateItem(restaurant, selectedItem);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(ctx).size.height * 0.92,
        decoration: BoxDecoration(
          color: ctx.surfaceElevatedColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            SizedBox(
              width: 40,
              height: 4,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: ctx.dividerColor,
                  borderRadius: const BorderRadius.all(Radius.circular(2)),
                ),
              ),
            ),
            SizedBox(height: 20),
            Expanded(child: AddRatingScreen()),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = [result.district, result.city]
        .where((s) => s != null && s.isNotEmpty)
        .join(', ');
    final itemCount = result.items.length;

    return GestureDetector(
      onTap: () => _showPopup(context, ref),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: context.surfaceColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: context.dividerColor),
        ),
        child: Row(
          children: [
            // İkon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: context.surfaceElevatedColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.storefront_rounded,
                  color: AppColors.textDisabled, size: 20),
            ),
            const SizedBox(width: 12),
            // Bilgiler
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Restoran adına dokunmak restoran sayfasını açar
                  // (kartın kalanı eşleşen ürünleri gösterir)
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => RestaurantDetailScreen(
                          restaurantId: result.restaurantId,
                          restaurantName: result.name,
                          locationText: location,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Flexible(
                          child: Text(result.name,
                              style: AppTextStyles.titleSmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.north_east_rounded,
                            size: 13, color: AppColors.primary),
                      ],
                    ),
                  ),
                  if (location.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(location, style: AppTextStyles.bodySmall),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    '$itemCount eşleşen ürün',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.textDisabled, size: 20),
          ],
        ),
      ),
    );
  }
}

// ── Restoran popup ────────────────────────────────────────────────────────────

class _RestaurantPopup extends StatelessWidget {
  const _RestaurantPopup({required this.result});
  final _RestaurantResult result;

  @override
  Widget build(BuildContext context) {
    final location = [result.district, result.city]
        .where((s) => s != null && s.isNotEmpty)
        .join(', ');

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.5,
      minChildSize: 0.3,
      maxChildSize: 0.85,
      builder: (_, scrollController) => Column(
        children: [
          // Handle
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 8),
            child: Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: context.dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
          // Restoran başlığı
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: context.surfaceElevatedColor,
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
                      Text(result.name, style: AppTextStyles.titleSmall),
                      if (location.isNotEmpty)
                        Text(location, style: AppTextStyles.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Ayırıcı + başlık
          Container(height: 0.5, color: context.dividerColor),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Eşleşen ürünler',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          // Ürün listesi
          Expanded(
            child: ListView.builder(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              itemCount: result.items.length,
              itemBuilder: (_, i) => _PopupItemRow(item: result.items[i]),
            ),
          ),
        ],
      ),
    );
  }
}

class _PopupItemRow extends StatefulWidget {
  const _PopupItemRow({required this.item});
  final MenuItemModel item;

  @override
  State<_PopupItemRow> createState() => _PopupItemRowState();
}

class _PopupItemRowState extends State<_PopupItemRow> {
  bool _wishlistLoading = false;
  bool _inWishlist = false;

  Future<void> _onWishlist() async {
    if (_wishlistLoading) return;
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
        if (mounted) setState(() { _inWishlist = false; _wishlistLoading = false; });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: const Text('İstek listesinden çıkarıldı.'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ));
        }
      } else {
        await WishlistRepository.instance
            .addToWishlist(userId, widget.item.menuItemId);
        if (mounted) setState(() { _inWishlist = true; _wishlistLoading = false; });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: const Text('İstek listene eklendi.'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ));
        }
      }
    } catch (_) {
      if (mounted) setState(() => _wishlistLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('İşlem başarısız, tekrar dene.'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: context.surfaceElevatedColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Yemek adı + puan + fiyat
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.item.name, style: AppTextStyles.bodyMedium),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        RatingBarIndicator(
                          rating: widget.item.averageRating,
                          itemSize: 13,
                          itemBuilder: (_, __) => const Icon(
                            Icons.star_rounded,
                            color: AppColors.star,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          widget.item.averageRating.toStringAsFixed(1),
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.star,
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
          Divider(height: 1, color: context.dividerColor),
          const SizedBox(height: 8),
          // Aksiyon butonları
          Row(
            children: [
              Expanded(
                child: _ItemActionButton(
                  icon: _inWishlist
                      ? Icons.bookmark_rounded
                      : Icons.bookmark_border_rounded,
                  label: _inWishlist ? 'Listeden Çıkar' : 'İstek Listesi\'ne Ekle',
                  isLoading: _wishlistLoading,
                  isPrimary: false,
                  onTap: _onWishlist,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ItemActionButton(
                  icon: Icons.star_rounded,
                  label: 'Değerlendir',
                  isPrimary: true,
                  onTap: () => Navigator.pop(context, widget.item),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ItemActionButton extends StatelessWidget {
  const _ItemActionButton({
    required this.icon,
    required this.label,
    required this.isPrimary,
    required this.onTap,
    this.isLoading = false,
  });

  final IconData icon;
  final String label;
  final bool isPrimary;
  final VoidCallback onTap;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final bgColor =
        isPrimary ? AppColors.primary : context.surfaceElevatedColor;
    final fgColor = isPrimary ? Colors.white : context.textPrimaryColor;
    final borderColor = isPrimary ? AppColors.primary : context.dividerColor;

    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: borderColor),
        ),
        child: isLoading
            ? Center(
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: fgColor,
                  ),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 15, color: fgColor),
                  const SizedBox(width: 5),
                  Text(
                    label,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: fgColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

// ── Boş durumlar ──────────────────────────────────────────────────────────────

class _EmptySearch extends StatelessWidget {
  const _EmptySearch();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.search_rounded,
              color: AppColors.textDisabled, size: 48),
          const SizedBox(height: 12),
          Text(
            'Yemek veya restoran ara',
            style:
                AppTextStyles.titleMedium.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 6),
          Text(
            'Üstteki haritayı kullanarak\nçevrendeki restoranları keşfedebilirsin.',
            style: AppTextStyles.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _NoResults extends StatelessWidget {
  const _NoResults();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.sentiment_dissatisfied_rounded,
              color: AppColors.textDisabled, size: 44),
          const SizedBox(height: 12),
          Text('Sonuç bulunamadı',
              style: AppTextStyles.titleMedium
                  .copyWith(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

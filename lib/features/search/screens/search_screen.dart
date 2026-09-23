import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/constants/app_categories.dart';
import '../../../core/network/restaurant_repository.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_metrics.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/models/menu_item_model.dart';
import '../../../shared/models/restaurant_model.dart';
import '../../../shared/widgets/map_tiles.dart';
import '../../../shared/widgets/min_tap_area.dart';
import '../../../shared/widgets/state_message.dart';
import '../../restaurant/screens/restaurant_detail_screen.dart';
import 'map_full_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  static const _istanbul = LatLng(41.0082, 28.9784);

  /// Bundan kısa metinle arama yapılmaz — sunucu da yapmıyor.
  static const _minQuery = 2;

  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  List<RestaurantModel> _allRestaurants = [];
  List<SearchResult> _results = [];
  bool _mapLoading = true;
  bool _searching = false;
  bool _failed = false;
  String _query = '';
  String? _selectedCategory;
  Timer? _debounce;

  /// Ekrandaki sonuçların hangi arama için geldiği.
  ///
  /// "Sonuç bulunamadı" yalnızca şu anki aramanın sonucu gerçekten boşsa
  /// gösteriliyor. Önceden yazarken, bekleme süresi dolmadan sonuç listesi
  /// boş olduğu için "pizza" daha yazılırken üzgün surat çıkıyordu.
  String? _resultsFor;

  /// Son isteğin sırası: hızlı yazarken eski yanıt yenisinin üstüne yazmasın.
  int _request = 0;

  String? get _activeKey {
    if (_selectedCategory != null) return 'kategori:$_selectedCategory';
    final q = _query.trim();
    return q.length >= _minQuery ? 'metin:$q' : null;
  }

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
    } catch (_) {
      // Harita önizlemesi işaretsiz kalır; arama yine çalışır.
    } finally {
      if (mounted) setState(() => _mapLoading = false);
    }
  }

  void _clearResults() {
    _request++;
    setState(() {
      _results = [];
      _resultsFor = null;
      _searching = false;
      _failed = false;
    });
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    setState(() {
      _query = value;
      _selectedCategory = null; // metin araması kategoriden bağımsız
    });

    final q = value.trim();
    if (q.length < _minQuery) {
      _clearResults();
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 350), () {
      _run('metin:$q', () => RestaurantRepository.instance.search(q));
    });
  }

  void _onCategoryTap(String label) {
    final again = _selectedCategory == label;
    _debounce?.cancel();
    setState(() {
      _selectedCategory = again ? null : label;
      _controller.clear();
      _query = '';
    });
    if (again) {
      _clearResults();
      return;
    }
    _run('kategori:$label', () async {
      final items =
          await RestaurantRepository.instance.getMenuItemsByCategory(label);
      return _groupByRestaurant(items);
    });
  }

  /// Son arama; hata ekranındaki "Tekrar dene" aynısını yeniden gönderir.
  VoidCallback? _retry;

  Future<void> _run(
      String key, Future<List<SearchResult>> Function() loader) async {
    _retry = () => _run(key, loader);
    final request = ++_request;
    setState(() {
      _searching = true;
      _failed = false;
    });
    try {
      final results = await loader();
      if (!mounted || request != _request) return;
      setState(() => _results = results);
    } catch (_) {
      if (!mounted || request != _request) return;
      setState(() {
        _results = [];
        _failed = true;
      });
    } finally {
      if (mounted && request == _request) {
        setState(() {
          _resultsFor = key;
          _searching = false;
        });
      }
    }
  }

  /// Kategori çipi: menü öğelerini restoran kartlarına dönüştürür.
  List<SearchResult> _groupByRestaurant(List<MenuItemModel> items) {
    final groups = <int, List<MenuItemModel>>{};
    final first = <int, MenuItemModel>{};
    for (final item in items) {
      (groups[item.restaurantId] ??= []).add(item);
      first.putIfAbsent(item.restaurantId, () => item);
    }
    return [
      for (final e in groups.entries)
        SearchResult(
          restaurantId: e.key,
          name: first[e.key]!.restaurantName,
          city: first[e.key]!.city,
          district: first[e.key]!.district,
          latitude: first[e.key]!.restaurantLatitude,
          longitude: first[e.key]!.restaurantLongitude,
          nameMatched: false,
          items: e.value,
        ),
    ];
  }

  void _openMap() {
    _focusNode.unfocus();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MapFullScreen(initialRestaurants: _allRestaurants),
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
                      color: AppColors.primary.withValues(alpha: 0.4),
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

  Widget _buildResults() {
    final key = _activeKey;
    if (key == null) return const _EmptySearch();

    final settled = _resultsFor == key && !_searching;
    if (settled && _failed) return _SearchFailed(onRetry: _retry);
    if (settled && _results.isEmpty) return const _NoResults();
    if (_results.isEmpty) {
      // İlk sonuç bekleniyor: boş durum yerine sessiz gösterge.
      return const Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(
              strokeWidth: 2, color: AppColors.primary),
        ),
      );
    }
    return _ResultsList(results: _results);
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
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: _SearchCategoryChips(
                      selectedCategory: _selectedCategory,
                      onCategoryTap: _onCategoryTap,
                    ),
                  ),
                  _SearchBar(
                    controller: _controller,
                    focusNode: _focusNode,
                    onChanged: _onSearchChanged,
                    isLoading: _searching,
                  ),
                  Expanded(child: _buildResults()),
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

  @override
  Widget build(BuildContext context) {
    const categories = AppCategories.all;
    // Şerit dokunma alanı kadar yüksek; çip görünüşte aynı boyda kalıyor.
    return SizedBox(
      height: AppSize.minTap,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final label = categories[i];
          final isSelected = selectedCategory == label;
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => onCategoryTap(label),
            child: MinTapArea(
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
                    color: isSelected ? Colors.white : context.textPrimaryColor,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
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
    return Semantics(
      button: true,
      label: 'Haritayı aç',
      child: GestureDetector(
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
                    const AppTileLayer(),
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
                        Colors.black.withValues(alpha: 0.65),
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
        textInputAction: TextInputAction.search,
        style: AppTextStyles.bodyMedium,
        decoration: InputDecoration(
          hintText: 'Yemek veya restoran ara...',
          hintStyle: AppTextStyles.bodyMedium
              .copyWith(color: context.textTertiaryColor),
          prefixIcon: Icon(Icons.search_rounded,
              color: context.textSecondaryColor, size: 22),
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
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
          ),
        ),
      ),
    );
  }
}

// ── Restoran sonuç listesi ────────────────────────────────────────────────────

class _ResultsList extends StatelessWidget {
  const _ResultsList({required this.results});
  final List<SearchResult> results;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      itemCount: results.length,
      itemBuilder: (_, i) => _RestaurantCard(result: results[i]),
    );
  }
}

class _RestaurantCard extends StatelessWidget {
  const _RestaurantCard({required this.result});
  final SearchResult result;

  String get _location => [result.district, result.city]
      .where((s) => s != null && s.isNotEmpty)
      .join(', ');

  void _openRestaurant(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RestaurantDetailScreen(
          restaurantId: result.restaurantId,
          restaurantName: result.name,
          locationText: _location,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final location = _location;
    final count = result.items.length;
    final subtitle = result.items.isEmpty
        ? 'Menü henüz eklenmemiş'
        : result.nameMatched
            ? 'Menüye bak'
            : '$count eşleşen ürün';

    // Kart da ad da aynı yere gidiyor: restoran sayfası. Önceden burada
    // aramaya özel bir mini menü açılıyordu; menü tek yerde olsun.
    return Semantics(
      button: true,
      label: '${result.name}, $subtitle',
      child: GestureDetector(
        onTap: () => _openRestaurant(context),
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
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: context.surfaceElevatedColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.storefront_rounded,
                    color: context.textTertiaryColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Restoran adına dokunmak restoran sayfasını açar
                    // (kartın kalanı eşleşen ürünleri gösterir)
                    GestureDetector(
                      onTap: () => _openRestaurant(context),
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
                      subtitle,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  color: context.textTertiaryColor, size: 20),
            ],
          ),
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
          Icon(Icons.search_rounded,
              color: context.textTertiaryColor, size: 48),
          const SizedBox(height: 12),
          Text(
            'Yemek veya restoran ara',
            style: AppTextStyles.titleMedium
                .copyWith(color: context.textSecondaryColor),
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

/// Boş ve hata durumları Keşfet'teki gibi sola hizalı `StateMessage`.
class _NoResults extends StatelessWidget {
  const _NoResults();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding:
          EdgeInsets.fromLTRB(AppSpace.screen, AppSpace.xl, AppSpace.screen, 0),
      child: Align(
        alignment: Alignment.topLeft,
        child: StateMessage(
          title: 'Sonuç bulunamadı',
          message: 'Farklı bir yemek ya da restoran adı dene.',
        ),
      ),
    );
  }
}

class _SearchFailed extends StatelessWidget {
  const _SearchFailed({this.onRetry});
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpace.screen, AppSpace.xl, AppSpace.screen, 0),
      child: Align(
        alignment: Alignment.topLeft,
        child: StateMessage(
          title: 'Arama yapılamadı',
          message: 'Bağlantını kontrol edip tekrar dene.',
          actionLabel: onRetry == null ? null : 'Tekrar dene',
          onAction: onRetry,
        ),
      ),
    );
  }
}

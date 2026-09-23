import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/auth/auth_provider.dart';
import '../../../core/constants/app_categories.dart';
import '../../../core/data/turkey_addresses.dart';
import '../../../core/location/location_service.dart';
import '../../../core/network/rating_repository.dart';
import '../../../core/network/restaurant_repository.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/models/menu_item_model.dart';
import '../../../shared/models/rating_model.dart';
import '../../../shared/models/restaurant_model.dart';
import '../../../shared/widgets/dish_photo.dart';
import '../../../shared/widgets/map_tiles.dart';
import '../../../shared/widgets/min_tap_area.dart';
import '../../../shared/widgets/rating_stars.dart';
import '../../discover/providers/location_provider.dart';
import '../../restaurant/screens/restaurant_detail_screen.dart';

class MapFullScreen extends ConsumerStatefulWidget {
  final List<RestaurantModel> initialRestaurants;

  const MapFullScreen({super.key, required this.initialRestaurants});

  @override
  ConsumerState<MapFullScreen> createState() => _MapFullScreenState();
}

class _MapFullScreenState extends ConsumerState<MapFullScreen> {
  static const _istanbul = LatLng(41.0082, 28.9784);

  /// Konum şeridi kapatıldı mı? (Bu oturum için.)
  bool _locationBannerDismissed = false;

  /// Cihazın konum izni. `null` → henüz bakılmadı; şerit gösterilmez.
  ///
  /// Şerit önceden keşfetteki konumun *kaynağına* bakıyordu: konum elle
  /// seçildiyse izin verilmiş olsa bile "konumunu aç" diyordu. Artık yalnızca
  /// cihaz izni yoksa çıkıyor.
  bool? _hasPermission;

  /// Kullanıcının puanladığı yemekler, restoran kimliğine göre.
  Map<int, List<RatingModel>> _myRatings = const {};

  /// Yalnızca puanlanan restoranlar mı gösteriliyor?
  bool _onlyRated = false;

  /// Harita nereye ortalansın?
  ///
  /// Konum izni yoksa haritayı ENGELLEMİYORUZ — restoran koordinatları
  /// sunucudan geliyor, harita kullanıcının nerede olduğunu bilmeden de
  /// işini görüyor. Sadece seçili konuma ortalıyoruz.
  LatLng get _center {
    final loc = ref.watch(selectedLocationProvider);
    if (loc.hasCoordinates) {
      return LatLng(loc.latitude!, loc.longitude!);
    }
    // Konum yoksa: seçili ilçe/ildeki restoranların ortalaması.
    final matches = widget.initialRestaurants.where((r) {
      if (r.latitude == null || r.longitude == null) return false;
      final target = loc.hasDistrict ? loc.district! : loc.province;
      final area = loc.hasDistrict ? r.district : r.city;
      return area != null &&
          TurkeyAddresses.searchKey(area) == TurkeyAddresses.searchKey(target);
    }).toList();
    if (matches.isEmpty) return _istanbul;
    final lat = matches.map((r) => r.latitude!).reduce((a, b) => a + b) /
        matches.length;
    final lng = matches.map((r) => r.longitude!).reduce((a, b) => a + b) /
        matches.length;
    return LatLng(lat, lng);
  }

  String? _selectedCategory;
  List<RestaurantModel> _visibleRestaurants = [];
  bool _isFiltering = false;

  @override
  void initState() {
    super.initState();
    _visibleRestaurants = widget.initialRestaurants;
    _checkPermission();
    _loadMyRatings();
  }

  Future<void> _checkPermission() async {
    final permission = await LocationService.hasPermission();
    if (mounted) setState(() => _hasPermission = permission);
  }

  Future<void> _loadMyRatings() async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;
    try {
      final list = await RatingRepository.instance.getRatingsByUser(userId);
      final map = <int, List<RatingModel>>{};
      for (final r in list) {
        final id = r.restaurantId;
        if (id != null) (map[id] ??= []).add(r);
      }
      for (final l in map.values) {
        l.sort((a, b) => b.score.compareTo(a.score));
      }
      if (mounted) setState(() => _myRatings = map);
    } catch (_) {
      // Puan işaretleri olmadan da harita çalışır.
    }
  }

  Future<void> _onCategoryTap(String label) async {
    if (_selectedCategory == label) {
      setState(() {
        _selectedCategory = null;
        _visibleRestaurants = widget.initialRestaurants;
      });
      return;
    }

    final previous = _selectedCategory;
    setState(() {
      _selectedCategory = label;
      _isFiltering = true;
    });

    try {
      final items =
          await RestaurantRepository.instance.getMenuItemsByCategory(label);
      final markers = _itemsToRestaurants(items);
      if (mounted) {
        setState(() {
          _visibleRestaurants = markers;
          _isFiltering = false;
        });
      }
    } catch (_) {
      // Önceden çip seçili görünüp harita eski işaretlerle kalıyordu; filtre
      // uygulanmış sanılıyordu. Seçim geri alınır ve söylenir.
      if (!mounted) return;
      setState(() {
        _selectedCategory = previous;
        _isFiltering = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Filtre uygulanamadı, tekrar dene.')),
      );
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

  List<Marker> _buildMarkers() {
    final shown = _onlyRated
        ? _visibleRestaurants
            .where((r) => _myRatings.containsKey(r.restaurantId))
        : _visibleRestaurants;
    return shown
        .where((r) => r.latitude != null && r.longitude != null)
        .map((r) {
      final rated = _myRatings.containsKey(r.restaurantId);
      return Marker(
        point: LatLng(r.latitude!, r.longitude!),
        width: 52,
        height: 52,
        child: Semantics(
          button: true,
          label: r.name,
          child: GestureDetector(
            onTap: () => _openPreview(r),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  margin: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    // Puanladığın restoranlar turuncu halkalı.
                    border: rated
                        ? Border.all(color: AppColors.primary, width: 3)
                        : null,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.35),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  // Restoranın türü (menüsündeki çoğunluk kategori) sade ikonla.
                  child: Center(
                    child: Icon(
                      AppCategories.icon(r.categoryName),
                      size: 22,
                      color: const Color(0xFF1A1A1A),
                    ),
                  ),
                ),
                if (rated)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.star_rounded,
                          size: 12, color: AppColors.onPrimary),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    }).toList();
  }

  /// İşarete dokununca küçük bir önizleme kartı açılır: restoran, varsa
  /// puanladığın yemekler ve "Menüyü aç".
  ///
  /// Önceden burada haritaya özel bir mini menü açılıyordu: arama kutusu yok,
  /// sıralama yok, uzun menüde aradığın yemeğe ulaşmak için hepsini kaydırmak
  /// gerekiyordu. Artık menü tek yerde — restoran sayfasında.
  Future<void> _openPreview(RestaurantModel restaurant) async {
    final open = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PreviewCard(
        restaurant: restaurant,
        ratings: _myRatings[restaurant.restaurantId] ?? const [],
      ),
    );
    if (open == true && mounted) await _openRestaurantPage(restaurant);
  }

  Future<void> _openRestaurantPage(RestaurantModel restaurant) async {
    final place = [restaurant.district, restaurant.city]
        .where((s) => s != null && s.isNotEmpty)
        .join(', ');
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RestaurantDetailScreen(
          restaurantId: restaurant.restaurantId,
          restaurantName: restaurant.name,
          locationText: place,
        ),
      ),
    );
    // Sayfada puan verilmiş olabilir; işaretler güncellensin.
    if (mounted) _loadMyRatings();
  }

  Widget _buildLocationBanner() {
    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.only(top: 64, left: 12, right: 12),
          child: Container(
            padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.72),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.my_location_rounded,
                    color: AppColors.primary, size: 18),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    'Sana en yakınındaki yemekleri gösterebilmemiz için '
                    'konumunu aç.',
                    style:
                        AppTextStyles.bodySmall.copyWith(color: Colors.white),
                  ),
                ),
                TextButton(
                  onPressed: _requestLocation,
                  child: Text('Aç',
                      style: AppTextStyles.labelLarge
                          .copyWith(color: AppColors.primary)),
                ),
                IconButton(
                  icon: Icon(Icons.close_rounded,
                      size: 18, color: Colors.white.withValues(alpha: 0.7)),
                  tooltip: 'Konum şeridini kapat',
                  onPressed: () =>
                      setState(() => _locationBannerDismissed = true),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _requestLocation() async {
    final notifier = ref.read(selectedLocationProvider.notifier);
    final r = await notifier.requestGps();
    if (!mounted) return;
    if (r.isOk) {
      setState(() {
        _hasPermission = true;
        _locationBannerDismissed = true;
      });
      return;
    }
    final message = switch (r.outcome) {
      LocationOutcome.serviceDisabled =>
        'Cihazının konum servisi kapalı. Ayarlardan açabilirsin.',
      LocationOutcome.deniedForever =>
        'Konum izni kapalı. Ayarlar’dan açabilirsin.',
      _ => 'Konum alınamadı. Şehri kendin seçebilirsin.',
    };
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        action: r.outcome == LocationOutcome.deniedForever
            ? const SnackBarAction(
                label: 'Ayarlar',
                // Varsayılan aksiyon rengi açık temada beyaz zemin üstünde
                // beyaz kalıyor ve buton hiç görünmüyordu.
                textColor: AppColors.primary,
                onPressed: LocationService.openSettings)
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ── Harita ──────────────────────────────────────────────────
          FlutterMap(
            options: MapOptions(
              initialCenter: _center,
              initialZoom: 12,
            ),
            children: [
              const AppTileLayer(),
              MarkerLayer(markers: _buildMarkers()),
              const MapAttribution(),
            ],
          ),

          // ── Konum şeridi ────────────────────────────────────────────
          // Engellemez, kapatılabilir. Konum izni olmayan kullanıcı
          // haritayı yine de kullanabilsin diye böyle: haritanın işi
          // "restoranlar nerede", "ben neredeyim" değil.
          if (!_locationBannerDismissed && _hasPermission == false)
            _buildLocationBanner(),

          // ── Üst sıra: geri + "Puanladıklarım" ────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  _MapButton(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.arrow_back_rounded,
                        color: Colors.white, size: 20),
                  ),
                  const Spacer(),
                  if (_myRatings.isNotEmpty)
                    _CategoryChip(
                      label: '★ Puanladıklarım',
                      isSelected: _onlyRated,
                      onTap: () => setState(() => _onlyRated = !_onlyRated),
                    ),
                ],
              ),
            ),
          ),

          // ── Filtreleme göstergesi ────────────────────────────────────
          if (_isFiltering)
            const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),

          // ── Sağ taraf: kategori butonları ────────────────────────────
          // Kaydırılabilir: küçük ekranda 13 kategori sığmıyor.
          SafeArea(
            child: Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 12, top: 64, bottom: 24),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: AppCategories.all.map((label) {
                      return Padding(
                        // Dokunma alanı çipin çevresini zaten dolduruyor.
                        padding: EdgeInsets.zero,
                        child: _CategoryChip(
                          label: label,
                          isSelected: _selectedCategory == label,
                          onTap: () => _onCategoryTap(label),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Önizleme kartı ────────────────────────────────────────────────────────────

/// Harita işaretinin kartı: restoran künyesi, varsa puanladığın yemekler ve
/// menüye giden düğme. Uzun değil — menünün kendisi restoran sayfasında.
class _PreviewCard extends StatelessWidget {
  const _PreviewCard({required this.restaurant, required this.ratings});

  final RestaurantModel restaurant;
  final List<RatingModel> ratings;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final location = [restaurant.district, restaurant.city]
        .where((s) => s != null && s.isNotEmpty)
        .join(', ');

    return Container(
      constraints: BoxConstraints(maxHeight: media.size.height * 0.6),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: context.dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: context.surfaceElevatedColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    AppCategories.icon(restaurant.categoryName),
                    size: 22,
                    color: context.textSecondaryColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(restaurant.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.titleSmall),
                      Text(
                        [
                          if (restaurant.categoryName != null)
                            restaurant.categoryName!,
                          if (location.isNotEmpty) location,
                        ].join(' · '),
                        style: AppTextStyles.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (ratings.isNotEmpty) ...[
            const SizedBox(height: 12),
            Divider(height: 1, color: context.dividerColor),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
              child: Text(
                'Puanladığın ${ratings.length} yemek',
                style: AppTextStyles.bodySmall.copyWith(
                  color: context.textSecondaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: ratings.length,
                separatorBuilder: (_, __) =>
                    Divider(height: 1, color: context.dividerColor),
                itemBuilder: (_, i) {
                  final r = ratings[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      children: [
                        DishPhoto(
                          url: r.reviewPhotoUrl ?? r.photoUrl,
                          width: 40,
                          height: 40,
                          radius: 8,
                          iconSize: 16,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            r.menuItemName,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.bodyMedium
                                .copyWith(color: context.textPrimaryColor),
                          ),
                        ),
                        const SizedBox(width: 12),
                        StarRow(rating: r.score, size: 14),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
          Padding(
            padding: EdgeInsets.fromLTRB(20, 16, 20, media.padding.bottom + 12),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Menüyü aç'),
              ),
            ),
          ),
        ],
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
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: MinTapArea(
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
    // Çip ~36 pt: 44 pt'lik dokunma kutusunda alt alta dizilince aralarında
    // 1.4 öncesindeki gibi ~8 pt kalıyor. 30 pt'lik eski boyda kutular çipleri
    // 17 pt aralıkla seyrek diziyordu, çipler küçülmüş gibi görünüyordu.
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: MinTapArea(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary
                : Colors.black.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(12),
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
              fontSize: 12,
              // Seçiliyken de beyaz: keşfet ve aramadaki çiplerle aynı.
              color: Colors.white,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }
}

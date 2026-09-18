import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import '../../../core/network/restaurant_repository.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_metrics.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/turkish_text.dart';
import '../../../shared/models/menu_item_model.dart';
import '../../../shared/widgets/dish_photo.dart';
import '../../../shared/widgets/pressable.dart';
import '../../../shared/widgets/skeleton.dart';
import '../../../shared/widgets/state_message.dart';
import '../providers/rating_flow_provider.dart';

class Step2MenuItemSelect extends ConsumerStatefulWidget {
  const Step2MenuItemSelect({super.key});

  @override
  ConsumerState<Step2MenuItemSelect> createState() =>
      _Step2MenuItemSelectState();
}

class _Step2MenuItemSelectState extends ConsumerState<Step2MenuItemSelect> {
  final _searchController = TextEditingController();
  List<MenuItemModel> _allItems = [];
  List<MenuItemModel> _filteredItems = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadMenu();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadMenu() async {
    final restaurant =
        ref.read(ratingFlowProvider).selectedRestaurant;
    if (restaurant == null) return;

    try {
      final items = await RestaurantRepository.instance
          .getRestaurantMenu(restaurant.restaurantId);
      if (mounted) {
        setState(() {
          _allItems = items;
          _filteredItems = items;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'Menü yüklenemedi';
          _isLoading = false;
        });
      }
    }
  }

  void _filter(String query) {
    setState(() {
      _filteredItems = query.isEmpty
          ? _allItems
          : _allItems
              .where((item) =>
                  item.name.toLowerCase().contains(query.toLowerCase()))
              .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final restaurant = ref.watch(ratingFlowProvider).selectedRestaurant;
    // Akış sıfırlanırken panel kapanana kadar bir kare daha çizilebiliyor.
    if (restaurant == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Başlık ──────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpace.screen, AppSpace.md, AppSpace.screen, 0),
          child: Text(
            'Ne yedin?',
            style: AppTextStyles.displayLarge
                .copyWith(color: context.textPrimaryColor),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpace.screen, AppSpace.sm, AppSpace.screen, AppSpace.screen),
          child: Row(
            children: [
              Icon(TablerIcons.building_store,
                  size: 16, color: context.textSecondaryColor),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  restaurant.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyMedium
                      .copyWith(color: context.textSecondaryColor),
                ),
              ),
            ],
          ),
        ),

        // ── Menü Arama ───────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.screen),
          child: TextField(
            controller: _searchController,
            style: AppTextStyles.bodyLarge,
            decoration: const InputDecoration(
              hintText: 'Menüde ara',
              prefixIcon: Icon(TablerIcons.search, size: 20),
            ),
            onChanged: _filter,
          ),
        ),

        const SizedBox(height: AppSpace.xs),

        // ── Menü Listesi ─────────────────────────────────────────────────
        Expanded(child: _buildContent()),
      ],
    );
  }

  Widget _buildContent() {
    const pad = EdgeInsets.fromLTRB(
        AppSpace.screen, AppSpace.lg, AppSpace.screen, 0);

    if (_isLoading) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(
            AppSpace.screen, AppSpace.sm, AppSpace.screen, 0),
        children: const [
          SkeletonPulse(child: SkeletonRows(count: 5, leadingSize: 52)),
        ],
      );
    }

    if (_error != null) {
      return ListView(
        padding: pad,
        children: [
          StateMessage(
            title: _error!,
            message: 'Bağlantını kontrol edip tekrar dene.',
            actionLabel: 'Tekrar dene',
            onAction: () {
              setState(() {
                _isLoading = true;
                _error = null;
              });
              _loadMenu();
            },
          ),
        ],
      );
    }

    if (_filteredItems.isEmpty) {
      final menuEmpty = _allItems.isEmpty;
      return ListView(
        padding: pad,
        children: [
          StateMessage(
            title: menuEmpty ? 'Menü henüz boş' : 'Eşleşen yemek yok',
            message: menuEmpty
                ? 'Bu restoranın menüsü eklendiğinde buradan seçebileceksin.'
                : 'Farklı bir kelimeyle aramayı dene.',
          ),
        ],
      );
    }

    // Kategorilere göre grupla
    final grouped = <String, List<MenuItemModel>>{};
    for (final item in _filteredItems) {
      final category = item.categoryName ?? 'Diğer';
      grouped.putIfAbsent(category, () => []).add(item);
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: AppSpace.screen),
      itemCount: grouped.length,
      itemBuilder: (context, groupIndex) {
        final category = grouped.keys.elementAt(groupIndex);
        final items = grouped[category]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Kategori başlığı
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpace.screen, AppSpace.screen, AppSpace.screen, 2),
              child: Text(
                // Dart'ın toUpperCase()'i "Diğer"i DIĞER yapıyor (İ yerine I).
                TurkishText.upper(category),
                style: AppTextStyles.label.copyWith(
                  fontSize: 12,
                  letterSpacing: 0.8,
                  color: context.textSecondaryColor,
                ),
              ),
            ),
            // Kategori öğeleri
            ...items.map((item) => _MenuItemTile(
                  item: item,
                  onTap: () => ref
                      .read(ratingFlowProvider.notifier)
                      .selectMenuItem(item),
                )),
          ],
        );
      },
    );
  }
}

// ── Menü öğesi listesi satırı ─────────────────────────────────────────────────

/// Satırda kategori tekrar edilmiyor (grup başlığı zaten söylüyor) ve sağ ok
/// yok: listenin tamamı dokunulabilir, her satıra ok koymak yalnızca gürültü.
class _MenuItemTile extends StatelessWidget {
  const _MenuItemTile({required this.item, required this.onTap});

  final MenuItemModel item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      scale: 0.98,
      semanticLabel: item.name,
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpace.screen, vertical: 10),
        child: Row(
          children: [
            DishPhoto(
              url: item.photoUrl,
              width: 52,
              height: 52,
              radius: AppRadius.sm,
              iconSize: 20,
            ),
            const SizedBox(width: AppSpace.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: AppTextStyles.titleSmall
                        .copyWith(color: context.textPrimaryColor),
                  ),
                  // Puan bilerek gösterilmiyor: kullanıcı kendi puanını
                  // vermeden önce başkalarının ortalamasını görürse o sayıya
                  // yanaşıyor. Keşfet, arama ve haritada puanlar duruyor —
                  // orada iş keşfetmek, burada değerlendirmek.
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/restaurant_repository.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/models/menu_item_model.dart';
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
          _error = 'Menü yüklenemedi. Lütfen tekrar dene.';
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
    final restaurant = ref.watch(ratingFlowProvider).selectedRestaurant!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Başlık ──────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
          child: Text('Ne yedin?', style: AppTextStyles.headlineLarge),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Row(
            children: [
              const Icon(Icons.storefront_rounded,
                  color: AppColors.primary, size: 14),
              const SizedBox(width: 5),
              Text(restaurant.name,
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.primary)),
            ],
          ),
        ),

        // ── Menü Arama ───────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: TextField(
            controller: _searchController,
            style: AppTextStyles.bodyLarge,
            decoration: const InputDecoration(
              hintText: 'Menüde ara...',
              prefixIcon: Icon(Icons.search_rounded,
                  color: AppColors.textSecondary),
            ),
            onChanged: _filter,
          ),
        ),

        const SizedBox(height: 12),

        // ── Menü Listesi ─────────────────────────────────────────────────
        Expanded(child: _buildContent()),
      ],
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline,
                color: AppColors.error, size: 40),
            const SizedBox(height: 12),
            Text(_error!, style: AppTextStyles.bodyMedium),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _error = null;
                });
                _loadMenu();
              },
              child: const Text('Tekrar Dene'),
            ),
          ],
        ),
      );
    }

    if (_filteredItems.isEmpty) {
      return Center(
        child: Text(
          'Menüde ürün bulunamadı.',
          style: AppTextStyles.bodyMedium
              .copyWith(color: AppColors.textSecondary),
        ),
      );
    }

    // Kategorilere göre grupla
    final grouped = <String, List<MenuItemModel>>{};
    for (final item in _filteredItems) {
      final category = item.categoryName ?? 'Diğer';
      grouped.putIfAbsent(category, () => []).add(item);
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 20),
      itemCount: grouped.length,
      itemBuilder: (context, groupIndex) {
        final category = grouped.keys.elementAt(groupIndex);
        final items = grouped[category]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Kategori başlığı
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Text(
                category.toUpperCase(),
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.textDisabled,
                  letterSpacing: 1.2,
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

class _MenuItemTile extends StatelessWidget {
  const _MenuItemTile({required this.item, required this.onTap});

  final MenuItemModel item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            // Fotoğraf küçük görsel
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(10),
              ),
              clipBehavior: Clip.hardEdge,
              child: item.photoUrl != null && item.photoUrl!.isNotEmpty
                  ? Image.network(item.photoUrl!, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _placeholder())
                  : _placeholder(),
            ),
            const SizedBox(width: 14),
            // Bilgiler
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.name, style: AppTextStyles.titleSmall),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (item.averageRating > 0) ...[
                        const Icon(Icons.star_rounded,
                            color: AppColors.star, size: 13),
                        const SizedBox(width: 3),
                        Text(
                          item.averageRating.toStringAsFixed(1),
                          style: AppTextStyles.ratingSmall
                              .copyWith(fontSize: 12),
                        ),
                      ],
                      if (item.categoryName != null) ...[
                        if (item.averageRating > 0)
                          const SizedBox(width: 8),
                        Text(
                          item.categoryName!,
                          style: AppTextStyles.bodySmall,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.textSecondary, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() => Container(
        color: AppColors.divider,
        child: const Icon(Icons.restaurant_rounded,
            color: AppColors.textDisabled, size: 22),
      );
}

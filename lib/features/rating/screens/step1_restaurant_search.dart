import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/restaurant_repository.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/models/restaurant_model.dart';
import '../providers/rating_flow_provider.dart';

class Step1RestaurantSearch extends ConsumerStatefulWidget {
  const Step1RestaurantSearch({super.key});

  @override
  ConsumerState<Step1RestaurantSearch> createState() =>
      _Step1RestaurantSearchState();
}

class _Step1RestaurantSearchState extends ConsumerState<Step1RestaurantSearch> {
  final _controller = TextEditingController();
  List<RestaurantModel> _results = [];
  bool _isSearching = false;
  String _lastQuery = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _search(String query) async {
    if (query.trim().length < 2 || query == _lastQuery) return;
    _lastQuery = query;

    setState(() => _isSearching = true);

    try {
      final results =
          await RestaurantRepository.instance.searchRestaurants(query.trim());
      if (mounted) setState(() => _results = results);
    } catch (_) {
      if (mounted) setState(() => _results = []);
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Başlık ──────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
          child: Text('Nerede yedin?', style: AppTextStyles.headlineLarge),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Text(
            'Restoran adını yaz, listeden seç.',
            style: AppTextStyles.bodySmall,
          ),
        ),

        // ── Arama Kutusu ─────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: TextField(
            controller: _controller,
            autofocus: true,
            style: AppTextStyles.bodyLarge,
            decoration: InputDecoration(
              hintText: 'Restoran adı...',
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: AppColors.textSecondary,
              ),
              suffixIcon: _controller.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close_rounded,
                          color: AppColors.textSecondary),
                      onPressed: () {
                        _controller.clear();
                        setState(() {
                          _results = [];
                          _lastQuery = '';
                        });
                      },
                    )
                  : null,
            ),
            onChanged: (value) {
              setState(() {});
              _search(value);
            },
          ),
        ),

        const SizedBox(height: 16),

        // ── Sonuçlar ─────────────────────────────────────────────────────
        Expanded(
          child: _buildResults(),
        ),
      ],
    );
  }

  void _selectHint(String hint) {
    _controller.text = hint;
    setState(() {});
    _search(hint);
  }

  Widget _buildResults() {
    if (_isSearching) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (_controller.text.isEmpty) {
      return _EmptySearchHint(onHintTap: _selectHint);
    }

    if (_results.isEmpty && _controller.text.length >= 2) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.storefront_outlined,
                color: AppColors.textDisabled, size: 48),
            const SizedBox(height: 12),
            Text(
              '"${_controller.text}" ile eşleşen\nrestoran bulunamadı.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: _results.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final restaurant = _results[index];
        return _RestaurantTile(
          restaurant: restaurant,
          onTap: () =>
              ref.read(ratingFlowProvider.notifier).selectRestaurant(restaurant),
        );
      },
    );
  }
}

// ── Boş durum ipucu ───────────────────────────────────────────────────────────

class _EmptySearchHint extends StatelessWidget {
  const _EmptySearchHint({required this.onHintTap});
  final ValueChanged<String> onHintTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Örnek aramalar',
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textDisabled,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ['Burger', 'Sushi', 'Pizza', 'Ocakbaşı', 'Noodle']
                .map((hint) => _HintChip(
                      label: hint,
                      onTap: () => onHintTap(hint),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _HintChip extends StatelessWidget {
  const _HintChip({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.divider),
        ),
        child: Text(label, style: AppTextStyles.bodySmall),
      ),
    );
  }
}

// ── Restoran listesi öğesi ────────────────────────────────────────────────────

class _RestaurantTile extends StatelessWidget {
  const _RestaurantTile({required this.restaurant, required this.onTap});

  final RestaurantModel restaurant;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.divider),
        ),
        child: restaurant.logoUrl != null && restaurant.logoUrl!.isNotEmpty
            ? ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(restaurant.logoUrl!, fit: BoxFit.cover),
              )
            : Center(
                child: Text(
                  restaurant.name.isNotEmpty
                      ? restaurant.name[0].toUpperCase()
                      : '?',
                  style: AppTextStyles.titleMedium
                      .copyWith(color: AppColors.primary),
                ),
              ),
      ),
      title: Text(restaurant.name, style: AppTextStyles.titleSmall),
      subtitle: Text(
        restaurant.district != null
            ? '${restaurant.district}, ${restaurant.city}'
            : restaurant.city,
        style: AppTextStyles.bodySmall,
      ),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: AppColors.textSecondary,
        size: 20,
      ),
    );
  }
}

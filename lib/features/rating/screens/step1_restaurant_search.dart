import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import '../../../core/network/restaurant_repository.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_metrics.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/models/restaurant_model.dart';
import '../../../shared/widgets/dish_photo.dart';
import '../../../shared/widgets/pressable.dart';
import '../../../shared/widgets/skeleton.dart';
import '../../../shared/widgets/state_message.dart';
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

  /// Son arama bağlantı hatasıyla bitti. Önceden hata "Restoran bulunamadı"
  /// gibi görünüyor, kullanıcı restoranın uygulamada olmadığını sanıyordu.
  bool _failed = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _search(String query) async {
    if (query.trim().length < 2 || query == _lastQuery) return;
    _lastQuery = query;

    setState(() {
      _isSearching = true;
      _failed = false;
    });

    try {
      final results =
          await RestaurantRepository.instance.searchRestaurants(query.trim());
      if (mounted) setState(() => _results = results);
    } catch (_) {
      // Aynı sorgu "Tekrar dene" ile yeniden gönderilebilsin.
      _lastQuery = '';
      if (mounted) {
        setState(() {
          _results = [];
          _failed = true;
        });
      }
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
          padding: const EdgeInsets.fromLTRB(
              AppSpace.screen, AppSpace.md, AppSpace.screen, 0),
          child: Text(
            'Nerede yedin?',
            style: AppTextStyles.displayLarge
                .copyWith(color: context.textPrimaryColor),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpace.screen, 6, AppSpace.screen, AppSpace.screen),
          child: Text(
            'Restoran adını yaz, listeden seç.',
            style: AppTextStyles.bodyMedium
                .copyWith(color: context.textSecondaryColor),
          ),
        ),

        // ── Arama Kutusu ─────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.screen),
          child: TextField(
            controller: _controller,
            autofocus: true,
            textInputAction: TextInputAction.search,
            style: AppTextStyles.bodyLarge,
            decoration: InputDecoration(
              hintText: 'Restoran adı',
              prefixIcon: const Icon(TablerIcons.search, size: 20),
              suffixIcon: _controller.text.isNotEmpty
                  ? IconButton(
                      tooltip: 'Temizle',
                      icon: const Icon(TablerIcons.x, size: 18),
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
              setState(() => _failed = false);
              _search(value);
            },
          ),
        ),

        const SizedBox(height: AppSpace.sm),

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
      return ListView(
        padding: const EdgeInsets.symmetric(horizontal: AppSpace.screen),
        children: const [
          SkeletonPulse(child: SkeletonRows(count: 4, leadingSize: 44)),
        ],
      );
    }

    if (_controller.text.isEmpty) {
      return _EmptySearchHint(onHintTap: _selectHint);
    }

    if (_failed) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(
            AppSpace.screen, AppSpace.lg, AppSpace.screen, 0),
        children: [
          StateMessage(
            title: 'Arama yapılamadı',
            message: 'Bağlantını kontrol edip tekrar dene.',
            actionLabel: 'Tekrar dene',
            onAction: () => _search(_controller.text),
          ),
        ],
      );
    }

    if (_results.isEmpty && _controller.text.length >= 2) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(
            AppSpace.screen, AppSpace.lg, AppSpace.screen, 0),
        children: [
          StateMessage(
            title: 'Restoran bulunamadı',
            message:
                '“${_controller.text}” ile eşleşen bir restoran yok. Adın bir kısmını yazmayı dene.',
          ),
        ],
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(
          AppSpace.screen, 0, AppSpace.screen, AppSpace.screen),
      itemCount: _results.length,
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
      padding: const EdgeInsets.fromLTRB(
          AppSpace.screen, AppSpace.md, AppSpace.screen, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Önceden en soluk gri tondaydı; koyu zeminde neredeyse okunmuyordu.
          Text(
            'Örnek aramalar',
            style: AppTextStyles.caption
                .copyWith(color: context.textSecondaryColor),
          ),
          const SizedBox(height: AppSpace.md),
          Wrap(
            spacing: AppSpace.sm,
            runSpacing: AppSpace.sm,
            // Arama restoran adında yapılıyor; her örnek gerçek veride en az
            // bir restoran getirmeli (24 Eylül'de denendi). Lahmacun, mantı,
            // köfte gibi adlar restoran adında geçmediği için boş dönüyordu.
            children: [
              'Burger',
              'Sushi',
              'Pizza',
              'Döner',
              'Kebap',
              'Ocakbaşı',
              'Kahvaltı',
              'Ramen',
              'Noodle',
              'Balık',
            ]
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
    return Pressable(
      onTap: onTap,
      semanticLabel: '$label ara',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        // Nötr dolgu: sabit koyu zemin açık temada kara leke, turuncu zemin de
        // ekranın asıl eylemiyle yarışan bir vurgu oluyordu.
        decoration: BoxDecoration(
          color: context.fillColor,
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Text(
          label,
          style: AppTextStyles.label
              .copyWith(fontSize: 14, color: context.textPrimaryColor),
        ),
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
    final hasLogo =
        restaurant.logoUrl != null && restaurant.logoUrl!.isNotEmpty;

    return Pressable(
      onTap: onTap,
      semanticLabel: restaurant.name,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            // Harf kutusu temaya duyarlı: önceden koyu tema sabitiyle
            // çizildiği için açık temada siyah kare olarak görünüyordu.
            hasLogo
                ? DishPhoto(
                    url: restaurant.logoUrl,
                    width: 44,
                    height: 44,
                    radius: AppRadius.sm,
                    iconSize: 18,
                  )
                : Container(
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: context.fillColor,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Text(
                      restaurant.name.isNotEmpty
                          ? restaurant.name.characters.first
                          : '?',
                      style: AppTextStyles.titleMedium
                          .copyWith(color: context.textSecondaryColor),
                    ),
                  ),
            const SizedBox(width: AppSpace.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    restaurant.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.titleSmall
                        .copyWith(color: context.textPrimaryColor),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    restaurant.district != null
                        ? '${restaurant.district}, ${restaurant.city}'
                        : restaurant.city,
                    style: AppTextStyles.caption
                        .copyWith(color: context.textSecondaryColor),
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

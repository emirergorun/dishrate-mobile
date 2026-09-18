import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';

import '../../../core/data/turkey_addresses.dart';
import '../../../core/network/restaurant_repository.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_metrics.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/models/menu_item_model.dart';
import '../../../shared/widgets/dish_sheet.dart';
import '../../../shared/widgets/pressable.dart';
import '../../../shared/widgets/skeleton.dart';
import '../../../shared/widgets/state_message.dart';
import '../../discover/widgets/dish_layouts.dart';

/// Bir restoranın tam ekran detayı: başlık + puana göre sıralı menü.
///
/// Bir yemeğe dokununca yemek paneli açılır (puan, son yorumlar,
/// Değerlendir). Önceden doğrudan yorum listesine gidiliyordu ve oradan
/// puan vermenin yolu yoktu.
class RestaurantDetailScreen extends ConsumerStatefulWidget {
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
  ConsumerState<RestaurantDetailScreen> createState() =>
      _RestaurantDetailScreenState();
}

class _RestaurantDetailScreenState
    extends ConsumerState<RestaurantDetailScreen> {
  List<MenuItemModel> _menu = [];
  bool _loading = true;
  String? _error;
  _MenuSort _sort = _MenuSort.rating;

  /// Menü içi arama. Uzun menülerde aradığın yemeği kaydırarak aramak
  /// zorunda kalmayasın diye; kısa menüde kutu hiç gösterilmiyor.
  final _menuSearchCtrl = TextEditingController();
  String _menuQuery = '';
  static const int _menuSearchThreshold = 8;

  @override
  void dispose() {
    _menuSearchCtrl.dispose();
    super.dispose();
  }

  /// Arama metnine uyan yemekler (Türkçe karakter ve harf büyüklüğü yok sayılır).
  List<MenuItemModel> get _filteredMenu {
    if (_menuQuery.trim().isEmpty) return _menu;
    final queryKey = TurkeyAddresses.searchKey(_menuQuery.trim());
    return _menu
        .where((m) => TurkeyAddresses.searchKey(m.name).contains(queryKey))
        .toList();
  }

  /// Seçili sıralamaya göre menü. Eşitlikte öbür ölçüt devreye giriyor:
  /// tek kişinin 5 verdiği yemek, 40 kişinin 5 verdiğinin önüne geçmesin.
  List<MenuItemModel> get _sortedMenu {
    final l = [..._filteredMenu];
    switch (_sort) {
      case _MenuSort.rating:
        l.sort((a, b) {
          final c = b.averageRating.compareTo(a.averageRating);
          return c != 0 ? c : b.ratingCount.compareTo(a.ratingCount);
        });
      case _MenuSort.count:
        l.sort((a, b) {
          final c = b.ratingCount.compareTo(a.ratingCount);
          return c != 0 ? c : b.averageRating.compareTo(a.averageRating);
        });
    }
    return l;
  }

  static const _pad = EdgeInsets.fromLTRB(
      AppSpace.screen, AppSpace.xs, AppSpace.screen, AppSpace.xxl);

  @override
  void initState() {
    super.initState();
    _load();
  }

  /// [silent] açıkken iskelet gösterilmez: aşağı çekip yenilerken ya da puan
  /// verip dönünce liste yerinde kalsın, yalnızca rakamlar tazelensin.
  Future<void> _load({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final menu = await RestaurantRepository.instance
          .getRestaurantMenu(widget.restaurantId);
      if (mounted) {
        setState(() {
          _menu = menu;
          _loading = false;
          _error = null;
        });
      }
    } catch (_) {
      if (!mounted) return;
      // Sessiz tazeleme başarısızsa eldeki liste kalsın; hata ekranına
      // düşmek, çalışan sayfayı elinden almak olurdu.
      if (silent && _menu.isNotEmpty) return;
      setState(() {
        _error = 'Menü yüklenemedi';
        _loading = false;
      });
    }
  }

  Future<void> _openDish(MenuItemModel item) async {
    final rated = await DishSheet.open(
      context,
      ref,
      item,
      showRestaurantLink: false,
    );
    // Puan verildiyse ortalamalar ve sıralama değişmiş olabilir.
    if (rated && mounted) _load(silent: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bgColor,
      appBar: AppBar(
        backgroundColor: context.bgColor,
        leading: IconButton(
          icon: const Icon(TablerIcons.chevron_left),
          tooltip: 'Geri',
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => _load(silent: true),
        color: AppColors.primary,
        backgroundColor: context.surfaceColor,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    // Restoran adı yalnızca burada, bir kez. Önceden hem üst barda hem hemen
    // altındaki kenarlıklı başlık kartında yazıyordu.
    final header = _Header(
      name: widget.restaurantName,
      location: widget.locationText,
    );

    if (_loading) {
      return ListView(
        padding: _pad,
        children: [
          header,
          const SizedBox(height: AppSpace.xxl),
          const SkeletonPulse(
            child: SkeletonRows(count: 4, leadingSize: 56),
          ),
        ],
      );
    }

    if (_error != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: _pad,
        children: [
          header,
          const SizedBox(height: AppSpace.xxl),
          StateMessage(
            title: _error!,
            message: 'Bağlantını kontrol edip tekrar dene.',
            actionLabel: 'Tekrar dene',
            onAction: _load,
          ),
        ],
      );
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: _pad,
      children: [
        header,
        const SizedBox(height: AppSpace.xxl),
        Text(
          'Menü',
          style: AppTextStyles.titleLarge
              .copyWith(color: context.textPrimaryColor),
        ),
        // Önceden burada "12 yemek, puana göre sıralı" yazıyordu; sıralama
        // artık seçilebildiği için yerini seçici aldı.
        if (_menu.length >= _menuSearchThreshold) ...[
          const SizedBox(height: AppSpace.md),
          TextField(
            controller: _menuSearchCtrl,
            style: AppTextStyles.bodyMedium,
            decoration: const InputDecoration(
              hintText: 'Menüde ara',
              prefixIcon: Icon(TablerIcons.search, size: 20),
            ),
            onChanged: (v) => setState(() => _menuQuery = v),
          ),
        ],
        if (_menu.isNotEmpty) ...[
          const SizedBox(height: AppSpace.md),
          _SortToggle(
            value: _sort,
            onChanged: (s) => setState(() => _sort = s),
          ),
        ],
        const SizedBox(height: AppSpace.sm),
        if (_menu.isNotEmpty && _sortedMenu.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: AppSpace.sm),
            child: StateMessage(
              title: 'Eşleşen yemek yok',
              message: 'Farklı bir kelimeyle aramayı dene.',
            ),
          )
        else if (_menu.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: AppSpace.sm),
            child: StateMessage(
              title: 'Henüz menü yok',
              message:
                  'Bu restoranın menüsü eklendiğinde yemekler burada puana göre sıralanacak.',
            ),
          )
        else
          ..._rows(_sortedMenu),
      ],
    );
  }

  List<Widget> _rows(List<MenuItemModel> menu) {
    final byCount = _sort == _MenuSort.count;
    return [
      for (var i = 0; i < menu.length; i++)
        DishRankRow(
          // Sıralama ölçütü sıfır olanlar hep altta; numaralar kesintisiz.
          rank: (byCount ? menu[i].ratingCount > 0 : menu[i].averageRating > 0)
              ? i + 1
              : null,
          item: menu[i],
          showRestaurant: false,
          note: byCount
              ? (menu[i].ratingCount > 0
                  ? '${menu[i].ratingCount} değerlendirme'
                  : null)
              : (i == 0 && menu[i].averageRating > 0 ? 'Önerilen' : null),
          onTap: () => _openDish(menu[i]),
        ),
    ];
  }
}

enum _MenuSort { rating, count }

/// Menü sıralaması: puana göre ya da kaç kişinin değerlendirdiğine göre.
class _SortToggle extends StatelessWidget {
  const _SortToggle({required this.value, required this.onChanged});

  final _MenuSort value;
  final ValueChanged<_MenuSort> onChanged;

  @override
  Widget build(BuildContext context) {
    Widget pill(String label, _MenuSort option) {
      final selected = value == option;
      return Pressable(
        onTap: () => onChanged(option),
        semanticLabel: label,
        child: AnimatedContainer(
          duration: AppMotion.fast,
          height: 34,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : context.fillColor,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            label,
            style: AppTextStyles.label.copyWith(
              color: selected ? AppColors.onPrimary : context.textPrimaryColor,
            ),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          pill('Puana göre', _MenuSort.rating),
          const SizedBox(width: AppSpace.sm),
          pill('Değerlendirme sayısına göre', _MenuSort.count),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.name, required this.location});

  final String name;
  final String? location;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          name,
          style: AppTextStyles.headlineLarge
              .copyWith(color: context.textPrimaryColor),
        ),
        if ((location ?? '').isNotEmpty) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(TablerIcons.map_pin,
                  size: 15, color: context.textSecondaryColor),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  location!,
                  style: AppTextStyles.bodyMedium
                      .copyWith(color: context.textSecondaryColor),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

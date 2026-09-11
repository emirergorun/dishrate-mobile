import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';

import '../../../core/network/restaurant_repository.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_metrics.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/models/menu_item_model.dart';
import '../../../shared/widgets/dish_sheet.dart';
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
      // En yüksek puanlı üstte ("Önerilen")
      menu.sort((a, b) => b.averageRating.compareTo(a.averageRating));
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
        if (_menu.isNotEmpty) ...[
          const SizedBox(height: 3),
          Text(
            '${_menu.length} yemek, puana göre sıralı',
            style: AppTextStyles.caption
                .copyWith(color: context.textSecondaryColor),
          ),
        ],
        const SizedBox(height: AppSpace.sm),
        if (_menu.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: AppSpace.sm),
            child: StateMessage(
              title: 'Henüz menü yok',
              message:
                  'Bu restoranın menüsü eklendiğinde yemekler burada puana göre sıralanacak.',
            ),
          )
        else
          for (var i = 0; i < _menu.length; i++)
            DishRankRow(
              // Liste puana göre sıralı; puanlılar hep üstte olduğundan
              // numaralar kesintisiz ilerliyor.
              rank: _menu[i].averageRating > 0 ? i + 1 : null,
              item: _menu[i],
              showRestaurant: false,
              note: i == 0 && _menu[i].averageRating > 0 ? 'Önerilen' : null,
              onTap: () => _openDish(_menu[i]),
            ),
      ],
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

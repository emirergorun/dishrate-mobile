import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import '../../../core/network/restaurant_repository.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_metrics.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/models/menu_item_model.dart';
import '../../../shared/widgets/state_message.dart';
import '../widgets/menu_item_card.dart';

/// "Tümünü gör" ekranı.
///
/// [sectionKey] verilirse liste sunucudan sayfa sayfa gelir; kaydırma sona
/// yaklaştıkça sıradaki sayfa istenir. Verilmezse [items] olduğu gibi
/// gösterilir.
class SeeAllScreen extends StatefulWidget {
  const SeeAllScreen({
    super.key,
    required this.title,
    this.items = const [],
    this.sectionKey,
    this.city,
    this.district,
    this.category,
    this.onItemTap,
  });

  final String title;

  /// Sayfalı modda ilk sayfa gelene kadar gösterilen önizleme.
  final List<MenuItemModel> items;
  final String? sectionKey;
  final String? city;
  final String? district;
  final String? category;
  final void Function(MenuItemModel)? onItemTap;

  @override
  State<SeeAllScreen> createState() => _SeeAllScreenState();
}

class _SeeAllScreenState extends State<SeeAllScreen> {
  static const int _pageSize = 20;

  final _scroll = ScrollController();
  late List<MenuItemModel> _items = widget.items;
  int _nextPage = 0;
  bool _loading = false;
  bool _done = false;
  bool _failed = false;

  bool get _paged => widget.sectionKey != null;

  @override
  void initState() {
    super.initState();
    if (_paged) {
      _scroll.addListener(_onScroll);
      _loadMore();
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scroll.position.extentAfter < 600) _loadMore();
  }

  Future<void> _loadMore() async {
    if (_loading || _done) return;
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      final page = await RestaurantRepository.instance.getFeedSection(
        widget.sectionKey!,
        city: widget.city,
        district: widget.district,
        category: widget.category,
        page: _nextPage,
        size: _pageSize,
      );
      if (!mounted) return;
      setState(() {
        // İlk sayfa önizlemenin yerini alır; sonrakiler eklenir.
        _items = _nextPage == 0 ? page : [..._items, ...page];
        _nextPage++;
        _done = page.length < _pageSize;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _failed = true;
      });
    }
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
        title: Text(
          widget.title,
          style: AppTextStyles.titleMedium
              .copyWith(color: context.textPrimaryColor),
        ),
        titleSpacing: 0,
      ),
      body: _items.isEmpty && !_loading
          ? Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpace.screen, AppSpace.xxl, AppSpace.screen, 0),
              child: _failed
                  ? StateMessage(
                      title: 'Liste yüklenemedi',
                      message: 'Bağlantını kontrol edip tekrar dene.',
                      actionLabel: 'Tekrar dene',
                      onAction: _loadMore,
                    )
                  : const StateMessage(
                      title: 'İçerik bulunamadı',
                      message: 'Bu listede henüz yemek yok.',
                    ),
            )
          : LayoutBuilder(
              builder: (context, constraints) {
                const gap = AppSpace.md;
                final cardWidth =
                    (constraints.maxWidth - AppSpace.screen * 2 - gap) / 2;
                return CustomScrollView(
                  controller: _scroll,
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(
                          AppSpace.screen, AppSpace.md, AppSpace.screen, 0),
                      sliver: SliverGrid.builder(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: gap,
                          mainAxisSpacing: AppSpace.xl,
                          // Sabit oran yerine hesaplanan yükseklik: iki satırlık
                          // yemek adı ya da büyük yazı ölçeği kartı kesmesin.
                          mainAxisExtent:
                              MenuItemCard.heightFor(context, cardWidth),
                        ),
                        itemCount: _items.length,
                        itemBuilder: (context, index) => MenuItemCard(
                          item: _items[index],
                          onTap: () => widget.onItemTap?.call(_items[index]),
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(child: _footer(context)),
                  ],
                );
              },
            ),
    );
  }

  /// Listenin altı: yükleniyor göstergesi ya da sayfa hatasında yeniden dene.
  Widget _footer(BuildContext context) {
    Widget child = const SizedBox.shrink();
    if (_loading) {
      child = const SizedBox.square(
        dimension: 22,
        child: CircularProgressIndicator(
            strokeWidth: 2, color: AppColors.primary),
      );
    } else if (_failed) {
      child = TextButton(
        onPressed: _loadMore,
        child: const Text('Devamı yüklenemedi · Tekrar dene'),
      );
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpace.screen, AppSpace.xl, AppSpace.screen, AppSpace.xxl),
      child: Center(child: child),
    );
  }
}

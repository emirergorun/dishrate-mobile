import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/auth/token_storage.dart';
import '../../../core/network/restaurant_repository.dart';
import '../../../core/network/wishlist_repository.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/models/menu_item_model.dart';
import '../../../shared/models/restaurant_model.dart';
import '../../rating/providers/rating_flow_provider.dart';
import '../../../shared/widgets/rating_sheet.dart';
import '../../restaurant/screens/restaurant_detail_screen.dart';
import '../../reviews/screens/menu_item_reviews_screen.dart';
import '../widgets/category_chips.dart';
import '../widgets/menu_item_card.dart';
import '../widgets/section_header.dart';
import '../providers/location_provider.dart';
import '../../../core/data/turkiye_adres.dart';
import '../../../shared/widgets/searchable_picker.dart';
import '../../../core/location/location_service.dart';
import 'see_all_screen.dart';

/// Başlıktaki "dishrate" kelime markasının punto'su. Harf aralığı buna
/// oranla (−%2) hesaplanır, böylece punto değişse de logoyla oran korunur.
///
/// 28'den 24'e indirildi: sağdaki konum yazısıyla arada nefes kalmıyordu.
const double _wordmarkSize = 24;

class DiscoverScreen extends ConsumerStatefulWidget {
  const DiscoverScreen({super.key});

  @override
  ConsumerState<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends ConsumerState<DiscoverScreen> {
  String? _selectedCategory; // null veya 'Tümü' → hepsi gösterilir

  List<MenuItemModel> _allItems = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await RestaurantRepository.instance.getAllMenuItems();
      if (mounted) {
        setState(() {
          _allItems = items;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'İçerikler yüklenemedi.';
          _loading = false;
        });
      }
    }
  }

  static const List<String> _categories = [
    'Tümü',
    'Burger',
    'Pizza',
    'Kebap',
    'Sushi',
    'Tatlı',
    'Kahvaltı',
    'İtalyan',
    'Vegan',
    'Meze',
    'Sandviç',
    'Noodle',
  ];

  // ── Bölüm üretimi ─────────────────────────────────────────────────────────
  // Backend henüz "trend / en çok istek listesinde / bu hafta" gibi sorguları
  // sunmadığından bölümler, mevcut alanlardan (puan, fiyat, kategori) istemci
  // tarafında türetilir. Backend feed endpoint'leri gelince burası sadeleşecek.

  static const Set<String> _indulgentCats = {
    'Burger', 'Pizza', 'Tatlı', 'Kebap', 'İtalyan', 'Noodle', 'Sandviç',
  };
  static const Set<String> _healthyCats = {
    'Vegan', 'Salata', 'Kahvaltı', 'Meze',
  };

  List<MenuItemModel> _filtered(List<MenuItemModel> src) {
    if (_selectedCategory == null || _selectedCategory == 'Tümü') return src;
    return src
        .where((item) => item.categoryName == _selectedCategory)
        .toList();
  }

  /// Seçili kategoriye göre filtrelenmiş tüm öğeler — bölümlerin kaynağı.
  List<MenuItemModel> get _baseItems => _filtered(_allItems);

  /// Seçili konum. İlçe seçiliyse önce o ilçe denenir; orada hiç sonuç
  /// yoksa il geneline düşülür — kullanıcı boş ekranla karşılaşmasın.
  List<MenuItemModel> get _localItems {
    final loc = ref.watch(selectedLocationProvider);
    final ilGeneli = _baseItems
        .where((i) => i.city == null || _esit(i.city!, loc.il))
        .toList();
    if (!loc.hasIlce) return ilGeneli;
    final ilceIcinde = ilGeneli
        .where((i) => i.district != null && _esit(i.district!, loc.ilce!))
        .toList();
    return ilceIcinde.isEmpty ? ilGeneli : ilceIcinde;
  }

  static bool _esit(String a, String b) =>
      TurkiyeAdres.aramaAnahtari(a.trim()) ==
      TurkiyeAdres.aramaAnahtari(b.trim());

  List<MenuItemModel> _byRatingDesc(Iterable<MenuItemModel> src) {
    final l = src.toList()
      ..sort((a, b) => b.averageRating.compareTo(a.averageRating));
    return l.take(12).toList();
  }

  List<MenuItemModel> get _topRated => _byRatingDesc(_localItems);

  // "Bu hafta" için yaklaşık: en yeni eklenen (yüksek ID) yüksek puanlılar.
  List<MenuItemModel> get _weeklyTop {
    final l = _baseItems.where((i) => i.averageRating >= 4.5).toList()
      ..sort((a, b) => b.menuItemId.compareTo(a.menuItemId));
    return l.take(12).toList();
  }

  // "Herkes denemek istiyor": en sevilenler (en yüksek puanlıların ardından gelenler).
  List<MenuItemModel> get _mostWanted {
    final l = _baseItems.toList()
      ..sort((a, b) => b.averageRating.compareTo(a.averageRating));
    return l.skip(3).take(12).toList();
  }

  List<MenuItemModel> get _cheatMeal => _byRatingDesc(
      _baseItems.where((i) => _indulgentCats.contains(i.categoryName)));

  List<MenuItemModel> get _healthy => _byRatingDesc(
      _baseItems.where((i) => _healthyCats.contains(i.categoryName)));

  // "Gizli mücevherler": az bilinen kategorilerde yüksek puanlılar.
  static const Set<String> _nicheCats = {'Meze', 'Noodle', 'Vegan', 'Tavuk'};
  List<MenuItemModel> get _hidden => _byRatingDesc(
      _baseItems.where((i) => _nicheCats.contains(i.categoryName)));

  void _seeAll(String title, List<MenuItemModel> items) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            SeeAllScreen(title: title, items: items, onItemTap: _showItemSheet),
      ),
    );
  }

  Future<void> _showItemSheet(MenuItemModel item) async {
    final shouldRate = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _MenuItemSheet(item: item),
    );
    if (shouldRate == true && mounted) {
      final restaurant = RestaurantModel(
        restaurantId: item.restaurantId,
        name: item.restaurantName,
        city: item.city ?? 'İstanbul',
        district: item.district,
        fullAddress:
            '${item.restaurantName}, ${item.district ?? item.city ?? "İstanbul"}',
        latitude: item.restaurantLatitude,
        longitude: item.restaurantLongitude,
        categoryName: item.categoryName,
      );
      ref.read(ratingFlowProvider.notifier).jumpToRateItem(restaurant, item);
      if (!mounted) return;
      await RatingSheet.show(context);
    }
  }

  /// Görünür bölümler — boş olanlar otomatik elenir.
  List<({String title, String subtitle, List<MenuItemModel> items})>
      get _sections => [
            (
              title: '${ref.watch(selectedLocationProvider).hasIlce ? ref.watch(selectedLocationProvider).ilce : ref.watch(selectedLocationProvider).il}\'da En İyiler',
              subtitle: 'Konumuna yakın, yüksek puanlı lezzetler',
              items: _topRated,
            ),
            (
              title: 'Bu Haftanın Favorileri',
              subtitle: 'Yeni eklenen, en çok beğenilen menü öğeleri',
              items: _weeklyTop,
            ),
            (
              title: 'Herkes Denemek İstiyor',
              subtitle: 'Merak uyandıran özel lezzetler',
              items: _mostWanted,
            ),
            (
              title: 'Diyeti Bozmaya Değer',
              subtitle: 'Pişman olmayacağın kalorili şaheserler',
              items: _cheatMeal,
            ),
            (
              title: 'Sağlıklı & Fit Seçenekler',
              subtitle: 'Hem lezzetli hem de hafif alternatifler',
              items: _healthy,
            ),
            (
              title: 'Şehrin Gizli Mücevherleri',
              subtitle: 'Az bilinen ama çok sevilecek lezzetler',
              items: _hidden,
            ),
          ].where((s) => s.items.isNotEmpty).toList();

  @override
  Widget build(BuildContext context) {
    final sections = _loading || _error != null ? const [] : _sections;

    return Scaffold(
      backgroundColor: context.bgColor,
      body: RefreshIndicator(
        onRefresh: _load,
        color: AppColors.primary,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [
            // ── App Bar ──────────────────────────────────────────────────
            _DiscoverAppBar(),

            // ── Kategori Chip'leri ───────────────────────────────────────
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  CategoryChips(
                    categories: _categories,
                    onSelected: (category) {
                      setState(() => _selectedCategory = category);
                    },
                  ),
                ],
              ),
            ),

            // ── Yükleniyor ───────────────────────────────────────────────
            if (_loading)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              )

            // ── Hata ─────────────────────────────────────────────────────
            else if (_error != null)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.cloud_off_rounded,
                          color: AppColors.textDisabled, size: 48),
                      const SizedBox(height: 12),
                      Text(_error!,
                          style: AppTextStyles.titleMedium
                              .copyWith(color: AppColors.textSecondary)),
                      const SizedBox(height: 16),
                      OutlinedButton(
                        onPressed: _load,
                        child: const Text('Tekrar Dene'),
                      ),
                    ],
                  ),
                ),
              )

            // ── Boş ──────────────────────────────────────────────────────
            else if (sections.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.ramen_dining_rounded,
                          color: AppColors.textDisabled, size: 48),
                      const SizedBox(height: 12),
                      Text(
                        _selectedCategory == null ||
                                _selectedCategory == 'Tümü'
                            ? 'Henüz içerik yok'
                            : 'Bu kategoride içerik yok',
                        style: AppTextStyles.titleMedium
                            .copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              )

            // ── Bölümler ─────────────────────────────────────────────────
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final s = sections[index];
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SectionHeader(
                          title: s.title,
                          subtitle: s.subtitle,
                          onSeeAll: () => _seeAll(s.title, s.items),
                        ),
                        _HorizontalCardList(
                          onItemTap: _showItemSheet,
                          items: s.items,
                        ),
                      ],
                    );
                  },
                  childCount: sections.length,
                ),
              ),

            // ── Alt boşluk (bottom nav ile çakışmasın) ──────────────────
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }
}

// ── App Bar ───────────────────────────────────────────────────────────────────

/// İl listesinin başına sabitlenen GPS satırının etiketi.
const String _konumuKullan = 'Konumumu kullan';

class _DiscoverAppBar extends ConsumerWidget {
  /// Konuma dokunulduğunda: izin hiç sorulmadıysa önce kısa bir açıklama
  /// gösterip sistem penceresini açar (tek şansı burada, faydası belliyken
  /// harcıyoruz). Diğer her durumda seçim listesi açılır.
  ///
  /// İzin verilmiş olsa bile buradan GPS'i yeniden çalıştırmıyoruz: kullanıcı
  /// konuma dokunduysa muhtemelen **başka bir yere** bakmak istiyor. Eskiden
  /// izin varken dokunmak doğrudan GPS'i tetikleyip geri dönüyordu, bu yüzden
  /// elle ilçe seçmek imkânsızdı. GPS artık listenin başındaki "Konumumu
  /// kullan" satırından çalışıyor.
  Future<void> _onLocationTap(BuildContext context, WidgetRef ref) async {
    final notifier = ref.read(selectedLocationProvider.notifier);

    final izinVar = await LocationService.hasPermission();
    if (!izinVar && await LocationService.canAsk()) {
      if (!context.mounted) return;
      final izinIster = await _askUseLocation(context);
      if (!context.mounted) return;
      if (izinIster == true) {
        final r = await notifier.requestGps();
        if (!context.mounted) return;
        if (r.isOk) return;
        if (r.outcome == LocationOutcome.serviceDisabled) {
          _snack(context, 'Cihazının konum servisi kapalı. '
              'Açıp tekrar dene ya da şehri kendin seç.');
        }
      }
    }

    if (!context.mounted) return;
    await _pickLocation(context, ref);
  }

  /// Sistem penceresinden ÖNCE gösterilen açıklama. iOS penceresi ömür boyu
  /// bir kez açılabildiği için, kullanıcı neye evet dediğini bilerek gelsin.
  Future<bool?> _askUseLocation(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ctx.surfaceColor,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18)),
        title: Text('Konumunu kullanalım mı?',
            style: AppTextStyles.titleMedium),
        content: Text(
          'Sana en yakın restoranları gösterebilmemiz için konumuna '
          'ihtiyacımız var.',
          style: AppTextStyles.bodyMedium
              .copyWith(color: ctx.textSecondaryColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Şimdi değil'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary),
            child: const Text('Konumumu kullan'),
          ),
        ],
      ),
    );
  }

  void _snack(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  /// İl → (opsiyonel) ilçe seçimi. İl değişirse ilçe sıfırlanır.
  Future<void> _pickLocation(BuildContext context, WidgetRef ref) async {
    final iller = await TurkiyeAdres.iller();
    final izinVar = await LocationService.hasPermission();
    if (!context.mounted) return;
    final mevcut = ref.read(selectedLocationProvider);

    final secilenIl = await SearchablePicker.show(
      context,
      title: 'İl Seç',
      options: iller.map((i) => i.ad).toList(),
      // Elle seçim yaptıktan sonra cihaz konumuna dönebilmenin tek yolu.
      pinned: izinVar
          ? const [
              SabitSecenek(_konumuKullan, icon: Icons.my_location_rounded),
            ]
          : const [],
      selected: mevcut.il,
      searchHint: 'İl ara…',
    );
    if (secilenIl == null || !context.mounted) return;

    if (secilenIl == _konumuKullan) {
      final r = await ref.read(selectedLocationProvider.notifier).requestGps();
      if (!context.mounted || r.isOk) return;
      _snack(context, 'Konum alınamadı. Şehri listeden seçebilirsin.');
      return;
    }

    final il = iller.firstWhere((i) => i.ad == secilenIl);
    final tumu = 'Tüm $secilenIl';
    final secilenIlce = await SearchablePicker.show(
      context,
      title: '$secilenIl · İlçe Seç',
      options: il.ilceler.map((i) => i.ad).toList(),
      // İl geneline dönme seçeneği alfabetik sıraya karışmasın diye sabit.
      pinned: [SabitSecenek(tumu, icon: Icons.select_all_rounded)],
      selected: secilenIl == mevcut.il ? (mevcut.ilce ?? tumu) : null,
      searchHint: 'İlçe ara…',
    );
    if (secilenIlce == null) {
      // İlçe adımı iptal edilse bile il seçimi geçerli olsun.
      await ref.read(selectedLocationProvider.notifier).setManual(secilenIl);
      return;
    }
    await ref.read(selectedLocationProvider.notifier).setManual(
          secilenIl,
          ilce: secilenIlce == tumu ? null : secilenIlce,
        );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SliverAppBar(
      pinned: true,
      floating: false,
      backgroundColor: context.bgColor,
      expandedHeight: 100,
      collapsedHeight: 60,
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.pin,
        background: Builder(
          builder: (ctx) => Container(color: ctx.bgColor),
        ),
        titlePadding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
        title: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Logo kelime markası — ayarlar logonun kendisinden alınmıştır
            // ("Dishrate logo/OKUBENI.md": Poppins SemiBold 600, harf aralığı
            // −%2, hep küçük harf). Buradaki yazı logoyla yan yana geldiğinde
            // (açılış ekranı, giriş ekranı) aynı görünsün diye birebir aynı
            // olmalı; displayLarge'ın 900'ü ve −1 aralığı bu yüzden eziliyor.
            Text(
              'dishrate',
              style: AppTextStyles.displayLarge.copyWith(
                fontSize: _wordmarkSize,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
                letterSpacing: _wordmarkSize * -0.02,
              ),
            ),
            const Spacer(),
            // Konum — dokunulunca il/ilçe seçilir; GPS seçeneği de o listenin
            // başında duruyor.
            GestureDetector(
              onTap: () => _onLocationTap(context, ref),
              behavior: HitTestBehavior.opaque,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Icon(
                    Icons.location_on_rounded,
                    color: AppColors.textSecondary,
                    size: 14,
                  ),
                  const SizedBox(width: 3),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 170),
                    child: Text(
                      ref.watch(selectedLocationProvider).isUnset
                          ? 'Konum Seç'
                          : ref.watch(selectedLocationProvider).etiket,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      // Kelime markasının yanında duruyor; aynı ağırlıkta
                      // olunca ikisi tek blok gibi görünüyordu.
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                  ),
                  // Konum GPS'ten geliyorsa seçim yapmaya gerek yok — ok
                  // işareti "burada seçilecek bir şey var" diye çağırmasın.
                  if (ref.watch(selectedLocationProvider).source !=
                      LocationSource.gps) ...[
                    const SizedBox(width: 2),
                    const Icon(
                      Icons.expand_more_rounded,
                      color: AppColors.textSecondary,
                      size: 14,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(0.5),
        child: Builder(
          builder: (ctx) => Container(height: 0.5, color: ctx.dividerColor),
        ),
      ),
    );
  }
}

// ── Yatay kaydırmalı kart listesi ─────────────────────────────────────────────

class _HorizontalCardList extends StatelessWidget {
  const _HorizontalCardList({
    required this.items,
    required this.onItemTap,
  });
  final List<MenuItemModel> items;
  final void Function(MenuItemModel) onItemTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 230,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: items.length,
        itemBuilder: (context, index) => MenuItemCard(
          item: items[index],
          onTap: () => onItemTap(items[index]),
        ),
      ),
    );
  }
}

// ── Yemek öğesi detay sheet'i ─────────────────────────────────────────────────

class _MenuItemSheet extends ConsumerStatefulWidget {
  const _MenuItemSheet({required this.item});
  final MenuItemModel item;

  @override
  ConsumerState<_MenuItemSheet> createState() => _MenuItemSheetState();
}

class _MenuItemSheetState extends ConsumerState<_MenuItemSheet> {
  bool _inWishlist = false;
  bool _wishlistLoading = true;

  @override
  void initState() {
    super.initState();
    _checkWishlist();
  }

  Future<void> _checkWishlist() async {
    try {
      final userId = await TokenStorage.instance.getUserId();
      if (userId == null) {
        if (mounted) setState(() => _wishlistLoading = false);
        return;
      }
      final list = await WishlistRepository.instance.getWishlist(userId);
      if (!mounted) return;
      setState(() {
        _inWishlist =
            list.any((w) => w.menuItemId == widget.item.menuItemId);
        _wishlistLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _wishlistLoading = false);
    }
  }

  Future<void> _toggleWishlist() async {
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
      } else {
        await WishlistRepository.instance
            .addToWishlist(userId, widget.item.menuItemId);
      }
      if (!mounted) return;
      setState(() {
        _inWishlist = !_inWishlist;
        _wishlistLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _wishlistLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: BoxDecoration(
        color: context.surfaceElevatedColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Handle ───────────────────────────────────────────────────
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
          const SizedBox(height: 16),

          // ── Fotoğraf ─────────────────────────────────────────────────
          if (item.photoUrl != null && item.photoUrl!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  item.photoUrl!,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 180,
                    decoration: BoxDecoration(
                      color: context.surfaceColor,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.restaurant_rounded,
                        color: AppColors.textDisabled, size: 48),
                  ),
                ),
              ),
            ),

          const SizedBox(height: 14),

          // ── Bilgiler ─────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // İsim + puan
                Row(
                  children: [
                    Expanded(
                      child: Text(item.name,
                          style: AppTextStyles.titleLarge),
                    ),
                    if (item.averageRating > 0) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color:
                              AppColors.star.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star_rounded,
                                color: AppColors.star, size: 14),
                            const SizedBox(width: 3),
                            Text(
                              item.averageRating.toStringAsFixed(1),
                              style: AppTextStyles.ratingSmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 6),
                // Restoran + konum (restorana tıkla → detay)
                GestureDetector(
                  onTap: () {
                    final loc = [item.district, item.city]
                        .where((e) => e != null && e.isNotEmpty)
                        .join(', ');
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => RestaurantDetailScreen(
                          restaurantId: item.restaurantId,
                          restaurantName: item.restaurantName,
                          locationText: loc,
                        ),
                      ),
                    );
                  },
                  child: Row(
                    children: [
                      const Icon(Icons.storefront_rounded,
                          color: AppColors.primary, size: 14),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          item.restaurantName,
                          style: AppTextStyles.bodySmall
                              .copyWith(color: AppColors.primary),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded,
                          color: AppColors.primary, size: 16),
                      if (item.district != null) ...[
                        const SizedBox(width: 4),
                        const Icon(Icons.location_on_rounded,
                            color: AppColors.textSecondary, size: 12),
                        const SizedBox(width: 2),
                        Text(item.district!,
                            style: AppTextStyles.bodySmall),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ── Yorumları gör ────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MenuItemReviewsScreen(
                      menuItemId: item.menuItemId,
                      menuItemName: item.name,
                    ),
                  ),
                ),
                icon: const Icon(Icons.reviews_outlined, size: 18),
                label: const Text('Yorumları Gör'),
              ),
            ),
          ),

          // ── Butonlar ─────────────────────────────────────────────────
          Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, bottomPad + 16),
            child: Row(
              children: [
                // İstek listesi
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed:
                        _wishlistLoading ? null : _toggleWishlist,
                    icon: _wishlistLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.primary,
                            ),
                          )
                        : Icon(
                            _inWishlist
                                ? Icons.bookmark_rounded
                                : Icons.bookmark_border_rounded,
                            size: 18,
                          ),
                    label: Text(
                      _inWishlist
                          ? 'Listeden Çıkar'
                          : 'İstek Listesi\'ne Ekle',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Değerlendir
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context, true),
                    icon: const Icon(Icons.star_rounded, size: 18),
                    label: const Text('Değerlendir',
                        style: TextStyle(fontSize: 13)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


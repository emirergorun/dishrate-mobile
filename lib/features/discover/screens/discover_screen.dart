import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import '../../../core/network/restaurant_repository.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../core/theme/app_metrics.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/models/menu_item_model.dart';
import '../../../shared/widgets/dish_sheet.dart';
import '../../../shared/widgets/pressable.dart';
import '../../../shared/widgets/skeleton.dart';
import '../../../shared/widgets/state_message.dart';
import '../widgets/category_chips.dart';
import '../widgets/dish_layouts.dart';
import '../widgets/section_header.dart';
import '../providers/location_provider.dart';
import '../../../core/data/turkiye_adres.dart';
import '../../../shared/widgets/searchable_picker.dart';
import '../../../core/location/location_service.dart';
import 'see_all_screen.dart';

/// Başlıktaki "dishrate" kelime markasının punto'su. Harf aralığı buna
/// oranla (−%2) hesaplanır, böylece punto değişse de logoyla oran korunur.
///
/// Başlık artık genişleyip daralmıyor: genişken yazı 1.5 kat büyüyüp konum
/// yazısını da büyütüyor, kaydırınca ikisi birden zıplıyordu.
const double _wordmarkSize = 24;

/// Bölümün düzeni — bkz. `dish_layouts.dart`. Yan yana iki bölüm aynı
/// düzeni kullanmıyor.
enum _Layout { ranked, posters, wide, grid, list }

typedef _Section = ({
  String title,
  String subtitle,
  List<MenuItemModel> items,
  _Layout layout,
});

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
          _error = 'İçerikler yüklenemedi';
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

  bool get _allSelected =>
      _selectedCategory == null || _selectedCategory == 'Tümü';

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
    if (_allSelected) return src;
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
            SeeAllScreen(title: title, items: items, onItemTap: _openDish),
      ),
    );
  }

  Future<void> _openDish(MenuItemModel item) =>
      DishSheet.open(context, ref, item);

  /// Görünür bölümler — boş olanlar otomatik elenir.
  ///
  /// Başlıklar cümle düzeninde: Her Kelimesi Büyük Başlık altı bölümde üst
  /// üste gelince ekran bir menü tabelası gibi okunuyordu.
  List<_Section> get _sections {
    final loc = ref.watch(selectedLocationProvider);
    final yer = loc.hasIlce ? loc.ilce! : loc.il;
    final List<_Section> all = [
      (
        title: '${_bulunmaEki(yer)} en iyiler',
        subtitle: 'Konumuna yakın, yüksek puanlı lezzetler',
        items: _topRated,
        layout: _Layout.ranked,
      ),
      (
        title: 'Bu haftanın favorileri',
        subtitle: 'Yeni eklenen, en çok beğenilen menü öğeleri',
        items: _weeklyTop,
        layout: _Layout.posters,
      ),
      (
        title: 'Herkes denemek istiyor',
        subtitle: 'Merak uyandıran özel lezzetler',
        items: _mostWanted,
        layout: _Layout.wide,
      ),
      (
        title: 'Diyeti bozmaya değer',
        subtitle: 'Pişman olmayacağın kalorili şaheserler',
        items: _cheatMeal,
        layout: _Layout.grid,
      ),
      (
        title: 'Sağlıklı & fit seçenekler',
        subtitle: 'Hem lezzetli hem de hafif alternatifler',
        items: _healthy,
        layout: _Layout.posters,
      ),
      (
        title: 'Şehrin gizli mücevherleri',
        subtitle: 'Az bilinen ama çok sevilecek lezzetler',
        items: _hidden,
        layout: _Layout.list,
      ),
    ];
    return all.where((s) => s.items.isNotEmpty).toList();
  }

  /// "Kadıköy" → "Kadıköy'de", "Beşiktaş" → "Beşiktaş'ta". Önceden her yere
  /// "'da" ekleniyordu ("Kadıköy'da", "Beşiktaş'da").
  static String _bulunmaEki(String yer) {
    const kalin = 'aıouAIOU';
    const ince = 'eiöüEİÖÜ';
    var unlu = 'a';
    for (var i = yer.length - 1; i >= 0; i--) {
      if (kalin.contains(yer[i])) break;
      if (ince.contains(yer[i])) {
        unlu = 'e';
        break;
      }
    }
    final son = yer.isEmpty ? '' : yer[yer.length - 1];
    final sert = 'çfhkpsştÇFHKPSŞT'.contains(son);
    return "$yer'${sert ? 't' : 'd'}$unlu";
  }

  Widget _sectionBody(_Section s) {
    switch (s.layout) {
      case _Layout.ranked:
        return DishRankedList(
          items: s.items.take(5).toList(),
          onTap: _openDish,
          withLead: true,
        );
      case _Layout.list:
        return DishRankedList(items: s.items.take(5).toList(), onTap: _openDish);
      case _Layout.posters:
        return DishPosterCarousel(items: s.items, onTap: _openDish);
      case _Layout.wide:
        return DishWideCarousel(items: s.items, onTap: _openDish);
      case _Layout.grid:
        return DishTileGrid(items: s.items, onTap: _openDish);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sections =
        _loading || _error != null ? const <_Section>[] : _sections;

    return Scaffold(
      backgroundColor: context.bgColor,
      body: RefreshIndicator(
        onRefresh: _load,
        color: AppColors.primary,
        backgroundColor: context.surfaceColor,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [
            // ── App Bar ──────────────────────────────────────────────────
            const _DiscoverAppBar(),

            // ── Kategori Chip'leri ───────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: AppSpace.xs),
                child: CategoryChips(
                  categories: _categories,
                  onSelected: (category) {
                    setState(() => _selectedCategory = category);
                  },
                ),
              ),
            ),

            // ── Yükleniyor ───────────────────────────────────────────────
            if (_loading)
              const SliverToBoxAdapter(child: _DiscoverSkeleton())

            // ── Hata ─────────────────────────────────────────────────────
            else if (_error != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                      AppSpace.screen, 48, AppSpace.screen, 0),
                  child: StateMessage(
                    title: _error!,
                    message: 'Bağlantını kontrol edip tekrar dene.',
                    actionLabel: 'Tekrar dene',
                    onAction: _load,
                  ),
                ),
              )

            // ── Boş ──────────────────────────────────────────────────────
            else if (sections.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                      AppSpace.screen, 48, AppSpace.screen, 0),
                  child: StateMessage(
                    title: _allSelected
                        ? 'Henüz içerik yok'
                        : 'Bu kategoride içerik yok',
                    message: _allSelected
                        ? 'Restoranlar menülerini ekledikçe yemekler burada görünecek.'
                        : 'Başka bir kategori seç ya da Tümü\'ne dön.',
                  ),
                ),
              )

            // ── Bölümler ─────────────────────────────────────────────────
            else
              SliverList.builder(
                itemCount: sections.length,
                itemBuilder: (context, index) {
                  final s = sections[index];
                  return Padding(
                    padding: EdgeInsets.only(
                      top: index == 0 ? AppSpace.xl : AppSpace.section,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SectionHeader(
                          title: s.title,
                          subtitle: s.subtitle,
                          onSeeAll: () => _seeAll(s.title, s.items),
                        ),
                        _sectionBody(s),
                      ],
                    ),
                  );
                },
              ),

            // ── Alt boşluk (bottom nav ile çakışmasın) ──────────────────
            const SliverToBoxAdapter(child: SizedBox(height: AppSpace.xxl)),
          ],
        ),
      ),
    );
  }
}

// ── Yükleme iskeleti ──────────────────────────────────────────────────────────

/// İlk bölümün (öne çıkan + sıralı satırlar) şeklinde iskelet.
class _DiscoverSkeleton extends StatelessWidget {
  const _DiscoverSkeleton();

  @override
  Widget build(BuildContext context) {
    Widget row() => const Padding(
          padding: EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              SizedBox(width: 28),
              SkeletonBox(width: 56, height: 56, radius: AppRadius.sm),
              SizedBox(width: AppSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonBox(width: 160, height: 14),
                    SizedBox(height: 6),
                    SkeletonBox(width: 110, height: 12),
                  ],
                ),
              ),
            ],
          ),
        );

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpace.screen, AppSpace.xl, AppSpace.screen, 0),
      child: SkeletonPulse(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SkeletonBox(width: 180, height: 20),
            const SizedBox(height: 6),
            const SkeletonBox(width: 240, height: 12),
            const SizedBox(height: AppSpace.lg),
            const AspectRatio(
              aspectRatio: 16 / 10,
              child: SkeletonBox(height: double.infinity, radius: AppRadius.md),
            ),
            const SizedBox(height: AppSpace.md),
            row(),
            row(),
            row(),
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
  const _DiscoverAppBar();

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
        title: const Text('Konumunu kullanalım mı?'),
        content: const Text(
          'Sana en yakın restoranları gösterebilmemiz için konumuna '
          'ihtiyacımız var.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            style: TextButton.styleFrom(
                foregroundColor: ctx.textSecondaryColor),
            child: const Text('Şimdi değil'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
            child: const Text('Konumumu kullan'),
          ),
        ],
      ),
    );
  }

  void _snack(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
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
    final loc = ref.watch(selectedLocationProvider);

    return SliverAppBar(
      pinned: true,
      backgroundColor: context.bgColor,
      surfaceTintColor: Colors.transparent,
      toolbarHeight: 60,
      titleSpacing: AppSpace.screen,
      automaticallyImplyLeading: false,
      title: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Logo kelime markası — ayarlar logonun kendisinden alınmıştır
          // ("Dishrate logo/OKUBENI.md": Poppins SemiBold 600, harf aralığı
          // −%2, hep küçük harf). Arayüz fontu Geist olsa da bu yazı logoyla
          // yan yana geldiğinde (açılış, giriş ekranı) aynı görünmeli.
          const Text(
            'dishrate',
            style: TextStyle(
              fontFamily: AppFonts.wordmark,
              fontSize: _wordmarkSize,
              fontWeight: FontWeight.w600,
              height: 1,
              color: AppColors.primary,
              letterSpacing: _wordmarkSize * -0.02,
            ),
          ),
          const Spacer(),
          // Konum — dokunulunca il/ilçe seçilir; GPS seçeneği de o listenin
          // başında duruyor. Keşfet'in tüm içeriği bu seçime bağlı, bu yüzden
          // soluk gri değil metin renginde duruyor.
          Pressable(
            onTap: () => _onLocationTap(context, ref),
            semanticLabel: 'Konum: ${loc.isUnset ? 'seçilmedi' : loc.etiket}',
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    loc.source == LocationSource.gps
                        ? TablerIcons.navigation_filled
                        : TablerIcons.map_pin,
                    color: context.textSecondaryColor,
                    size: 16,
                  ),
                  const SizedBox(width: 5),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 170),
                    child: Text(
                      loc.isUnset ? 'Konum seç' : loc.etiket,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.label.copyWith(
                        fontSize: 14,
                        color: context.textPrimaryColor,
                      ),
                    ),
                  ),
                  // Konum GPS'ten geliyorsa seçim yapmaya gerek yok — ok
                  // işareti "burada seçilecek bir şey var" diye çağırmasın.
                  if (loc.source != LocationSource.gps) ...[
                    const SizedBox(width: 3),
                    Icon(
                      TablerIcons.chevron_down,
                      color: context.textSecondaryColor,
                      size: 13,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import '../../../core/network/restaurant_repository.dart';
import '../../../core/theme/app_colors.dart';
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

/// Başlıktaki "dishrate" kelime markasının punto'su.
///
/// Başlık artık genişleyip daralmıyor: genişken yazı 1.5 kat büyüyüp konum
/// yazısını da büyütüyor, kaydırınca ikisi birden zıplıyordu.
const double _wordmarkSize = 24;

/// Bölümün düzeni — bkz. `dish_layouts.dart`. Yan yana iki bölüm aynı
/// düzeni kullanmıyor.
enum _Layout { ranked, posters, wide, grid, list }

typedef _Section = ({
  String key,
  String title,
  String? subtitle,
  List<MenuItemModel> items,
  bool hasMore,
  _Layout layout,
});

/// Sıralı liste düzenlerinde ekranda gösterilen satır sayısı.
const int _listRows = 5;

class DiscoverScreen extends ConsumerStatefulWidget {
  const DiscoverScreen({super.key});

  @override
  ConsumerState<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends ConsumerState<DiscoverScreen> {
  String? _selectedCategory; // null veya 'Tümü' → hepsi gösterilir

  List<FeedSection> _feed = [];
  bool _loading = true;
  String? _error;

  /// Son isteğin sırası: konum ya da çip hızlı değişince eski yanıt yenisinin
  /// üzerine yazılmasın.
  int _request = 0;

  @override
  void initState() {
    super.initState();
    // Akış konuma bağlı: il ya da ilçe değişince yeniden istenir.
    ref.listenManual(selectedLocationProvider, (prev, next) {
      if (prev?.il != next.il || prev?.ilce != next.ilce) _load();
    });
    _load();
  }

  Future<void> _load() async {
    final loc = ref.read(selectedLocationProvider);
    final request = ++_request;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final feed = await RestaurantRepository.instance.getFeed(
        city: _city(loc),
        district: _district(loc),
        category: _category,
      );
      if (mounted && request == _request) {
        setState(() {
          _feed = feed;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted && request == _request) {
        setState(() {
          _error = 'İçerikler yüklenemedi';
          _loading = false;
        });
      }
    }
  }

  static String? _city(SelectedLocation loc) =>
      loc.il.trim().isEmpty ? null : loc.il;
  static String? _district(SelectedLocation loc) =>
      loc.hasIlce ? loc.ilce : null;
  String? get _category => _allSelected ? null : _selectedCategory;

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

  // ── Bölümler ──────────────────────────────────────────────────────────────
  // Bölümlerin içeriği (hangi kategori, hangi sıralama, ilçe → il geneline
  // düşme) sunucuda `FeedService`'te. Burada yalnızca anahtar → başlık ve
  // düzen eşlemesi var.

  void _seeAll(_Section s) {
    final loc = ref.read(selectedLocationProvider);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SeeAllScreen(
          title: s.title,
          items: s.items,
          sectionKey: s.key,
          city: _city(loc),
          district: _district(loc),
          category: _category,
          onItemTap: _openDish,
        ),
      ),
    );
  }

  Future<void> _openDish(MenuItemModel item) =>
      DishSheet.open(context, ref, item);

  /// Görünür bölümler — boş olanlar otomatik elenir.
  ///
  /// Başlıklar cümle düzeninde: Her Kelimesi Büyük Başlık altı bölümde üst
  /// üste gelince ekran bir menü tabelası gibi okunuyordu.
  ///
  /// Alt başlık yalnızca bölümün neye göre dizildiğini söylüyorsa var.
  /// Başlığı başka sözlerle tekrar eden alt başlıklar altı bölümde altı gri
  /// satır ediyordu; ekran fotoğraflardan önce metin olarak okunuyordu.
  List<_Section> get _sections {
    final loc = ref.watch(selectedLocationProvider);
    final yer = loc.hasIlce ? loc.ilce! : loc.il;
    final Map<String, ({String title, String? subtitle, _Layout layout})>
        meta = {
      'top-rated': (
        title: '${_bulunmaEki(yer)} en iyiler',
        subtitle: 'Konumuna yakın, yüksek puanlı lezzetler',
        layout: _Layout.ranked,
      ),
      'weekly': (
        title: 'Haftanın Yıldızları',
        subtitle: 'Bu hafta en çok beğenilen menü öğeleri',
        layout: _Layout.posters,
      ),
      'most-wanted': (
        title: 'Herkes Denemek İstiyor',
        subtitle: null,
        layout: _Layout.wide,
      ),
      'cheat-meal': (
        title: 'Cheat Meal Önerileri',
        subtitle: null,
        layout: _Layout.grid,
      ),
      'healthy': (
        title: 'Diyet Dostu',
        subtitle: null,
        layout: _Layout.posters,
      ),
      'hidden-gems': (
        title: 'Şehrin Gizli Cevherleri',
        subtitle: null,
        layout: _Layout.list,
      ),
    };
    // Sunucunun sırası korunur; tanımadığımız (daha yeni) anahtarlar atlanır.
    return [
      for (final f in _feed)
        if (meta[f.key] != null && f.items.isNotEmpty)
          (
            key: f.key,
            title: meta[f.key]!.title,
            subtitle: meta[f.key]!.subtitle,
            items: f.items,
            hasMore: f.hasMore,
            layout: meta[f.key]!.layout,
          ),
    ];
  }

  /// Sıralı listeler ekranda yalnızca [_listRows] satır gösteriyor; sunucuda
  /// devamı olmasa da gizli kalan satırlar için "Tümünü gör" gerekir.
  static bool _canSeeAll(_Section s) =>
      s.hasMore ||
      ((s.layout == _Layout.ranked || s.layout == _Layout.list) &&
          s.items.length > _listRows);

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
          items: s.items.take(_listRows).toList(),
          onTap: _openDish,
          withLead: true,
        );
      case _Layout.list:
        return DishRankedList(
            items: s.items.take(_listRows).toList(), onTap: _openDish);
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
                // Şeridin dokunma alanı çipten uzun; taşan kısım üst boşluktan
                // düşülüyor ki çip görünüşte yerinden oynamasın.
                padding: const EdgeInsets.only(
                    top: AppSpace.xs - CategoryChips.tapInset),
                child: CategoryChips(
                  categories: _categories,
                  onSelected: (category) {
                    if (category == _selectedCategory) return;
                    setState(() => _selectedCategory = category);
                    _load();
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
                        ? 'Bu bölgede henüz içerik yok'
                        : 'Bu kategoride içerik yok',
                    message: _allSelected
                        ? 'Konumu değiştirerek başka bir şehre göz atabilirsin.'
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
                    // Başlığın dokunma alanı üstüne, çiplerinki altına
                    // taşıyor; ikisi düşülünce görünen boşluk yine xl/section.
                    padding: EdgeInsets.only(
                      top: (index == 0
                              ? AppSpace.xl - CategoryChips.tapInset
                              : AppSpace.section) -
                          SectionHeader.tapInset,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SectionHeader(
                          title: s.title,
                          subtitle: s.subtitle,
                          onSeeAll: _canSeeAll(s) ? () => _seeAll(s) : null,
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
          padding: EdgeInsets.symmetric(vertical: AppSpace.md),
          child: Row(
            children: [
              SizedBox(width: DishRankRow.rankWidth),
              SkeletonBox(
                width: DishRankRow.photoSize,
                height: DishRankRow.photoSize,
                radius: AppRadius.sm,
              ),
              SizedBox(width: AppSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonBox(width: 160, height: 14),
                    SizedBox(height: AppSpace.sm),
                    SkeletonBox(width: 110, height: 12),
                  ],
                ),
              ),
            ],
          ),
        );

    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpace.screen,
          AppSpace.xl - CategoryChips.tapInset, AppSpace.screen, 0),
      child: SkeletonPulse(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SkeletonBox(width: 180, height: 20),
            const SizedBox(height: AppSpace.sm),
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
          _snack(
              context,
              'Konum izni kapalı gözüküyor. '
              'Ayarlardan açarak tekrar deneyebilirsin.');
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
        title: const Text('Yakınındaki restoranları keşfet.'),
        content: const Text(
          'Sana en yakın restoranları gösterebilmemiz için konumuna '
          'ihtiyacımız var.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            style:
                TextButton.styleFrom(foregroundColor: ctx.textSecondaryColor),
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
          // Logo kelime markası — hep küçük harf; ayarı token katmanında.
          Text(
            'dishrate',
            style: AppTextStyles.wordmark(_wordmarkSize)
                .copyWith(color: AppColors.primary),
          ),
          const Spacer(),
          // Konum — dokunulunca il/ilçe seçilir; GPS seçeneği de o listenin
          // başında duruyor. Keşfet'in tüm içeriği bu seçime bağlı, bu yüzden
          // soluk gri değil metin renginde duruyor.
          Pressable(
            onTap: () => _onLocationTap(context, ref),
            semanticLabel: 'Konum: ${loc.isUnset ? 'seçilmedi' : loc.etiket}',
            // Yazı tek satır, görünen yükseklik 34 pt'de kalıyor; dokunma
            // alanı yine de en az 44.
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: AppSize.minTap),
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
                  const SizedBox(width: AppSpace.xs),
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
                    const SizedBox(width: AppSpace.xxs),
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

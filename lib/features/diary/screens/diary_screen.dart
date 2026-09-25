import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/auth/auth_provider.dart';
import '../../../core/network/api_errors.dart';
import '../../../core/network/file_repository.dart';
import '../../../core/network/rating_repository.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_metrics.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/models/rating_model.dart';
import '../../../shared/models/rating_request_model.dart';
import '../../../shared/providers/data_refresh.dart';
import '../../../shared/widgets/dish_photo.dart';
import '../../../shared/widgets/edit_sheet_guard.dart';
import '../../../shared/widgets/info_banner.dart';
import '../../../shared/widgets/min_tap_area.dart';
import '../../../shared/widgets/pressable.dart';
import '../../../core/utils/relative_date.dart';
import '../../../shared/widgets/rating_stars.dart';
import '../../../shared/widgets/skeleton.dart';
import '../../../shared/widgets/state_message.dart';
import '../../../shared/widgets/swipe_to_delete.dart';

// ── Sıralama seçenekleri ──────────────────────────────────────────────────────

enum _SortBy {
  newest('En yeni'),
  oldest('En eski'),
  highest('En yüksek puan'),
  lowest('En düşük puan');

  const _SortBy(this.label);
  final String label;
}

// ── Ekran ─────────────────────────────────────────────────────────────────────

class DiaryScreen extends ConsumerStatefulWidget {
  const DiaryScreen({super.key});

  @override
  ConsumerState<DiaryScreen> createState() => _DiaryScreenState();
}

class _DiaryScreenState extends ConsumerState<DiaryScreen> {
  List<RatingModel> _allRatings = [];
  List<RatingModel> _displayed = [];
  bool _isLoading = true;
  String? _error;

  _SortBy _sortBy = _SortBy.newest;
  String? _categoryFilter; // null = tümü

  final _scrollController = ScrollController();

  /// Yemek panelindeki "Günlüğe git" ile gelindiğinde kısa süre aydınlatılan
  /// değerlendirme. Vurgu bitince null'a döner.
  int? _highlightedId;

  /// Odaklanan kartın konumunu tam hizalamak için (kart yalnızca odaktayken
  /// bu anahtarı taşır).
  final _highlightKey = GlobalKey();

  /// Kart bulunamayınca bir kez tazelenir; sonsuz döngü olmasın.
  bool _refreshedForFocus = false;

  /// Silinip "Geri al" süresi dolmamış değerlendirmeler, eskiden yeniye.
  /// Kayıt `_allRatings`'ten çıkmaz, yalnızca gizlenir; böylece geri alınınca
  /// tam eski yerine döner. Sunucuya istek her birinin kendi süresi dolunca gider.
  final List<_PendingDelete> _pendingDeletes = [];

  /// Silme hatası gibi eylemsiz şerit mesajları (kısa süre görünür).
  final List<_Notice> _notices = [];
  int _noticeSeq = 0;

  /// Listeye geri dönen kayıtlar; kartları bir kez açılarak girer.
  final Set<int> _restoredIds = {};

  static const _undoWindow = Duration(seconds: 5);

  /// Sunucudan silme isteğinin beklendiği süre.
  static const _deleteDeadline = Duration(seconds: 4);

  /// Yaklaşık kart yüksekliği — tembel listede ekran dışındaki kartın context'i
  /// olmadığı için önce buna göre yaklaşılır, sonra tam hizalanır.
  static const double _cardHeight = 132;

  // Yüklenen puanlardan dinamik kategori listesi
  Set<String> get _availableCategories =>
      _visibleRatings.map((r) => r.categoryName).whereType<String>().toSet();

  /// Geri alma süresindekiler hariç değerlendirmeler.
  Iterable<RatingModel> get _visibleRatings {
    final hidden = {for (final p in _pendingDeletes) p.rating.ratingId};
    return _allRatings.where((r) => !hidden.contains(r.ratingId));
  }

  bool get _hasActiveFilter =>
      _categoryFilter != null || _sortBy != _SortBy.newest;

  /// Bekleyen silmelerin uygulama geneli kaydı. `dispose`'da `ref`
  /// kullanılamadığı için baştan tutulur.
  late final PendingRatingDeletes _pendingRegistry;

  @override
  void initState() {
    super.initState();
    _pendingRegistry = ref.read(pendingRatingDeletesProvider.notifier);
    _load();
    // Ekran ilk kez burada oluşuyorsa ref.listen henüz bir değişiklik görmez;
    // bekleyen odak isteği varsa onu da karşıla.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final pending = ref.read(diaryFocusProvider);
      if (pending != null) _focusOn(pending);
    });
  }

  @override
  void dispose() {
    // Ekran kapanıyorsa bekleyen silme artık geri alınamaz; hemen gönderilir.
    for (final pending in _pendingDeletes) {
      pending.timer.cancel();
      RatingRepository.instance.deleteRating(pending.rating.ratingId).ignore();
    }
    // Ağaç kapanırken sağlayıcı değiştirilemez; bir sonraki turda temizlenir.
    final ids = [for (final p in _pendingDeletes) p.rating.ratingId];
    final registry = _pendingRegistry;
    Future.microtask(() => ids.forEach(registry.remove));
    for (final notice in _notices) {
      notice.timer.cancel();
    }
    _scrollController.dispose();
    super.dispose();
  }

  /// Verilen değerlendirmeye kaydırır ve kısa süre aydınlatır.
  Future<void> _focusOn(int ratingId) async {
    if (!mounted) return;

    // Puan başka bir cihazda/ekranda verilmiş olabilir: listede yoksa bir kez tazele.
    if (!_allRatings.any((r) => r.ratingId == ratingId)) {
      if (_refreshedForFocus) return _clearFocus();
      _refreshedForFocus = true;
      await _load(silent: true);
      if (!mounted) return;
      if (!_allRatings.any((r) => r.ratingId == ratingId)) return _clearFocus();
    }
    _refreshedForFocus = false;

    // Kategori filtresi kartı gizliyorsa filtre kalkar; sıralama tercihi kalır.
    if (!_displayed.any((r) => r.ratingId == ratingId)) {
      setState(() {
        _categoryFilter = null;
        _applyFilters();
      });
    }

    final index = _displayed.indexWhere((r) => r.ratingId == ratingId);
    if (index == -1) return _clearFocus();

    setState(() => _highlightedId = ratingId);

    // 1) Yaklaşık konuma atla — hedef kart böylece oluşturulur.
    if (_scrollController.hasClients) {
      final scrollTarget = (index * _cardHeight)
          .clamp(0.0, _scrollController.position.maxScrollExtent);
      _scrollController.jumpTo(scrollTarget);
    }

    // 2) Bir sonraki karede tam hizala.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _highlightKey.currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(
          ctx,
          alignment: 0.25,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });

    // Vurgu söndükten sonra istek tüketilmiş sayılır; aynı yemeğe ikinci kez
    // basılınca yeniden çalışsın diye provider da sıfırlanır.
    await Future<void>.delayed(const Duration(milliseconds: 1600));
    if (!mounted) return;
    setState(() => _highlightedId = null);
    _clearFocus();
  }

  void _clearFocus() {
    if (ref.read(diaryFocusProvider) != null) {
      ref.read(diaryFocusProvider.notifier).state = null;
    }
  }

  /// [silent] açıkken iskelet gösterilmez: başka ekranda puan verilince liste
  /// yerinde kalıp yalnızca tazelensin.
  Future<void> _load({bool silent = false}) async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Oturum bulunamadı';
        });
      }
      return;
    }
    setState(() {
      if (!silent) _isLoading = true;
      _error = null;
    });
    try {
      final ratings = await RatingRepository.instance.getRatingsByUser(userId);
      // Geri alma süresindekiler sunucuda hâlâ duruyor; `_visibleRatings`
      // onları gizlemeye devam eder.
      if (mounted) {
        setState(() {
          _allRatings = ratings;
          _applyFilters();
        });
      }
    } catch (_) {
      if (mounted) setState(() => _error = 'Değerlendirmeler yüklenemedi');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _applyFilters() {
    var list = _visibleRatings.where((r) {
      if (_categoryFilter == null) return true;
      return r.categoryName == _categoryFilter;
    }).toList();

    switch (_sortBy) {
      case _SortBy.newest:
        list.sort((a, b) =>
            (b.ratedAt ?? DateTime(0)).compareTo(a.ratedAt ?? DateTime(0)));
      case _SortBy.oldest:
        list.sort((a, b) =>
            (a.ratedAt ?? DateTime(0)).compareTo(b.ratedAt ?? DateTime(0)));
      case _SortBy.highest:
        list.sort((a, b) => b.score.compareTo(a.score));
      case _SortBy.lowest:
        list.sort((a, b) => a.score.compareTo(b.score));
    }

    _displayed = list;
  }

  /// Kaydırma ve kart menüsündeki "Sil" buraya gelir. Kart hemen gizlenir,
  /// altta "… silindi · Geri al" şeridi çıkar; sunucuya istek şerit
  /// kapanınca gider. Geri alınırsa hiç gitmez, kayıt olduğu gibi kalır.
  /// Art arda silmelerde her birinin kendi şeridi ve süresi var.
  void _deleteRating(RatingModel rating) {
    if (_pendingDeletes.any((p) => p.rating.ratingId == rating.ratingId)) {
      return;
    }
    late final _PendingDelete pending;
    pending = _PendingDelete(
        rating, Timer(_undoWindow, () => _commitDelete(pending)));
    setState(() {
      _pendingDeletes.add(pending);
      _applyFilters();
    });
    _pendingRegistry.add(PendingRatingDelete(
      ratingId: rating.ratingId,
      menuItemId: rating.menuItemId,
      commitNow: () => _commitDelete(pending),
    ));
  }

  void _undoDelete(_PendingDelete pending) {
    pending.timer.cancel();
    _pendingRegistry.remove(pending.rating.ratingId);
    _markRestored(pending.rating.ratingId);
    setState(() {
      _pendingDeletes.remove(pending);
      _applyFilters();
    });
  }

  /// Kart yeniden oluşurken açılma animasyonu oynasın; bir kare sonra iz
  /// silinir ki sonraki yeniden çizimlerde tekrar oynamasın.
  void _markRestored(int ratingId) {
    _restoredIds.add(ratingId);
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _restoredIds.remove(ratingId));
  }

  /// Süre dolunca ya da yemek paneli beklemeden istediğinde (İstek
  /// Listesi'ne ekleme) çalışır. Sunucu sildiyse `true`.
  Future<bool> _commitDelete(_PendingDelete pending) async {
    pending.timer.cancel();
    if (!mounted || !_pendingDeletes.contains(pending)) return true;
    final rating = pending.rating;
    setState(() {
      _pendingDeletes.remove(pending);
      _allRatings.removeWhere((r) => r.ratingId == rating.ratingId);
      _applyFilters();
    });
    try {
      // Bağlantı zaman aşımı (10 sn) beklenmez; o kadar süre kayıt silinmiş
      // görünürdü. Süre dolarsa kart geri gelir, kayıt sunucuda kalır.
      await RatingRepository.instance
          .deleteRating(rating.ratingId)
          .timeout(_deleteDeadline);
      _pendingRegistry.remove(rating.ratingId);
      if (mounted) ref.read(userDataRefreshProvider.notifier).state++;
      return true;
    } catch (_) {
      _pendingRegistry.remove(rating.ratingId);
      if (!mounted) return false;
      // Sunucu silmediyse kart geri gelir.
      _markRestored(rating.ratingId);
      setState(() {
        _allRatings.add(rating);
        _applyFilters();
      });
      _showNotice('Silinemedi, tekrar dene.');
      return false;
    }
  }

  void _showNotice(String message,
      {IconData icon = Icons.error_outline_rounded}) {
    late final _Notice notice;
    notice = _Notice(
        _noticeSeq++,
        message,
        icon,
        Timer(const Duration(seconds: 3), () {
          if (mounted) setState(() => _notices.remove(notice));
        }));
    setState(() => _notices.add(notice));
  }

  List<Widget> _buildBanners() => [
        for (final pending in _pendingDeletes)
          InfoBanner(
            key: ValueKey('deleted_${pending.rating.ratingId}'),
            icon: Icons.delete_outline_rounded,
            message: '${pending.rating.menuItemName} silindi.',
            actionLabel: 'Geri al',
            onAction: () => _undoDelete(pending),
          ),
        for (final notice in _notices)
          InfoBanner(
            key: ValueKey('notice_${notice.id}'),
            icon: notice.icon,
            message: notice.message,
          ),
      ];

  Future<void> _editRating(RatingModel rating) async {
    final result = await showModalBottomSheet<Map<String, dynamic>?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      // Aşağı kaydırmayı panel kendisi yönetiyor: Flutter'ın kaydırarak
      // kapatması PopScope'a sormadan kapatıyor, değişiklik kayboluyordu.
      enableDrag: false,
      builder: (_) => _EditRatingSheet(rating: rating),
    );
    if (result == null || !mounted) return;

    final newScore = result['score'] as double;
    final rawComment = result['comment'] as String?;
    final newComment = (rawComment?.isEmpty ?? true) ? null : rawComment;

    setState(() {
      final i = _allRatings.indexWhere((r) => r.ratingId == rating.ratingId);
      if (i != -1) {
        _allRatings[i] = rating.copyWith(score: newScore, comment: newComment);
        _applyFilters();
      }
    });
    ref.read(userDataRefreshProvider.notifier).state++;

    // Yeşil SnackBar yerine silme şeritleriyle aynı yığın: ekranda tek tür
    // bildirim olsun.
    if (mounted) {
      _showNotice('Puan güncellendi.',
          icon: Icons.check_circle_outline_rounded);
    }
  }

  void _openFilterSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.sheetColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (_) => _FilterSheet(
        currentSort: _sortBy,
        currentCategory: _categoryFilter,
        availableCategories: _availableCategories,
        onChanged: (sort, category) {
          setState(() {
            _sortBy = sort;
            _categoryFilter = category;
            _applyFilters();
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Başka ekranda puan verilince/silinince liste sessizce tazelenir.
    ref.listen<int>(userDataRefreshProvider, (_, __) => _load(silent: true));
    // Yemek panelindeki "Günlüğe git" isteği.
    ref.listen<int?>(diaryFocusProvider, (_, next) {
      if (next != null) _focusOn(next);
    });

    final bannerCount = _pendingDeletes.length + _notices.length;

    return Scaffold(
      backgroundColor: context.bgColor,
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: _load,
            color: AppColors.primary,
            child: CustomScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              slivers: [
                // ── App Bar ──────────────────────────────────────────────────
                SliverAppBar(
                  pinned: true,
                  backgroundColor: context.bgColor,
                  title: const Text('Günlüğüm',
                      style: AppTextStyles.headlineMedium),
                  actions: [
                    // Listelenen kart sayısı (filtre açıksa süzülmüş hâli).
                    if (!_isLoading && _error == null)
                      Center(
                        child: Text(
                          '${_displayed.length} değerlendirme',
                          style: AppTextStyles.bodySmall
                              .copyWith(color: context.textSecondaryColor),
                        ),
                      ),
                    // Filtre butonu — aktifse vurgulu
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        IconButton(
                          onPressed: _openFilterSheet,
                          tooltip: 'Filtrele ve sırala',
                          icon: Icon(
                            TablerIcons.adjustments_horizontal,
                            color: _hasActiveFilter
                                ? AppColors.primary
                                : context.textSecondaryColor,
                          ),
                        ),
                        if (_hasActiveFilter)
                          Positioned(
                            top: 10,
                            right: 10,
                            child: Container(
                              width: 7,
                              height: 7,
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      ],
                    ),
                    IconButton(
                      onPressed: _load,
                      tooltip: 'Yenile',
                      icon: Icon(TablerIcons.refresh,
                          color: context.textSecondaryColor),
                    ),
                  ],
                  bottom: PreferredSize(
                    preferredSize: const Size.fromHeight(0.5),
                    child: Builder(
                        builder: (ctx) =>
                            Container(height: 0.5, color: ctx.dividerColor)),
                  ),
                ),

                // ── Aktif filtre bildirimi ────────────────────────────────────
                if (_hasActiveFilter && !_isLoading && _error == null)
                  SliverToBoxAdapter(
                    child: _ActiveFilterBar(
                      sortBy: _sortBy,
                      category: _categoryFilter,
                      onClear: () => setState(() {
                        _sortBy = _SortBy.newest;
                        _categoryFilter = null;
                        _applyFilters();
                      }),
                    ),
                  ),

                // ── İçerik ───────────────────────────────────────────────────
                if (_isLoading)
                  const SliverToBoxAdapter(child: _DiarySkeleton())
                else if (_error != null)
                  _StateSliver(
                    child: StateMessage(
                      title: _error!,
                      message: 'Bağlantını kontrol edip tekrar dene.',
                      actionLabel: 'Tekrar dene',
                      onAction: _load,
                    ),
                  )
                else if (_visibleRatings.isEmpty)
                  const _StateSliver(
                    child: StateMessage(
                      title: 'Henüz puan vermedin',
                      message: '+ butonuna basarak ilk puanını ekle.',
                    ),
                  )
                else if (_displayed.isEmpty)
                  _StateSliver(
                    child: StateMessage(
                      title: 'Bu filtreye uyan puan yok',
                      actionLabel: 'Filtreyi temizle',
                      onAction: () => setState(() {
                        _categoryFilter = null;
                        _applyFilters();
                      }),
                    ),
                  )
                else ...[
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final rating = _displayed[index];
                        final highlighted = rating.ratingId == _highlightedId;
                        return SwipeToDelete(
                          key: Key('rating_${rating.ratingId}'),
                          sideInset: 20,
                          bottomGap: 12,
                          animateIn: _restoredIds.contains(rating.ratingId),
                          onDelete: () => _deleteRating(rating),
                          // Menüdeki "Sil" de aynı kayma ve kapanmayı oynatır.
                          builder: (_, swipeAway) => _RatingCard(
                            key: highlighted ? _highlightKey : null,
                            rating: rating,
                            highlighted: highlighted,
                            onDelete: swipeAway,
                            onEdit: () => _editRating(rating),
                          ),
                        );
                      },
                      childCount: _displayed.length,
                    ),
                  ),
                  // Şeritler açıkken son kart altlarında kalmasın (şerit ~56 + 8 aralık).
                  SliverToBoxAdapter(
                      child: AnimatedContainer(
                          duration: const Duration(milliseconds: 280),
                          curve: Curves.easeInOut,
                          height:
                              bannerCount == 0 ? 24 : 32 + bannerCount * 64)),
                ],
              ],
            ),
          ),
          // Silme şeritleri — listenin altında, alt menünün hemen üstünde.
          Positioned(
            left: 16,
            right: 16,
            bottom: 12,
            child: InfoBannerStack(banners: _buildBanners()),
          ),
        ],
      ),
    );
  }
}

/// Geri alma süresindeki silme ve süresi dolunca onu gönderecek zamanlayıcı.
class _PendingDelete {
  _PendingDelete(this.rating, this.timer);
  final RatingModel rating;
  final Timer timer;
}

/// Kısa süre görünen eylemsiz şerit mesajı.
class _Notice {
  _Notice(this.id, this.message, this.icon, this.timer);
  final int id;
  final String message;
  final IconData icon;
  final Timer timer;
}

// ── Aktif filtre bildirimi ────────────────────────────────────────────────────

class _ActiveFilterBar extends StatelessWidget {
  const _ActiveFilterBar({
    required this.sortBy,
    required this.category,
    required this.onClear,
  });

  final _SortBy sortBy;
  final String? category;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final parts = <String>[];
    if (sortBy != _SortBy.newest) parts.add(sortBy.label);
    if (category != null) parts.add(category!);

    // Kartlarla aynı yüzey: turuncu ana eyleme ayrılmış, gri dolgu da açık
    // temada sönük duruyordu.
    return Container(
      margin: const EdgeInsets.fromLTRB(
          AppSpace.screen, AppSpace.md, AppSpace.screen, AppSpace.xs),
      padding: const EdgeInsets.only(left: AppSpace.md),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: context.dividerColor),
      ),
      child: Row(
        children: [
          Icon(TablerIcons.adjustments_horizontal,
              color: context.textSecondaryColor, size: 16),
          const SizedBox(width: AppSpace.sm),
          Expanded(
            child: Text(
              parts.join(' · '),
              style: AppTextStyles.bodySmall
                  .copyWith(color: context.textPrimaryColor),
            ),
          ),
          IconButton(
            onPressed: onClear,
            tooltip: 'Filtreyi temizle',
            constraints: const BoxConstraints(
                minWidth: AppSize.minTap, minHeight: AppSize.minTap),
            icon: Icon(TablerIcons.x,
                color: context.textSecondaryColor, size: 16),
          ),
        ],
      ),
    );
  }
}

// ── Filtre bottom sheet ───────────────────────────────────────────────────────

class _FilterSheet extends StatefulWidget {
  const _FilterSheet({
    required this.currentSort,
    required this.currentCategory,
    required this.availableCategories,
    required this.onChanged,
  });

  final _SortBy currentSort;
  final String? currentCategory;
  final Set<String> availableCategories;
  final void Function(_SortBy sort, String? category) onChanged;

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late _SortBy _sort;
  String? _category;

  @override
  void initState() {
    super.initState();
    _sort = widget.currentSort;
    _category = widget.currentCategory;
  }

  void _update() => widget.onChanged(_sort, _category);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Padding(
              padding:
                  const EdgeInsets.only(top: AppSpace.md, bottom: AppSpace.lg),
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: context.dividerColor,
                  borderRadius: BorderRadius.circular(AppRadius.xs),
                ),
              ),
            ),
          ),

          // ── Sıralama ─────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.screen),
            child: Text('Sırala',
                style: AppTextStyles.titleSmall
                    .copyWith(color: context.textSecondaryColor)),
          ),
          const SizedBox(height: AppSpace.sm),
          ..._SortBy.values.map((s) => _SortOption(
                label: s.label,
                isSelected: _sort == s,
                onTap: () {
                  setState(() => _sort = s);
                  _update();
                },
              )),

          // ── Kategori (varsa) ─────────────────────────────────────────
          if (widget.availableCategories.isNotEmpty) ...[
            const SizedBox(height: AppSpace.lg),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpace.screen),
              child: Text('Kategori',
                  style: AppTextStyles.titleSmall
                      .copyWith(color: context.textSecondaryColor)),
            ),
            const SizedBox(height: AppSpace.md),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpace.screen),
              child: Row(
                children: [
                  // Tümü chip
                  _CategoryChip(
                    label: 'Tümü',
                    isSelected: _category == null,
                    onTap: () {
                      setState(() => _category = null);
                      _update();
                    },
                  ),
                  ...widget.availableCategories.map((cat) => _CategoryChip(
                        label: cat,
                        isSelected: _category == cat,
                        onTap: () {
                          setState(
                              () => _category = _category == cat ? null : cat);
                          _update();
                        },
                      )),
                ],
              ),
            ),
          ],

          SizedBox(height: AppSpace.xl + MediaQuery.paddingOf(context).bottom),
        ],
      ),
    );
  }
}

class _SortOption extends StatelessWidget {
  const _SortOption({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // Seçili seçeneğin halkası turuncu (24 Eylül). Yazı metin renginde kalır:
    // açık zeminde küçük turuncu yazı ya soluk ya da fazla koyu duruyor.
    return InkWell(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: AppSize.minTap),
        padding: const EdgeInsets.symmetric(horizontal: AppSpace.screen),
        child: Row(
          children: [
            SizedBox(
              width: 22,
              height: 22,
              child: AnimatedContainer(
                duration: AppMotion.fast,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primary
                        : context.textTertiaryColor,
                    width: isSelected ? 6 : 1.5,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpace.md),
            Text(
              label,
              style: AppTextStyles.bodyMedium.copyWith(
                color: isSelected
                    ? context.textPrimaryColor
                    : context.textSecondaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // Filtre panelindeki çip: seçiliyken turuncu + beyaz yazı, keşfet ve
    // arama çipleriyle aynı (24 Eylül). Eskiden bilerek metin renginde
    // doluydu; uygulamanın her yerinde seçili çip tek görünümde olsun diye
    // değişti.
    return Padding(
      padding: const EdgeInsets.only(right: AppSpace.sm),
      child: Pressable(
        onTap: onTap,
        semanticLabel: label,
        child: MinTapArea(
          child: AnimatedContainer(
            duration: AppMotion.base,
            curve: AppMotion.curve,
            height: 36,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.lg),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : context.fillColor,
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: Text(
              label,
              style: AppTextStyles.label.copyWith(
                fontSize: 14,
                color: isSelected ? Colors.white : context.textPrimaryColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Puan kartı ────────────────────────────────────────────────────────────────

class _RatingCard extends StatelessWidget {
  const _RatingCard({
    super.key,
    required this.rating,
    required this.onDelete,
    required this.onEdit,
    this.highlighted = false,
  });
  final RatingModel rating;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  /// "Günlüğe git" ile gelindiğinde kart kısa süre aydınlanır.
  final bool highlighted;

  /// Kart köşesi. Ölçekte (12 / 20) yok: kart hem fotoğraftan (8) hem panel
  /// köşesinden ayrı durmalı. Kaydırarak silmedeki kırmızı alan da bununla
  /// aynı yarıçapı kullanıyor.
  static const double cardRadius = 16;

  @override
  Widget build(BuildContext context) {
    // Vurgu: turuncudan normale sönen zemin ve kenarlık.
    return TweenAnimationBuilder<double>(
      key: ValueKey(highlighted),
      tween: Tween(begin: highlighted ? 1 : 0, end: 0),
      duration: Duration(milliseconds: highlighted ? 1200 : 0),
      curve: Curves.easeOut,
      builder: (context, t, child) => Container(
        margin: const EdgeInsets.fromLTRB(
            AppSpace.screen, 0, AppSpace.screen, AppSpace.md),
        padding: const EdgeInsets.all(AppSpace.lg),
        decoration: BoxDecoration(
          color: Color.lerp(context.surfaceColor,
              AppColors.primary.withValues(alpha: 0.14), t),
          borderRadius: BorderRadius.circular(cardRadius),
          border: Border.all(
            color: Color.lerp(context.dividerColor, AppColors.primary, t)!,
          ),
        ),
        child: child,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Üst satır
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Fotoğraf (varsa) veya ikon — kendi fotoğrafını eklediysen o.
              DishPhoto(
                url: rating.reviewPhotoUrl ?? rating.photoUrl,
                width: 48,
                height: 48,
                radius: AppRadius.sm,
                iconSize: 22,
              ),
              const SizedBox(width: AppSpace.md),
              // Orta: yemek adı + restoran + yıldızlar
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(rating.menuItemName, style: AppTextStyles.titleSmall),
                    const SizedBox(height: AppSpace.xxs),
                    Text(rating.restaurantName,
                        style: AppTextStyles.bodySmall
                            .copyWith(color: context.textSecondaryColor)),
                    const SizedBox(height: AppSpace.sm),
                    Row(
                      children: [
                        StarRow(rating: rating.score, size: 14),
                        const SizedBox(width: AppSpace.sm),
                        // Tarih
                        if (rating.ratedAt != null)
                          Text(
                            RelativeDate.date(rating.ratedAt!),
                            style: AppTextStyles.caption.copyWith(
                              color: context.textTertiaryColor,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              // Sağ: puan + 3 nokta menü
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    rating.score.toStringAsFixed(1),
                    style: AppTextStyles.ratingSmall.copyWith(fontSize: 18),
                  ),
                  const SizedBox(height: AppSpace.xs),
                  SizedBox(
                    width: 28,
                    height: 28,
                    child: PopupMenuButton<String>(
                      padding: EdgeInsets.zero,
                      iconSize: 18,
                      tooltip: 'Seçenekler',
                      color: context.surfaceColor,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md)),
                      icon: Icon(TablerIcons.dots_vertical,
                          color: context.textTertiaryColor),
                      onSelected: (value) {
                        if (value == 'delete') onDelete();
                        if (value == 'edit') onEdit();
                      },
                      itemBuilder: (_) => [
                        PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(TablerIcons.pencil,
                                  size: 16, color: context.textSecondaryColor),
                              const SizedBox(width: AppSpace.md),
                              Text('Düzenle',
                                  style: AppTextStyles.bodySmall.copyWith(
                                      color: context.textPrimaryColor)),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(TablerIcons.trash,
                                  size: 16, color: context.errorTextColor),
                              const SizedBox(width: AppSpace.md),
                              Text('Sil',
                                  style: AppTextStyles.bodySmall
                                      .copyWith(color: context.errorTextColor)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          // Yorum
          if (rating.comment != null && rating.comment!.isNotEmpty) ...[
            const SizedBox(height: AppSpace.md),
            // Gri kutu bilinçli: yorum kartın içinde ayrışmalı (açık temada da).
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpace.md),
              decoration: BoxDecoration(
                color: context.surfaceElevatedColor,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Text(
                '“${rating.comment}”',
                style: AppTextStyles.bodySmall.copyWith(
                  fontStyle: FontStyle.italic,
                  color: context.textSecondaryColor,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Yükleniyor ve durum mesajları ────────────────────────────────────────────

/// Kart biçiminde yükleniyor iskeleti; liste gelince yerine aynı ölçüde
/// kartlar oturur.
class _DiarySkeleton extends StatelessWidget {
  const _DiarySkeleton();

  @override
  Widget build(BuildContext context) {
    return SkeletonPulse(
      child: Column(
        children: [
          const SizedBox(height: AppSpace.md),
          for (var i = 0; i < 4; i++)
            Container(
              margin: const EdgeInsets.fromLTRB(
                  AppSpace.screen, 0, AppSpace.screen, AppSpace.md),
              padding: const EdgeInsets.all(AppSpace.lg),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(_RatingCard.cardRadius),
                border: Border.all(color: context.dividerColor),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonBox(width: 48, height: 48, radius: AppRadius.sm),
                  SizedBox(width: AppSpace.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SkeletonBox(width: 150, height: 14),
                        SizedBox(height: AppSpace.sm),
                        SkeletonBox(width: 100, height: 12),
                        SizedBox(height: AppSpace.sm),
                        SkeletonBox(width: 120, height: 12),
                      ],
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

/// Boş, sonuçsuz ve hata durumları: Keşfet'teki gibi sola hizalı, ekran
/// kenarından başlayan mesaj.
class _StateSliver extends StatelessWidget {
  const _StateSliver({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
            AppSpace.screen, AppSpace.xxl, AppSpace.screen, 0),
        child: child,
      ),
    );
  }
}

// ── Değerlendirme düzenleme sheet'i ──────────────────────────────────────────

class _EditRatingSheet extends StatefulWidget {
  const _EditRatingSheet({required this.rating});
  final RatingModel rating;

  @override
  State<_EditRatingSheet> createState() => _EditRatingSheetState();
}

class _EditRatingSheetState extends State<_EditRatingSheet> {
  late double _score;
  late final TextEditingController _commentCtrl;
  bool _isLoading = false;
  String? _error;

  /// Kayıtlı fotoğraf (varsa). Kullanıcı kaldırırsa [_photoRemoved] açılır.
  String? _currentPhoto;
  bool _photoRemoved = false;

  /// Yeni seçilen fotoğraf; kaydederken yüklenir.
  XFile? _newPhoto;
  Uint8List? _newPhotoBytes;

  bool get _hasPhoto =>
      _newPhotoBytes != null || (!_photoRemoved && _currentPhoto != null);

  /// Kayıtlı hâlden farkı var mı? Yoksa "Güncelle" pasif kalır, kapatırken
  /// onay sorulmaz (bkz. [EditSheetGuard]). Fotoğraf eklemek, değiştirmek
  /// ya da kaldırmak da sayılır.
  bool get _isDirty =>
      _score != widget.rating.score ||
      _commentCtrl.text.trim() != (widget.rating.comment ?? '').trim() ||
      _newPhoto != null ||
      (_photoRemoved && _currentPhoto != null);

  @override
  void initState() {
    super.initState();
    _score = widget.rating.score;
    _commentCtrl = TextEditingController(text: widget.rating.comment ?? '');
    _currentPhoto = widget.rating.reviewPhotoUrl;
    // Her harfte "Güncelle"nin durumu yeniden hesaplansın.
    _commentCtrl.addListener(() => setState(() {}));
  }

  Future<void> _pickPhoto() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: context.surfaceElevatedColor,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(TablerIcons.camera),
              title: const Text('Fotoğraf çek'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(TablerIcons.photo),
              title: const Text('Galeriden seç'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;
    try {
      final file = await ImagePicker()
          .pickImage(source: source, maxWidth: 1600, imageQuality: 85);
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      setState(() {
        _newPhoto = file;
        _newPhotoBytes = bytes;
        _photoRemoved = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() =>
            _error = 'Fotoğrafa erişilemedi. İzni Ayarlar’dan açabilirsin.');
      }
    }
  }

  void _removePhoto() {
    setState(() {
      _newPhoto = null;
      _newPhotoBytes = null;
      _photoRemoved = true;
    });
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_score == 0) {
      setState(() => _error = 'Lütfen bir puan ver.');
      return;
    }
    setState(() {
      _isLoading = true;
      _error = null;
    });

    // Yeni fotoğraf varsa yüklenir; kaldırıldıysa boş metin gider (sunucu
    // fotoğrafı siler); ikisi de yoksa null gider ve mevcut fotoğraf kalır.
    String? photoUrl;
    if (_newPhoto != null) {
      try {
        photoUrl = await FileRepository.instance.uploadImage(_newPhoto!);
      } catch (_) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _error = 'Fotoğraf yüklenemedi, tekrar dene.';
          });
        }
        return;
      }
    } else if (_photoRemoved) {
      photoUrl = '';
    }

    try {
      await RatingRepository.instance.submitRating(
        RatingRequestModel(
          userId: widget.rating.userId,
          menuItemId: widget.rating.menuItemId,
          score: _score,
          comment: _commentCtrl.text.trim(),
          photoUrl: photoUrl,
        ),
      );
      if (mounted) {
        Navigator.pop(context, {
          'score': _score,
          'comment': _commentCtrl.text.trim(),
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = userMessageFor(e, fallback: 'Güncellenemedi, tekrar dene.');
        });
      }
    }
  }

  static String _scoreLabel(double score) =>
      score == 0 ? 'Puan seç' : ratingLabel(score);

  @override
  Widget build(BuildContext context) {
    return EditSheetGuard(
      isDirty: _isDirty,
      busy: _isLoading,
      discardMessage: 'Güncellemeyi iptal etmek istiyor musun?',
      child: _buildSheet(context),
    );
  }

  Widget _buildSheet(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: context.sheetColor,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            const SizedBox(height: AppSpace.md),
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: context.dividerColor,
                  borderRadius: BorderRadius.circular(AppRadius.xs),
                ),
              ),
            ),
            const SizedBox(height: AppSpace.screen),

            // Başlık
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpace.screen),
              // Tam genişlik: yoksa sütun metin kadar daralıp ortada kalıyordu.
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text('Değerlendirmeyi Düzenle',
                            style: AppTextStyles.titleSmall),
                        const SizedBox(height: AppSpace.xxs),
                        Text(
                          '${widget.rating.restaurantName} · ${widget.rating.menuItemName}',
                          style: AppTextStyles.bodySmall
                              .copyWith(color: context.textSecondaryColor),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpace.sm),
                  const SheetCancelButton(
                      semanticLabel: 'Düzenlemeyi iptal et'),
                ],
              ),
            ),
            const SizedBox(height: AppSpace.xl),

            // Yıldız
            Center(
              child: Column(
                children: [
                  Text(
                    _score == 0 ? '—' : _score.toStringAsFixed(1),
                    style: AppTextStyles.ratingLarge.copyWith(fontSize: 46),
                  ),
                  const SizedBox(height: AppSpace.md),
                  // Değerlendirme akışındaki yıldızların aynısı: boşlar
                  // çerçeveli, koyu temada da görünür.
                  RatingBar(
                    initialRating: _score,
                    minRating: 0.5,
                    allowHalfRating: true,
                    itemCount: 5,
                    itemSize: 40,
                    itemPadding: const EdgeInsets.symmetric(horizontal: 2),
                    glow: false,
                    ratingWidget: RatingWidget(
                      full: const StarGlyph(fill: 1, size: 40),
                      half: StarGlyph(
                          fill: 0.5,
                          size: 40,
                          emptyColor: context.starOutlineColor),
                      empty: StarGlyph(
                          fill: 0,
                          size: 40,
                          emptyColor: context.starOutlineColor),
                    ),
                    onRatingUpdate: (r) => setState(() => _score = r),
                  ),
                  const SizedBox(height: AppSpace.sm),
                  Text(
                    _scoreLabel(_score),
                    style: AppTextStyles.bodySmall.copyWith(
                      color: context.textSecondaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpace.screen),

            // Yorum
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpace.screen),
              child: TextField(
                controller: _commentCtrl,
                maxLines: 3,
                maxLength: 500,
                style: AppTextStyles.bodyMedium,
                decoration: InputDecoration(
                  hintText: 'Bu yemek hakkında ne düşünüyorsun?',
                  alignLabelWithHint: true,
                  counterStyle: AppTextStyles.caption
                      .copyWith(color: context.textTertiaryColor),
                ),
              ),
            ),

            // ── Fotoğraf ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpace.screen),
              child: Row(
                children: [
                  if (_hasPhoto)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      child: _newPhotoBytes != null
                          ? Image.memory(_newPhotoBytes!,
                              width: 56, height: 56, fit: BoxFit.cover)
                          : DishPhoto(
                              url: _currentPhoto, width: 56, height: 56),
                    ),
                  if (_hasPhoto) const SizedBox(width: AppSpace.md),
                  TextButton.icon(
                    onPressed: _pickPhoto,
                    icon: const Icon(TablerIcons.camera, size: 18),
                    label: Text(_hasPhoto ? 'Değiştir' : 'Fotoğraf ekle'),
                  ),
                  if (_hasPhoto)
                    TextButton(
                      onPressed: _removePhoto,
                      style: TextButton.styleFrom(
                          foregroundColor: context.textSecondaryColor),
                      child: const Text('Kaldır'),
                    ),
                ],
              ),
            ),

            if (_error != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpace.screen, AppSpace.xs, AppSpace.screen, 0),
                child: Text(_error!,
                    style: AppTextStyles.bodySmall
                        .copyWith(color: context.errorTextColor)),
              ),

            const SizedBox(height: AppSpace.lg),

            // Kaydet butonu
            Padding(
              padding: EdgeInsets.fromLTRB(AppSpace.screen, 0, AppSpace.screen,
                  AppSpace.xl + MediaQuery.paddingOf(context).bottom),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (_isLoading || !_isDirty) ? null : _save,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('Güncelle'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

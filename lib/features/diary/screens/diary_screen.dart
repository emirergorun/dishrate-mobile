import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/auth/auth_provider.dart';
import '../../../core/network/file_repository.dart';
import '../../../core/network/rating_repository.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/models/rating_model.dart';
import '../../../shared/models/rating_request_model.dart';
import '../../../shared/providers/data_refresh.dart';
import '../../../shared/widgets/dish_photo.dart';
import '../../../shared/widgets/info_banner.dart';
import '../../../shared/widgets/swipe_to_delete.dart';

// ── Sıralama seçenekleri ──────────────────────────────────────────────────────

enum _SortBy {
  newest('En Yeni'),
  oldest('En Eski'),
  highest('En Yüksek Puan'),
  lowest('En Düşük Puan');

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

  @override
  void initState() {
    super.initState();
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
          _error = 'Oturum bulunamadı.';
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
      if (mounted) setState(() => _error = 'Puanlar yüklenemedi.');
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
  }

  void _undoDelete(_PendingDelete pending) {
    pending.timer.cancel();
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

  Future<void> _commitDelete(_PendingDelete pending) async {
    pending.timer.cancel();
    if (!mounted || !_pendingDeletes.contains(pending)) return;
    final rating = pending.rating;
    setState(() {
      _pendingDeletes.remove(pending);
      _allRatings.removeWhere((r) => r.ratingId == rating.ratingId);
      _applyFilters();
    });
    try {
      await RatingRepository.instance.deleteRating(rating.ratingId);
      if (mounted) ref.read(userDataRefreshProvider.notifier).state++;
    } catch (_) {
      if (!mounted) return;
      // Sunucu silmediyse kart geri gelir.
      _markRestored(rating.ratingId);
      setState(() {
        _allRatings.add(rating);
        _applyFilters();
      });
      _showNotice('Silinemedi, tekrar dene.');
    }
  }

  void _showNotice(String message) {
    late final _Notice notice;
    notice = _Notice(
        _noticeSeq++,
        message,
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
            message:
                '${pending.rating.restaurantName} - ${pending.rating.menuItemName} silindi.',
            actionLabel: 'Geri al',
            onAction: () => _undoDelete(pending),
          ),
        for (final notice in _notices)
          InfoBanner(
            key: ValueKey('notice_${notice.id}'),
            icon: Icons.error_outline_rounded,
            message: notice.message,
          ),
      ];

  Future<void> _editRating(RatingModel rating) async {
    final result = await showModalBottomSheet<Map<String, dynamic>?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
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

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Row(children: [
          const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Text('Puan güncellendi!',
              style: AppTextStyles.bodyMedium.copyWith(color: Colors.white)),
        ]),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    }
  }

  void _openFilterSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.surfaceColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
                          icon: Icon(
                            Icons.tune_rounded,
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
                      icon: Icon(Icons.refresh_rounded,
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
                  const SliverFillRemaining(
                    child: Center(
                      child:
                          CircularProgressIndicator(color: AppColors.primary),
                    ),
                  )
                else if (_error != null)
                  SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.error_outline,
                              color: AppColors.error, size: 40),
                          const SizedBox(height: 12),
                          Text(_error!, style: AppTextStyles.bodyMedium),
                          const SizedBox(height: 16),
                          ElevatedButton(
                              onPressed: _load,
                              child: const Text('Tekrar Dene')),
                        ],
                      ),
                    ),
                  )
                else if (_visibleRatings.isEmpty)
                  const SliverFillRemaining(child: _EmptyDiary())
                else if (_displayed.isEmpty)
                  SliverFillRemaining(
                      child: _NoFilterResults(
                    onClear: () => setState(() {
                      _categoryFilter = null;
                      _applyFilters();
                    }),
                  ))
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
  _Notice(this.id, this.message, this.timer);
  final int id;
  final String message;
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

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.tune_rounded, color: AppColors.primary, size: 15),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              parts.join(' · '),
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.primary),
            ),
          ),
          GestureDetector(
            onTap: onClear,
            child: const Icon(Icons.close_rounded,
                color: AppColors.primary, size: 16),
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
              padding: const EdgeInsets.only(top: 12, bottom: 16),
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: context.dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),

          // ── Sıralama ─────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text('Sırala',
                style: AppTextStyles.titleSmall
                    .copyWith(color: context.textSecondaryColor)),
          ),
          const SizedBox(height: 8),
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
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text('Kategori',
                  style: AppTextStyles.titleSmall
                      .copyWith(color: context.textSecondaryColor)),
            ),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
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

          const SizedBox(height: 24),
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
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 4, 20, 4),
        child: Row(
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color:
                        isSelected ? AppColors.primary : AppColors.textDisabled,
                    width: isSelected ? 5 : 1.5,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
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
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : context.surfaceElevatedColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : context.dividerColor,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: isSelected ? Colors.white : context.textPrimaryColor,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
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

  static const _months = [
    'Oca',
    'Şub',
    'Mar',
    'Nis',
    'May',
    'Haz',
    'Tem',
    'Ağu',
    'Eyl',
    'Eki',
    'Kas',
    'Ara',
  ];

  String _formatDate(DateTime dt) {
    return '${dt.day} ${_months[dt.month - 1]} ${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    // Vurgu: turuncudan normale sönen zemin ve kenarlık.
    return TweenAnimationBuilder<double>(
      key: ValueKey(highlighted),
      tween: Tween(begin: highlighted ? 1 : 0, end: 0),
      duration: Duration(milliseconds: highlighted ? 1200 : 0),
      curve: Curves.easeOut,
      builder: (context, t, child) => Container(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Color.lerp(context.surfaceColor,
              AppColors.primary.withValues(alpha: 0.14), t),
          borderRadius: BorderRadius.circular(16),
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
                radius: 10,
                iconSize: 22,
              ),
              const SizedBox(width: 12),
              // Orta: yemek adı + restoran + yıldızlar
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(rating.menuItemName, style: AppTextStyles.titleSmall),
                    const SizedBox(height: 2),
                    Text(rating.restaurantName, style: AppTextStyles.bodySmall),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        RatingBarIndicator(
                          rating: rating.score,
                          itemSize: 16,
                          itemBuilder: (_, __) => const Icon(
                            Icons.star_rounded,
                            color: AppColors.star,
                          ),
                        ),
                        const SizedBox(width: 6),
                        // Tarih
                        if (rating.ratedAt != null)
                          Text(
                            _formatDate(rating.ratedAt!),
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textDisabled,
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
                  const SizedBox(height: 4),
                  SizedBox(
                    width: 28,
                    height: 28,
                    child: PopupMenuButton<String>(
                      padding: EdgeInsets.zero,
                      iconSize: 18,
                      color: context.surfaceColor,
                      icon: const Icon(Icons.more_vert_rounded,
                          color: AppColors.textDisabled),
                      onSelected: (value) {
                        if (value == 'delete') onDelete();
                        if (value == 'edit') onEdit();
                      },
                      itemBuilder: (_) => [
                        PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit_rounded,
                                  size: 16, color: context.textSecondaryColor),
                              const SizedBox(width: 10),
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
                              const Icon(Icons.delete_outline_rounded,
                                  size: 16, color: AppColors.error),
                              const SizedBox(width: 10),
                              Text('Sil',
                                  style: AppTextStyles.bodySmall
                                      .copyWith(color: AppColors.error)),
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
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: context.surfaceElevatedColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '"${rating.comment}"',
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

// ── Boş durumlar ──────────────────────────────────────────────────────────────

class _EmptyDiary extends StatelessWidget {
  const _EmptyDiary();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.menu_book_rounded,
              color: AppColors.textDisabled, size: 56),
          const SizedBox(height: 16),
          Text('Henüz puan vermedin.',
              style: AppTextStyles.titleMedium
                  .copyWith(color: context.textSecondaryColor)),
          const SizedBox(height: 8),
          Text(
            '+ butonuna basarak ilk puanını ekle.',
            style: AppTextStyles.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _NoFilterResults extends StatelessWidget {
  const _NoFilterResults({required this.onClear});
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.filter_list_off_rounded,
              color: AppColors.textDisabled, size: 48),
          const SizedBox(height: 16),
          Text('Bu filtreye uyan puan yok.',
              style: AppTextStyles.titleMedium
                  .copyWith(color: context.textSecondaryColor)),
          const SizedBox(height: 16),
          TextButton(
            onPressed: onClear,
            child: const Text('Filtreyi Temizle'),
          ),
        ],
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

  @override
  void initState() {
    super.initState();
    _score = widget.rating.score;
    _commentCtrl = TextEditingController(text: widget.rating.comment ?? '');
    _currentPhoto = widget.rating.reviewPhotoUrl;
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
              leading: const Icon(Icons.photo_camera_rounded),
              title: const Text('Fotoğraf çek'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded),
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
            _error = 'Fotoğrafa erişilemedi. İzni Ayarlar\'dan açabilirsin.');
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
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Güncellenemedi, tekrar dene.';
        });
      }
    }
  }

  static String _scoreLabel(double score) {
    if (score == 0) return 'Puan seç';
    if (score <= 1.0) return 'Berbat';
    if (score <= 2.0) return 'İdare eder';
    if (score <= 3.0) return 'Fena değil';
    if (score <= 3.5) return 'İyi';
    if (score <= 4.0) return 'Güzel';
    if (score <= 4.5) return 'Harika';
    return 'Mükemmel!';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: context.surfaceElevatedColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
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
            const SizedBox(height: 20),

            // Başlık
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Değerlendirmeyi Düzenle',
                      style: AppTextStyles.titleSmall),
                  const SizedBox(height: 3),
                  Row(children: [
                    const Icon(Icons.storefront_rounded,
                        color: AppColors.primary, size: 13),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '${widget.rating.restaurantName} · ${widget.rating.menuItemName}',
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.primary),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ]),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Yıldız
            Center(
              child: Column(
                children: [
                  Text(
                    _score == 0 ? '—' : _score.toStringAsFixed(1),
                    style: AppTextStyles.ratingLarge.copyWith(fontSize: 46),
                  ),
                  const SizedBox(height: 12),
                  RatingBar.builder(
                    initialRating: _score,
                    minRating: 0.5,
                    allowHalfRating: true,
                    itemCount: 5,
                    itemSize: 40,
                    unratedColor: context.surfaceColor,
                    itemBuilder: (_, __) =>
                        const Icon(Icons.star_rounded, color: AppColors.star),
                    onRatingUpdate: (r) => setState(() => _score = r),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _scoreLabel(_score),
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Yorum
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: _commentCtrl,
                maxLines: 3,
                maxLength: 500,
                style: AppTextStyles.bodyMedium,
                decoration: const InputDecoration(
                  hintText: 'Yorumunu güncelle...',
                  alignLabelWithHint: true,
                  counterStyle: TextStyle(color: AppColors.textDisabled),
                ),
              ),
            ),

            // ── Fotoğraf ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  if (_hasPhoto)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: _newPhotoBytes != null
                          ? Image.memory(_newPhotoBytes!,
                              width: 56, height: 56, fit: BoxFit.cover)
                          : DishPhoto(
                              url: _currentPhoto, width: 56, height: 56),
                    ),
                  if (_hasPhoto) const SizedBox(width: 12),
                  TextButton.icon(
                    onPressed: _pickPhoto,
                    icon: const Icon(Icons.photo_camera_rounded, size: 18),
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
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                child: Text(_error!,
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.error)),
              ),

            const SizedBox(height: 16),

            // Kaydet butonu
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _save,
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

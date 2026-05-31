import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

import '../../../core/network/rating_repository.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/models/rating_model.dart';
import '../../../shared/models/rating_request_model.dart';

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

class DiaryScreen extends StatefulWidget {
  const DiaryScreen({super.key});

  @override
  State<DiaryScreen> createState() => _DiaryScreenState();
}

class _DiaryScreenState extends State<DiaryScreen> {
  static const int _userId = 1; // TODO: auth sonrası gerçek userId

  List<RatingModel> _allRatings = [];
  List<RatingModel> _displayed = [];
  bool _isLoading = true;
  String? _error;

  _SortBy _sortBy = _SortBy.newest;
  String? _categoryFilter; // null = tümü

  // Yüklenen puanlardan dinamik kategori listesi
  Set<String> get _availableCategories => _allRatings
      .map((r) => r.categoryName)
      .whereType<String>()
      .toSet();

  bool get _hasActiveFilter =>
      _categoryFilter != null || _sortBy != _SortBy.newest;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final ratings =
          await RatingRepository.instance.getRatingsByUser(_userId);
      if (mounted) {
        setState(() {
          _allRatings = List.from(ratings); // unmodifiable → mutable copy
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
    var list = _allRatings.where((r) {
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

  Future<void> _deleteRating(RatingModel rating) async {
    try {
      await RatingRepository.instance.deleteRating(rating.ratingId);
      setState(() {
        _allRatings.removeWhere((r) => r.ratingId == rating.ratingId);
        _applyFilters();
      });
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Silinemedi, tekrar dene.')),
        );
      }
    }
  }

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
        _allRatings[i] = RatingModel(
          ratingId: rating.ratingId,
          userId: rating.userId,
          username: rating.username,
          menuItemId: rating.menuItemId,
          menuItemName: rating.menuItemName,
          restaurantName: rating.restaurantName,
          categoryName: rating.categoryName,
          score: newScore,
          comment: newComment,
          ratedAt: rating.ratedAt,
        );
        _applyFilters();
      }
    });

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
    return Scaffold(
      backgroundColor: context.bgColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── App Bar ──────────────────────────────────────────────────
          SliverAppBar(
            pinned: true,
            backgroundColor: context.bgColor,
            title: Text('Günlüğüm', style: AppTextStyles.headlineMedium),
            actions: [
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
                          : AppColors.textSecondary,
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
                icon: const Icon(Icons.refresh_rounded,
                    color: AppColors.textSecondary),
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(0.5),
              child: Builder(builder: (ctx) => Container(height: 0.5, color: ctx.dividerColor)),
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
                child: CircularProgressIndicator(color: AppColors.primary),
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
                        onPressed: _load, child: const Text('Tekrar Dene')),
                  ],
                ),
              ),
            )
          else if (_allRatings.isEmpty)
            const SliverFillRemaining(child: _EmptyDiary())
          else if (_displayed.isEmpty)
            SliverFillRemaining(child: _NoFilterResults(
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
                  return _SwipeCard(
                    key: Key('rating_${rating.ratingId}'),
                    onDelete: () => _deleteRating(rating),
                    child: _RatingCard(
                      rating: rating,
                      onDelete: () => _deleteRating(rating),
                      onEdit: () => _editRating(rating),
                    ),
                  );
                },
                childCount: _displayed.length,
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ],
      ),
    );
  }
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
        border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.tune_rounded,
              color: AppColors.primary, size: 15),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              parts.join(' · '),
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.primary),
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
                    .copyWith(color: AppColors.textSecondary)),
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
                      .copyWith(color: AppColors.textSecondary)),
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
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.textDisabled,
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
                    : AppColors.textSecondary,
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
    required this.rating,
    required this.onDelete,
    required this.onEdit,
  });
  final RatingModel rating;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  static const _months = [
    'Oca', 'Şub', 'Mar', 'Nis', 'May', 'Haz',
    'Tem', 'Ağu', 'Eyl', 'Eki', 'Kas', 'Ara',
  ];

  String _formatDate(DateTime dt) {
    return '${dt.day} ${_months[dt.month - 1]} ${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Üst satır
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // İkon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: context.surfaceElevatedColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.restaurant_rounded,
                    color: AppColors.textDisabled, size: 22),
              ),
              const SizedBox(width: 12),
              // Orta: yemek adı + restoran + yıldızlar
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(rating.menuItemName,
                        style: AppTextStyles.titleSmall),
                    const SizedBox(height: 2),
                    Text(rating.restaurantName,
                        style: AppTextStyles.bodySmall),
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
                              const Icon(Icons.edit_rounded,
                                  size: 16,
                                  color: AppColors.textSecondary),
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
                  color: AppColors.textSecondary,
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
                  .copyWith(color: AppColors.textSecondary)),
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
                  .copyWith(color: AppColors.textSecondary)),
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

  @override
  void initState() {
    super.initState();
    _score = widget.rating.score;
    _commentCtrl = TextEditingController(text: widget.rating.comment ?? '');
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
    setState(() { _isLoading = true; _error = null; });
    try {
      await RatingRepository.instance.submitRating(
        RatingRequestModel(
          userId: 1,
          menuItemId: widget.rating.menuItemId,
          score: _score,
          comment: _commentCtrl.text.trim(),
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
        setState(() { _isLoading = false; _error = 'Güncellenemedi, tekrar dene.'; });
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
                  Text('Değerlendirmeyi Düzenle',
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
                    style:
                        AppTextStyles.ratingLarge.copyWith(fontSize: 46),
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

// ── Kaydırarak sil (partial swipe reveal) ────────────────────────────────────

class _SwipeCard extends StatefulWidget {
  const _SwipeCard({super.key, required this.child, required this.onDelete});

  final Widget child;
  final VoidCallback onDelete;

  @override
  State<_SwipeCard> createState() => _SwipeCardState();
}

class _SwipeCardState extends State<_SwipeCard>
    with SingleTickerProviderStateMixin {
  static const _revealWidth = 80.0;

  late final AnimationController _ctrl;
  double _offset = 0;
  double _animStart = 0;
  double _animEnd = 0;
  bool _deleting = false;
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
    )
      ..addListener(() {
        final t = Curves.easeOutCubic.transform(_ctrl.value);
        if (mounted) {
          setState(() => _offset = _animStart + (_animEnd - _animStart) * t);
        }
      })
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed && _deleting && mounted) {
          widget.onDelete();
        }
      });
  }

  @override
  void dispose() {
    _removeOverlay();
    _ctrl.dispose();
    super.dispose();
  }

  void _animateTo(double target, {bool delete = false}) {
    _deleting = delete;
    _animStart = _offset;
    _animEnd = target;
    _ctrl.forward(from: 0);
  }

  // Kart açıkken ekranın tamamına şeffaf overlay — herhangi bir yere tap = kapat
  void _showOverlay() {
    _removeOverlay();
    _overlayEntry = OverlayEntry(
      builder: (_) => Positioned.fill(
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: _snapBack,
        ),
      ),
    );
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _snapBack() {
    _removeOverlay();
    _animateTo(0);
  }

  void _onDragUpdate(DragUpdateDetails d) {
    if (_deleting) return;
    _ctrl.stop();
    setState(() => _offset = (_offset + d.delta.dx).clamp(-300.0, 0.0));
  }

  void _onDragEnd(DragEndDetails d) {
    if (_deleting) return;
    final velocity = d.primaryVelocity ?? 0;
    final screenWidth = MediaQuery.sizeOf(context).width;

    if (velocity < -1200 || _offset < -(screenWidth * 0.5)) {
      _removeOverlay();
      _animateTo(-(screenWidth + 40), delete: true);
    } else if (_offset < -(_revealWidth * 0.35) || velocity < -300) {
      _animateTo(-_revealWidth);
      _showOverlay();
    } else {
      _snapBack();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.hardEdge,
      children: [
        // Çöp kovası — kart kaymaya başlamadan önce göstermiyoruz (köşe bleeding önlemi)
        if (_offset < -1)
          Positioned(
            top: 0,
            right: 20,
            bottom: 12,
            child: SizedBox(
              width: _revealWidth,
              child: GestureDetector(
                onTap: widget.onDelete,
                behavior: HitTestBehavior.opaque,
                child: Container(
                  decoration: const BoxDecoration(
                    color: AppColors.error,
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                  ),
                  child: const Icon(
                    Icons.delete_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ),
          ),
        // Kart (kaydırılabilir) — overlay zaten tap'leri yakalar
        Transform.translate(
          offset: Offset(_offset, 0),
          child: GestureDetector(
            onHorizontalDragUpdate: _onDragUpdate,
            onHorizontalDragEnd: _onDragEnd,
            child: widget.child,
          ),
        ),
      ],
    );
  }
}

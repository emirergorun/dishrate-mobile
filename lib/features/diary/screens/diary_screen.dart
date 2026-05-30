import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import '../../../core/network/rating_repository.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/models/rating_model.dart';

class DiaryScreen extends StatefulWidget {
  const DiaryScreen({super.key});

  @override
  State<DiaryScreen> createState() => _DiaryScreenState();
}

class _DiaryScreenState extends State<DiaryScreen> {
  // TODO: auth sonrası gerçek userId kullanılacak
  static const int _userId = 1;

  List<RatingModel> _ratings = [];
  bool _isLoading = true;
  String? _error;

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
      if (mounted) setState(() => _ratings = ratings);
    } catch (_) {
      if (mounted) setState(() => _error = 'Puanlar yüklenemedi.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── App Bar ──────────────────────────────────────────────────
          SliverAppBar(
            pinned: true,
            backgroundColor: AppColors.background,
            title: Text('Günlüğüm', style: AppTextStyles.headlineMedium),
            actions: [
              IconButton(
                onPressed: _load,
                icon: const Icon(Icons.refresh_rounded,
                    color: AppColors.textSecondary),
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(0.5),
              child: Container(height: 0.5, color: AppColors.divider),
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
          else if (_ratings.isEmpty)
            SliverFillRemaining(
              child: _EmptyDiary(),
            )
          else ...[
            // Özet satırı
            SliverToBoxAdapter(
              child: _SummaryBar(ratings: _ratings),
            ),
            // Puan listesi
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _RatingCard(rating: _ratings[index]),
                childCount: _ratings.length,
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ],
      ),
    );
  }
}

// ── Özet bar ─────────────────────────────────────────────────────────────────

class _SummaryBar extends StatelessWidget {
  const _SummaryBar({required this.ratings});
  final List<RatingModel> ratings;

  double get _ort => ratings.isEmpty
      ? 0
      : ratings.map((r) => r.score).reduce((a, b) => a + b) / ratings.length;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          _StatItem(
            value: '${ratings.length}',
            label: 'Toplam Puan',
          ),
          _Divider(),
          _StatItem(
            value: _ort.toStringAsFixed(1),
            label: 'Ortalama',
            isRating: true,
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.value,
    required this.label,
    this.isRating = false,
  });
  final String value;
  final String label;
  final bool isRating;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isRating) ...[
                const Icon(Icons.star_rounded,
                    color: AppColors.star, size: 18),
                const SizedBox(width: 4),
              ],
              Text(
                value,
                style: AppTextStyles.ratingLarge.copyWith(
                  color: isRating ? AppColors.star : AppColors.textPrimary,
                  fontSize: 26,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(label, style: AppTextStyles.bodySmall),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 36,
      color: AppColors.divider,
    );
  }
}

// ── Puan kartı ────────────────────────────────────────────────────────────────

class _RatingCard extends StatelessWidget {
  const _RatingCard({required this.rating});
  final RatingModel rating;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Üst satır: yemek adı + puan
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Sol: yemek ikonu
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.restaurant_rounded,
                    color: AppColors.textDisabled, size: 22),
              ),
              const SizedBox(width: 12),
              // Orta: isim
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      rating.menuItemName,
                      style: AppTextStyles.titleSmall,
                    ),
                    const SizedBox(height: 6),
                    RatingBarIndicator(
                      rating: rating.score,
                      itemSize: 16,
                      itemBuilder: (_, __) => const Icon(
                        Icons.star_rounded,
                        color: AppColors.star,
                      ),
                    ),
                  ],
                ),
              ),
              // Sağ: puan sayısı
              Text(
                rating.score.toStringAsFixed(1),
                style: AppTextStyles.ratingSmall.copyWith(fontSize: 18),
              ),
            ],
          ),
          // Yorum varsa göster
          if (rating.comment != null && rating.comment!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
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

// ── Boş durum ─────────────────────────────────────────────────────────────────

class _EmptyDiary extends StatelessWidget {
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

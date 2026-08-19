import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

import '../../../core/network/rating_repository.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/models/menu_item_review_model.dart';

/// Bir menü öğesine yapılan tüm değerlendirmeler. İsimler gizlilik için
/// maskeli gelir (E*** E***); kullanıcı kendi yorumunu gerçek adıyla görür.
class MenuItemReviewsScreen extends StatefulWidget {
  const MenuItemReviewsScreen({
    super.key,
    required this.menuItemId,
    required this.menuItemName,
  });
  final int menuItemId;
  final String menuItemName;

  @override
  State<MenuItemReviewsScreen> createState() => _MenuItemReviewsScreenState();
}

class _MenuItemReviewsScreenState extends State<MenuItemReviewsScreen> {
  List<MenuItemReviewModel> _reviews = [];
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
      final reviews =
          await RatingRepository.instance.getMenuItemReviews(widget.menuItemId);
      // En yeni önce
      reviews.sort((a, b) => b.ratingId.compareTo(a.ratingId));
      if (mounted) {
        setState(() {
          _reviews = reviews;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'Değerlendirmeler yüklenemedi.';
          _loading = false;
        });
      }
    }
  }

  double get _average => _reviews.isEmpty
      ? 0
      : _reviews.map((r) => r.score).reduce((a, b) => a + b) / _reviews.length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bgColor,
      appBar: AppBar(
        backgroundColor: context.bgColor,
        elevation: 0,
        title: Text('Değerlendirmeler', style: AppTextStyles.titleMedium),
        iconTheme: IconThemeData(color: context.textPrimaryColor),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        color: AppColors.primary,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.primary));
    }
    if (_error != null) {
      return _centered(Icons.cloud_off_rounded, _error!,
          OutlinedButton(onPressed: _load, child: const Text('Tekrar Dene')));
    }
    if (_reviews.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 120),
          _centered(Icons.reviews_outlined,
              'Bu ürüne henüz değerlendirme yapılmamış.', null),
        ],
      );
    }
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        // Özet
        Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: context.surfaceColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.dividerColor),
          ),
          child: Row(
            children: [
              Text(_average.toStringAsFixed(1),
                  style: AppTextStyles.headlineLarge
                      .copyWith(color: AppColors.star)),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.menuItemName, style: AppTextStyles.titleSmall),
                  const SizedBox(height: 2),
                  Text('${_reviews.length} değerlendirme',
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.textSecondary)),
                ],
              ),
            ],
          ),
        ),
        ..._reviews.map((r) => _ReviewCard(review: r)),
      ],
    );
  }

  Widget _centered(IconData icon, String msg, Widget? action) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 52, color: AppColors.textDisabled),
            const SizedBox(height: 16),
            Text(msg,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium
                    .copyWith(color: AppColors.textSecondary)),
            if (action != null) ...[const SizedBox(height: 20), action],
          ],
        ),
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.review});
  final MenuItemReviewModel review;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: review.mine ? AppColors.primary : context.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                child: const Icon(Icons.person_rounded,
                    size: 16, color: AppColors.primary),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  review.mine ? '${review.reviewerName} (Sen)' : review.reviewerName,
                  style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: context.textPrimaryColor),
                ),
              ),
              RatingBarIndicator(
                rating: review.score,
                itemSize: 14,
                itemBuilder: (_, __) =>
                    const Icon(Icons.star_rounded, color: AppColors.star),
              ),
              const SizedBox(width: 4),
              Text(review.score.toStringAsFixed(1),
                  style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.star, fontWeight: FontWeight.w700)),
            ],
          ),
          if (review.comment != null && review.comment!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('"${review.comment}"',
                style: AppTextStyles.bodySmall
                    .copyWith(fontStyle: FontStyle.italic)),
          ],
        ],
      ),
    );
  }
}

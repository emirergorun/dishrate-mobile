import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';

import '../../../core/network/rating_repository.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_metrics.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/models/menu_item_review_model.dart';
import '../../../shared/widgets/rating_stars.dart';
import '../../../shared/widgets/review_actions.dart';
import '../../../shared/widgets/review_tile.dart';
import '../../../shared/widgets/skeleton.dart';
import '../../../shared/widgets/state_message.dart';

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

  static const _pad = EdgeInsets.fromLTRB(
      AppSpace.screen, AppSpace.xs, AppSpace.screen, AppSpace.xxl);

  @override
  void initState() {
    super.initState();
    _load();
  }

  /// [silent]: bildirme/engelleme sonrası liste yerinde tazelenir, iskelet
  /// yanıp sönmez.
  Future<void> _load({bool silent = false}) async {
    setState(() {
      if (!silent) _loading = true;
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
          _error = 'Değerlendirmeler yüklenemedi';
          _loading = false;
        });
      }
    }
  }

  Future<void> _openActions(MenuItemReviewModel review) async {
    final result = await ReviewActions.show(context, review);
    if (result == null || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(result.message),
      behavior: SnackBarBehavior.floating,
      // Yanlış dokunuş için (karar 25 Eylül).
      action: SnackBarAction(
        label: 'Geri al',
        onPressed: () async {
          try {
            await result.undo();
          } catch (_) {}
          if (mounted) _load(silent: true);
        },
      ),
    ));
    // Bildirilen ya da engellenenin yorumları sunucudan artık gelmez.
    _load(silent: true);
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
        leading: IconButton(
          icon: const Icon(TablerIcons.chevron_left),
          tooltip: 'Geri',
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Değerlendirmeler',
          style: AppTextStyles.titleMedium
              .copyWith(color: context.textPrimaryColor),
        ),
        titleSpacing: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        color: AppColors.primary,
        backgroundColor: context.surfaceColor,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    final title = Text(
      widget.menuItemName,
      style:
          AppTextStyles.headlineLarge.copyWith(color: context.textPrimaryColor),
    );

    if (_loading) {
      return ListView(
        padding: _pad,
        children: [
          title,
          const SizedBox(height: AppSpace.lg),
          const SkeletonPulse(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBox(width: 140, height: 34),
                SizedBox(height: AppSpace.xxl),
                SkeletonRows(count: 3, leadingSize: 32),
              ],
            ),
          ),
        ],
      );
    }

    if (_error != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: _pad,
        children: [
          title,
          const SizedBox(height: AppSpace.xl),
          StateMessage(
            title: _error!,
            message: 'Bağlantını kontrol edip tekrar dene.',
            actionLabel: 'Tekrar dene',
            onAction: _load,
          ),
        ],
      );
    }

    if (_reviews.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: _pad,
        children: [
          title,
          const SizedBox(height: AppSpace.xl),
          const StateMessage(
            title: 'Henüz değerlendirme yok',
            message: 'Bu yemeği ilk puanlayan sen ol.',
          ),
        ],
      );
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: _pad,
      children: [
        title,
        const SizedBox(height: AppSpace.lg),

        // Özet — kenarlıklı kart değil, düz satır. Ortalama rakamı metin
        // renginde; sarı yalnızca yıldızda.
        Row(
          children: [
            Text(
              _average.toStringAsFixed(1),
              style: AppTextStyles.ratingLarge
                  .copyWith(color: context.textPrimaryColor),
            ),
            const SizedBox(width: AppSpace.md),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                StarRow(rating: _average, size: 14),
                const SizedBox(height: 4),
                Text(
                  '${_reviews.length} değerlendirme',
                  style: AppTextStyles.caption
                      .copyWith(color: context.textSecondaryColor),
                ),
              ],
            ),
          ],
        ),

        const SizedBox(height: AppSpace.xxl),

        for (var i = 0; i < _reviews.length; i++) ...[
          if (i > 0)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpace.screen),
              child: Divider(height: 1),
            ),
          ReviewTile(
            review: _reviews[i],
            onMore: () => _openActions(_reviews[i]),
          ),
        ],
      ],
    );
  }
}

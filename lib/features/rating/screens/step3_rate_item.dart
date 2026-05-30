import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/rating_repository.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/models/menu_item_model.dart';
import '../../../shared/models/rating_request_model.dart';
import '../providers/rating_flow_provider.dart';

class Step3RateItem extends ConsumerStatefulWidget {
  const Step3RateItem({super.key, required this.onSuccess});

  final VoidCallback onSuccess;

  @override
  ConsumerState<Step3RateItem> createState() => _Step3RateItemState();
}

class _Step3RateItemState extends ConsumerState<Step3RateItem> {
  final _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final state = ref.read(ratingFlowProvider);

    if (state.score == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen bir puan ver.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    ref.read(ratingFlowProvider.notifier).setLoading(true);

    try {
      await RatingRepository.instance.submitRating(
        RatingRequestModel(
          userId: 1, // TODO: gerçek kullanıcı ID'si (auth sonrası)
          menuItemId: state.selectedMenuItem!.menuItemId,
          score: state.score,
          comment: _commentController.text.trim(),
        ),
      );
      if (mounted) widget.onSuccess();
    } catch (e) {
      ref.read(ratingFlowProvider.notifier).showError(
            'Puan kaydedilemedi. Lütfen tekrar dene.',
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(ratingFlowProvider);
    final item = state.selectedMenuItem!;
    final restaurant = state.selectedRestaurant!;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Başlık ────────────────────────────────────────────────────
          Text('Nasıldı?', style: AppTextStyles.headlineLarge),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.storefront_rounded,
                  color: AppColors.primary, size: 14),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  '${restaurant.name} · ${item.name}',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.primary),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          const SizedBox(height: 32),

          // ── Ürün Görseli ──────────────────────────────────────────────
          _ItemPreview(item: item),

          const SizedBox(height: 32),

          // ── Puan Alanı ────────────────────────────────────────────────
          Center(
            child: Column(
              children: [
                Text(
                  state.score == 0
                      ? '—'
                      : state.score.toStringAsFixed(1),
                  style: AppTextStyles.ratingLarge.copyWith(fontSize: 52),
                ),
                const SizedBox(height: 12),
                RatingBar.builder(
                  initialRating: state.score,
                  minRating: 0.5,
                  allowHalfRating: true,
                  itemCount: 5,
                  itemSize: 42,
                  unratedColor: AppColors.surface,
                  itemBuilder: (_, __) => const Icon(
                    Icons.star_rounded,
                    color: AppColors.star,
                  ),
                  onRatingUpdate: (rating) {
                    ref
                        .read(ratingFlowProvider.notifier)
                        .updateScore(rating);
                  },
                ),
                const SizedBox(height: 8),
                Text(
                  _scoreLabel(state.score),
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // ── Yorum Alanı ───────────────────────────────────────────────
          Text('Yorum (opsiyonel)', style: AppTextStyles.titleSmall),
          const SizedBox(height: 8),
          TextField(
            controller: _commentController,
            maxLines: 4,
            maxLength: 500,
            style: AppTextStyles.bodyMedium,
            decoration: const InputDecoration(
              hintText: 'Bu yemek hakkında ne düşünüyorsun?',
              alignLabelWithHint: true,
              counterStyle: TextStyle(color: AppColors.textDisabled),
            ),
            onChanged: (val) =>
                ref.read(ratingFlowProvider.notifier).updateComment(val),
          ),

          const SizedBox(height: 8),

          // ── Hata mesajı ───────────────────────────────────────────────
          if (state.errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                state.errorMessage!,
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.error),
              ),
            ),

          // ── Kaydet Butonu ─────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: state.isLoading ? null : _submit,
              child: state.isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text('Puanı Kaydet'),
            ),
          ),
        ],
      ),
    );
  }

  String _scoreLabel(double score) {
    if (score == 0) return 'Puan seç';
    if (score <= 1.0) return 'Berbat';
    if (score <= 2.0) return 'İdare eder';
    if (score <= 3.0) return 'Fena değil';
    if (score <= 3.5) return 'İyi';
    if (score <= 4.0) return 'Güzel';
    if (score <= 4.5) return 'Harika';
    return 'Mükemmel!';
  }
}

// ── Ürün önizleme ─────────────────────────────────────────────────────────────

class _ItemPreview extends StatelessWidget {
  const _ItemPreview({required this.item});
  final MenuItemModel item;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.hardEdge,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (item.photoUrl != null && item.photoUrl!.isNotEmpty)
            Image.network(
              item.photoUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _placeholder(),
            )
          else
            _placeholder(),
          // Alt gradient + isim
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Color(0xDD0D0D0D), Colors.transparent],
                ),
              ),
              child: Text(item.name, style: AppTextStyles.titleLarge),
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholder() => Container(
        color: AppColors.divider,
        child: const Icon(Icons.restaurant_rounded,
            color: AppColors.textDisabled, size: 48),
      );
}

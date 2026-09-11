import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import '../../../core/auth/auth_provider.dart';
import '../../../core/network/rating_repository.dart';
import '../../../core/network/wishlist_repository.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_metrics.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/models/rating_request_model.dart';
import '../../../shared/widgets/dish_photo.dart';
import '../../../shared/widgets/rating_stars.dart';
import '../providers/rating_flow_provider.dart';

/// "Kaydedildi" görünümünün panelde kalma süresi. Panel hemen kapanınca puanın
/// gidip gitmediği ancak alttan çıkan bildirimden anlaşılıyordu; kısa bir onay
/// anı döngüye "tamamlandı" hissini veriyor, uzun olursa da akışı yavaşlatıyor.
const Duration _savedHold = Duration(milliseconds: 1100);

/// Giriş yıldızlarının boyutu. Parmakla yarım yıldız seçmek için her yıldızın
/// yarısı en az ~22 pt olmalı.
const double _starSize = 46;

class Step3RateItem extends ConsumerStatefulWidget {
  const Step3RateItem({super.key, required this.onSuccess});

  final VoidCallback onSuccess;

  @override
  ConsumerState<Step3RateItem> createState() => _Step3RateItemState();
}

class _Step3RateItemState extends ConsumerState<Step3RateItem> {
  final _commentController = TextEditingController();

  /// Puan seçmeden kaydete basıldı mı — uyarı puan alanının kendisinde.
  bool _scoreMissing = false;
  bool _saved = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final state = ref.read(ratingFlowProvider);

    if (state.score == 0) {
      // Kırmızı bildirim yerine yıldızların altındaki satır uyarıyor: sorun
      // tam orada, göz de oraya gitsin.
      HapticFeedback.lightImpact();
      setState(() => _scoreMissing = true);
      return;
    }

    final userId = ref.read(currentUserIdProvider);
    if (userId == null) {
      ref.read(ratingFlowProvider.notifier).showError(
            'Oturum bulunamadı. Lütfen tekrar giriş yap.',
          );
      return;
    }

    ref.read(ratingFlowProvider.notifier).setLoading(true);

    try {
      await RatingRepository.instance.submitRating(
        RatingRequestModel(
          userId: userId,
          menuItemId: state.selectedMenuItem!.menuItemId,
          score: state.score,
          comment: _commentController.text.trim(),
        ),
      );
      // Değerlendirilen yemek istek listesindeyse otomatik kaldır
      await WishlistRepository.instance.removeByMenuItemId(
        userId,
        state.selectedMenuItem!.menuItemId,
      );
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      setState(() => _saved = true);
      await Future<void>.delayed(_savedHold);
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
    final item = state.selectedMenuItem;
    final restaurant = state.selectedRestaurant;
    // Kayıttan sonra akış sıfırlanırken panel kapanana kadar bir kare daha
    // çizilebiliyor; seçimler o anda boş.
    if (item == null || restaurant == null) return const SizedBox.shrink();

    // Boş yıldız çerçevesinin rengi — bkz. aşağıdaki RatingBar yorumu.
    final emptyStar = context.starColor.withValues(alpha: 0.55);

    return AnimatedSwitcher(
      duration: AppMotion.base,
      // Varsayılan düzen çocukları ortalanmış bir Stack'e koyuyor; form kendi
      // yüksekliği kadar küçülüp panelin ortasına düşüyordu. Genişletilmiş
      // Stack formu yukarıdan başlatıyor, onay görünümü de ortada kalıyor.
      layoutBuilder: (current, previous) => Stack(
        fit: StackFit.expand,
        children: [...previous, if (current != null) current],
      ),
      child: _saved
          ? _SavedView(
              key: const ValueKey('saved'),
              score: state.score,
              itemName: item.name,
            )
          : SingleChildScrollView(
              key: const ValueKey('form'),
              // Yorum yazarken listeyi aşağı çekmek klavyeyi kapatsın — "Puanı
              // Kaydet"e basmadan klavyeden kurtulmanın başka yolu yoktu.
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(
                  AppSpace.screen, AppSpace.md, AppSpace.screen, AppSpace.xxl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Neyi puanlıyorsun ─────────────────────────────────
                  // Önceden 180 px'lik fotoğraf + yemek adı üç kez yazıyordu ve
                  // "Puanı Kaydet" ekranın altına itiliyordu. Küçük özet yetiyor.
                  Row(
                    children: [
                      DishPhoto(
                        url: item.photoUrl,
                        width: 48,
                        height: 48,
                        radius: AppRadius.sm,
                        iconSize: 18,
                      ),
                      const SizedBox(width: AppSpace.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.titleSmall
                                  .copyWith(color: context.textPrimaryColor),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              restaurant.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.caption
                                  .copyWith(color: context.textSecondaryColor),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: AppSpace.xxl),

                  Text(
                    'Nasıldı?',
                    style: AppTextStyles.displayLarge
                        .copyWith(color: context.textPrimaryColor),
                  ),

                  const SizedBox(height: AppSpace.xl),

                  // ── Puan Alanı ────────────────────────────────────────
                  Center(
                    child: Column(
                      children: [
                        // Boş yıldızlar dolu olanla aynı ikonun soluk hâli
                        // değil, ÇERÇEVELİ yıldız. Koyu temada dolgu rengi
                        // zeminle karıştığı için puanlanmamış yıldızlar
                        // görünmüyordu — kullanıcı orada tıklanacak bir şey
                        // olduğunu anlamıyor.
                        RatingBar(
                          initialRating: state.score,
                          minRating: 0.5,
                          allowHalfRating: true,
                          itemCount: 5,
                          itemSize: _starSize,
                          itemPadding: const EdgeInsets.symmetric(horizontal: 2),
                          glow: false,
                          ratingWidget: RatingWidget(
                            full: const StarGlyph(fill: 1, size: _starSize),
                            half: StarGlyph(
                              fill: 0.5,
                              size: _starSize,
                              emptyColor: emptyStar,
                            ),
                            empty: StarGlyph(
                              fill: 0,
                              size: _starSize,
                              emptyColor: emptyStar,
                            ),
                          ),
                          onRatingUpdate: (rating) {
                            // Her yarım yıldız adımında hafif tık: puan
                            // parmağın altında kalıyor, değişimi hissetmek
                            // bakmaktan hızlı.
                            if (rating != state.score) {
                              HapticFeedback.selectionClick();
                            }
                            if (_scoreMissing) {
                              setState(() => _scoreMissing = false);
                            }
                            ref
                                .read(ratingFlowProvider.notifier)
                                .updateScore(rating);
                          },
                        ),
                        const SizedBox(height: AppSpace.lg),
                        SizedBox(
                          height: 36,
                          child: AnimatedSwitcher(
                            duration: AppMotion.fast,
                            child: _scoreLine(context, state.score),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpace.xxl),

                  // ── Yorum Alanı ───────────────────────────────────────
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        'Yorum',
                        style: AppTextStyles.titleSmall
                            .copyWith(color: context.textPrimaryColor),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'isteğe bağlı',
                        style: AppTextStyles.caption
                            .copyWith(color: context.textTertiaryColor),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpace.sm),
                  TextField(
                    controller: _commentController,
                    minLines: 3,
                    maxLines: 5,
                    maxLength: 500,
                    style: AppTextStyles.bodyMedium,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      hintText: 'Bu yemek hakkında ne düşünüyorsun?',
                      alignLabelWithHint: true,
                    ),
                    onChanged: (val) => ref
                        .read(ratingFlowProvider.notifier)
                        .updateComment(val),
                  ),

                  const SizedBox(height: AppSpace.sm),

                  // ── Hata mesajı ───────────────────────────────────────
                  if (state.errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpace.md),
                      child: Text(
                        state.errorMessage!,
                        style: AppTextStyles.bodyMedium
                            .copyWith(color: context.errorTextColor),
                      ),
                    ),

                  // ── Kaydet Butonu ─────────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: state.isLoading ? null : _submit,
                      child: state.isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: AppColors.onPrimary,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text('Puanı kaydet'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  /// Yıldızların altındaki satır: puan + etiket, ya da ne yapılacağı.
  ///
  /// Önceden puan yokken 52 px'lik sarı bir "—" duruyordu ve ekranda çizgi
  /// gibi okunuyordu.
  Widget _scoreLine(BuildContext context, double score) {
    if (score == 0) {
      return Text(
        _scoreMissing ? 'Kaydetmeden önce bir puan seç' : 'Yıldızlara dokun',
        key: ValueKey('empty-$_scoreMissing'),
        style: AppTextStyles.bodyMedium.copyWith(
          color: _scoreMissing
              ? context.errorTextColor
              : context.textSecondaryColor,
        ),
      );
    }
    return Row(
      key: ValueKey(score),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          score.toStringAsFixed(1),
          style: AppTextStyles.ratingLarge
              .copyWith(fontSize: 28, color: context.textPrimaryColor),
        ),
        const SizedBox(width: 10),
        Text(
          _scoreLabel(score),
          style: AppTextStyles.titleMedium.copyWith(
            fontWeight: FontWeight.w400,
            color: context.textSecondaryColor,
          ),
        ),
      ],
    );
  }

  /// Her yarım yıldızın kendi etiketi var. Önceden 1.5 ile 2 aynı etiketi
  /// alıyordu; yarım yıldız seçen kullanıcı değişikliği yazıda görmüyordu.
  String _scoreLabel(double score) {
    if (score <= 1.0) return 'Berbat';
    if (score <= 1.5) return 'Çok kötü';
    if (score <= 2.0) return 'Kötü';
    if (score <= 2.5) return 'İdare eder';
    if (score <= 3.0) return 'Fena değil';
    if (score <= 3.5) return 'İyi';
    if (score <= 4.0) return 'Çok iyi';
    if (score <= 4.5) return 'Harika';
    return 'Mükemmel';
  }
}

// ── Kaydedildi ────────────────────────────────────────────────────────────────

class _SavedView extends StatelessWidget {
  const _SavedView({
    super.key,
    required this.score,
    required this.itemName,
  });

  final double score;
  final String itemName;

  @override
  Widget build(BuildContext context) {
    final animate = !MediaQuery.disableAnimationsOf(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpace.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: animate ? 0.6 : 1, end: 1),
              duration: const Duration(milliseconds: 380),
              curve: Curves.easeOutBack,
              builder: (_, v, child) => Transform.scale(scale: v, child: child),
              child: Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  TablerIcons.check,
                  size: 30,
                  color: AppColors.onPrimary,
                ),
              ),
            ),
            const SizedBox(height: AppSpace.screen),
            Text(
              'Puanın kaydedildi',
              style: AppTextStyles.headlineMedium
                  .copyWith(color: context.textPrimaryColor),
            ),
            const SizedBox(height: AppSpace.md),
            StarRow(rating: score, size: 18),
            const SizedBox(height: AppSpace.sm),
            Text(
              itemName,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bodyMedium
                  .copyWith(color: context.textSecondaryColor),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:video_player/video_player.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_metrics.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/auth/require_login.dart';
import 'story_widgets.dart';
import '../../core/constants/app_brand.dart';

/// Tanıtımın son adımı (A4): logo animasyonu (pullar üst üste konur, altında
/// "decouva" belirir; 17 Ekim, eski dönen tabakların yerine), "hoş geldin" ve
/// hesap seçenekleri (1.8).
///
/// Giriş ya da kayıt başarılı olunca auth durumu değişir ve uygulamanın kapısı
/// kendiliğinden Keşfet'e geçer. "Giriş yapmadan devam et" misafir olarak
/// açar.
/// İlk metnin (hoş geldin) belirdiği an, saniye. Videoda logo yazısı 2,43
/// sn'de beliriyor.
const double _revealStart = 2.5;

class AccountStep extends StatelessWidget {
  const AccountStep({
    super.key,
    required this.active,
    required this.controller,
    required this.index,
    required this.onExplore,
    required this.video,
  });

  final bool active;
  final PageController controller;
  final int index;
  final VoidCallback onExplore;
  final VideoPlayerController video;

  @override
  Widget build(BuildContext context) {
    return StoryTime(
      active: active,
      stillTime: _revealStart + 0.5 + 0.5,
      builder: (context, t) => AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          final width = MediaQuery.sizeOf(context).width;
          final page =
              controller.hasClients && controller.position.haveDimensions
                  ? controller.page ?? index.toDouble()
                  : controller.initialPage.toDouble();
          final offset = (page - index).clamp(-1.0, 1.0);
          return _content(context, t, offset, width);
        },
      ),
    );
  }

  Widget _content(BuildContext context, double t, double offset, double width) {
    // Metin ve düğmeler sırayla söner-kayarak gelir; videoda "decouva"
    // yazısı belirdikten sonra (2,4 sn).
    Widget reveal(double at, Widget child) {
      final start = _revealStart + at - 0.9;
      final p = phase(t, start, start + 0.5);
      return Opacity(
        opacity: p,
        child:
            Transform.translate(offset: Offset(0, (1 - p) * 16), child: child),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.screen),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Transform.translate(
              offset: Offset(offset * width * 0.45, 0),
              child: Opacity(
                opacity: (1 - offset.abs() * 1.1).clamp(0.0, 1.0),
                child: ExcludeSemantics(
                  child: Center(
                    child: OpeningVideo(controller: video, active: active),
                  ),
                ),
              ),
            ),
          ),
          reveal(
            0.9,
            Text(
              '${AppBrand.name}’ya hoş geldin!',
              textAlign: TextAlign.center,
              style: OnboardingText.headline.copyWith(fontSize: 30),
            ),
          ),
          // Cümle aşağıda, "Kayıt ol"a yakın: iki aralık ("cümle → Kayıt ol"
          // ve "Zaten hesabın var mı? → Giriş yap") eşit (Emir, 29 Eylül).
          const SizedBox(height: AppSpace.xl),
          reveal(
            1.0,
            Text(
              'Yemekleri keşfetmek ve günlüğüne eklemek için kaydol.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyLarge.copyWith(color: Colors.white),
            ),
          ),
          const SizedBox(height: AppSpace.sm),
          reveal(
            1.15,
            ElevatedButton(
              onPressed: () => openRegister(context),
              // Turuncu zemin, beyaz yazı (Emir'in kararı, 27 Eylül); temanın
              // koyu yazısı burada ezilir.
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Kayıt ol'),
            ),
          ),
          const SizedBox(height: AppSpace.lg),
          reveal(
            1.25,
            Text(
              'Zaten hesabın var mı?',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium
                  .copyWith(color: Colors.white.withValues(alpha: 0.7)),
            ),
          ),
          const SizedBox(height: AppSpace.sm),
          reveal(
            1.3,
            ElevatedButton(
              onPressed: () => openLogin(context),
              // Ölçü, köşe ve yazı temadan; beyaz zemin, turuncu yazı.
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.primary,
              ),
              child: const Text('Giriş yap'),
            ),
          ),
          const SizedBox(height: AppSpace.xs),
          reveal(
            1.4,
            Center(
              child: TextButton(
                onPressed: onExplore,
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  minimumSize: const Size(0, 48),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Giriş yapmadan devam et'),
                    SizedBox(width: 6),
                    Icon(TablerIcons.arrow_right, size: 18),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpace.sm),
        ],
      ),
    );
  }
}

/// A4'ün logo animasyonu (`assets/brand/video/opening.mp4`, logo paketinin
/// `decouva-acilis.mp4`'ü; 1080×1920, 4,4 sn, sessiz).
///
/// Sayfa etkin olunca baştan bir kez oynar ve son karede (logo + yazı) durur;
/// sayfadan çıkınca durup başa sarar, geri gelindiğinde baştan oynar (eski
/// dönen tabaklar gibi). "Hareketi azalt" açıksa yalnız son kare görünür.
class OpeningVideo extends StatefulWidget {
  const OpeningVideo(
      {super.key, required this.controller, required this.active});

  final VideoPlayerController controller;
  final bool active;

  static const asset = 'assets/brand/video/opening.mp4';

  /// Sessiz video çalarken kullanıcının dinlediği müzik durmasın.
  static VideoPlayerController createController() =>
      VideoPlayerController.asset(
        asset,
        videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
      );

  /// Videonun gösterilen bölgesi (piksel). Pullar kenarlardan uçarak geldiği
  /// için genişliğin tamamı; dikeyde bütün karelerdeki hareketin alanı
  /// (y 375–1341) ve biraz pay. Gerisi boş zemin.
  static const double _videoW = 1080, _videoH = 1920;
  static const double _cropTop = 360, _cropBottom = 1380;

  // Videonun zemini dosyada #0B0B0B ama iOS onu uygulamanın zeminiyle aynı
  // tonda (#0D0D0D) çiziyor (simülatörde ölçüldü, 17 Ekim). Renk düzeltmesi
  // eklemeyin: denendi, kırpılan alan 2 ton açık bir kutu olarak görünüyordu.

  @override
  State<OpeningVideo> createState() => _OpeningVideoState();
}

class _OpeningVideoState extends State<OpeningVideo> {
  VideoPlayerController get _c => widget.controller;

  @override
  void initState() {
    super.initState();
    _c.addListener(_onReady);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(OpeningVideo old) {
    super.didUpdateWidget(old);
    if (old.active != widget.active) _sync();
  }

  @override
  void dispose() {
    _c.removeListener(_onReady);
    super.dispose();
  }

  bool _wasReady = false;

  /// Video sayfa etkinleştikten sonra hazır olursa oynatmayı o an başlat.
  void _onReady() {
    final ready = _c.value.isInitialized;
    if (ready && !_wasReady) {
      _wasReady = true;
      _sync();
      if (mounted) setState(() {});
    }
  }

  void _sync() {
    if (!_c.value.isInitialized) return;
    _c.setVolume(0);
    if (MediaQuery.disableAnimationsOf(context)) {
      // Son kare: tam sona sarınca bazı cihazlarda boş kare geliyor.
      _c.pause();
      _c.seekTo(_c.value.duration - const Duration(milliseconds: 30));
      return;
    }
    if (widget.active) {
      _c.seekTo(Duration.zero).then((_) => _c.play());
    } else {
      _c.pause();
      _c.seekTo(Duration.zero);
    }
  }

  @override
  Widget build(BuildContext context) {
    const cropH = OpeningVideo._cropBottom - OpeningVideo._cropTop;
    // Align'ın hizası: videonun _cropTop'u kutunun üstüne denk gelsin.
    const alignY =
        2 * OpeningVideo._cropTop / (OpeningVideo._videoH - cropH) - 1;
    return AspectRatio(
      aspectRatio: OpeningVideo._videoW / cropH,
      child: !_c.value.isInitialized
          ? const SizedBox.shrink()
          : ClipRect(
              child: FittedBox(
                fit: BoxFit.contain,
                child: SizedBox(
                  width: OpeningVideo._videoW,
                  height: cropH,
                  child: OverflowBox(
                    maxHeight: OpeningVideo._videoH,
                    alignment: const Alignment(0, alignY),
                    child: SizedBox(
                      width: OpeningVideo._videoW,
                      height: OpeningVideo._videoH,
                      child: VideoPlayer(_c),
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}

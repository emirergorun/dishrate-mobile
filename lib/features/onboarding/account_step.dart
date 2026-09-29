import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_metrics.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/auth/require_login.dart';
import '../../shared/widgets/dishrate_logo.dart';
import 'story_widgets.dart';

/// Tanıtımın son adımı (A4): siyah zeminde turuncu `d`, etrafında dönen
/// yemek tabakları, "hoş geldin" ve hesap seçenekleri (1.8).
///
/// Giriş ya da kayıt başarılı olunca auth durumu değişir ve uygulamanın kapısı
/// kendiliğinden Keşfet'e geçer. "Giriş yapmadan devam et" misafir olarak
/// açar.
class AccountStep extends StatelessWidget {
  const AccountStep({
    super.key,
    required this.active,
    required this.controller,
    required this.index,
    required this.onExplore,
  });

  final bool active;
  final PageController controller;
  final int index;
  final VoidCallback onExplore;

  @override
  Widget build(BuildContext context) {
    return StoryTime(
      active: active,
      stillTime: 3,
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
    // Metin ve düğmeler sırayla söner-kayarak gelir.
    Widget reveal(double at, Widget child) {
      final p = phase(t, at, at + 0.5);
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
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: SizedBox.square(
                        dimension: _Orbit.size,
                        child: _Orbit(t: t),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          reveal(
            0.9,
            Text(
              'Dishrate’e hoş geldin!',
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

/// Ortada turuncu `d` ve ışığı, kesik çizgili yörünge, dönen dört tabak.
class _Orbit extends StatelessWidget {
  const _Orbit({required this.t});
  final double t;

  static const size = 400.0;
  static const _ring = 148.0;

  /// Bir tam tur süresi (sn).
  static const _period = 40.0;

  // (yemek, başlangıç açısı °, çap, yörüngeden uzaklık)
  static const _plates = [
    ('burger', -95.0, 96.0, 146.0),
    ('pizza', -12.0, 88.0, 156.0),
    ('durum', 82.0, 90.0, 140.0),
    ('baklava', 168.0, 82.0, 152.0),
  ];

  @override
  Widget build(BuildContext context) {
    const c = size / 2;
    // `d` ekranın ortasına yakın büyük başlar, küçülerek yerine oturur.
    final settle = phase(t, 0, 0.9, Curves.easeInOutCubic);
    final markScale = mix(1.8, 1, settle);
    final markDy = mix(110, 0, settle);
    final glow = phase(t, 0.4, 1.1);
    final ring = phase(t, 0.55, 1.3, Curves.easeInOut);
    final spin = t * 2 * math.pi / _period;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Işık
        Positioned.fill(
          child: Opacity(
            opacity: glow,
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.30),
                    AppColors.primary.withValues(alpha: 0.0),
                  ],
                  stops: const [0, 0.55],
                ),
              ),
            ),
          ),
        ),
        // Yörünge
        Positioned.fill(
          child:
              CustomPaint(painter: _RingPainter(progress: ring, radius: _ring)),
        ),
        // Tabaklar
        for (var i = 0; i < _plates.length; i++)
          () {
            final p = _plates[i];
            final a = p.$2 * math.pi / 180 + spin;
            final pop =
                phase(t, 0.75 + i * 0.12, 1.35 + i * 0.12, Curves.elasticOut);
            final d = p.$3;
            return Positioned(
              left: c + math.cos(a) * p.$4 - d / 2,
              top: c + math.sin(a) * p.$4 - d / 2,
              child: Transform.scale(
                scale: pop,
                child: _Plate(image: OnboardingAssets.plate(p.$1), size: d),
              ),
            );
          }(),
        // İşaret
        Center(
          child: Transform.translate(
            offset: Offset(0, markDy),
            child: Transform.scale(
              scale: markScale,
              child: const DishrateMark(size: 112),
            ),
          ),
        ),
      ],
    );
  }
}

class _Plate extends StatelessWidget {
  const _Plate({required this.image, required this.size});
  final String image;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipOval(
        child: Image.asset(image, fit: BoxFit.cover, cacheWidth: 240),
      ),
    );
  }
}

/// Kesik çizgili yörünge halkası; [progress] 0→1 boyunca saat yönünde çizilir.
class _RingPainter extends CustomPainter {
  _RingPainter({required this.progress, required this.radius});
  final double progress;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    final center = size.center(Offset.zero);
    // Dışta çok soluk düz halka
    canvas.drawCircle(
      center,
      radius + 30,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = Colors.white.withValues(alpha: 0.05 * progress),
    );
    final dash = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3
      ..strokeCap = StrokeCap.round
      ..color = Colors.white.withValues(alpha: 0.28);
    const count = 56;
    const sweep = 2 * math.pi / count;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final visible = (count * progress).floor();
    for (var i = 0; i < visible; i++) {
      canvas.drawArc(rect, -math.pi / 2 + i * sweep, sweep * 0.55, false, dash);
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.radius != radius;
}

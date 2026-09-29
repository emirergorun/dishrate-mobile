import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_fonts.dart';
import '../../core/theme/app_metrics.dart';

/// Tanıtım sayfalarının ortak parçaları (1.8).
///
/// Her sayfa bir "hikâye": sayfa açıkken geçen süreye (saniye) göre çizilen,
/// döngüyle oynayan küçük bir sahne. Tasarım Emir'in videolarından
/// (`Onboarding Görselleri/A1–A4`) uyarlandı.

/// Tanıtım fotoğrafları. Unsplash License (atıf zorunlu değil); kaynaklar
/// `Onboarding Görselleri/LISANS.md`'de.
abstract final class OnboardingAssets {
  static const _dir = 'assets/onboarding';

  /// A1 kartları (600×672).
  static String card(String dish) => '$_dir/card/$dish.jpg';

  /// Yuvarlak tabaklar ve küçük satır fotoğrafları (480×480).
  static String plate(String dish) => '$_dir/plate/$dish.jpg';

  /// A2'nin büyük kartı (900×667).
  static const burgerWide = '$_dir/burger_wide.jpg';

  static const dishes = ['burger', 'pizza', 'durum', 'baklava'];

  /// A2 listesindeki diğer iki burger (yalnız tabak boyu).
  static const otherBurgers = ['cheeseburger', 'onion_burger'];

  /// Sayfalar açılırken fotoğraflar sonradan belirmesin diye tanıtım
  /// başlarken hepsi çözülür.
  static void precache(BuildContext context) {
    for (final d in dishes) {
      precacheImage(AssetImage(card(d)), context);
      precacheImage(AssetImage(plate(d)), context);
    }
    for (final d in otherBurgers) {
      precacheImage(AssetImage(plate(d)), context);
    }
    precacheImage(const AssetImage(burgerWide), context);
  }
}

/// Tanıtımın büyük başlığı. Uygulamanın başlık skalası bilerek dışında:
/// videolardaki reklam dili, kalın ve iri (Emir'in kararı, 26 Eylül).
abstract final class OnboardingText {
  static const headline = TextStyle(
    fontFamily: AppFonts.active,
    fontSize: 34,
    // Urbanist'in Bold'u videodaki Poppins Bold'dan belirgin ince; Black
    // aynı ağırlığı veriyor.
    fontWeight: FontWeight.w900,
    height: 1.12,
    letterSpacing: -0.4,
    color: AppColors.textPrimary,
  );

  static final headlineAccent = headline.copyWith(color: AppColors.primary);
}

/// [t] saniyesinin [begin]–[end] aralığını 0→1'e çevirir, [curve] uygular.
double phase(double t, double begin, double end,
    [Curve curve = Curves.easeOutCubic]) {
  if (end <= begin) return t >= end ? 1 : 0;
  final v = ((t - begin) / (end - begin)).clamp(0.0, 1.0);
  return curve.transform(v);
}

/// İki değer arasında [t] (0→1) oranında.
double mix(double a, double b, double t) => a + (b - a) * t;

/// Sayfa etkinken geçen süreyi (saniye) [builder]'a verir.
///
/// Sayfa etkin olunca sıfırdan başlar, etkinliğini yitirince durup başa
/// sarılır: geri gelindiğinde hikâye baştan oynar. "Hareketi azalt" açıksa
/// zaman [stillTime]'da durur (hikâyenin son karesi).
class StoryTime extends StatefulWidget {
  const StoryTime({
    super.key,
    required this.active,
    required this.stillTime,
    required this.builder,
  });

  final bool active;
  final double stillTime;
  final Widget Function(BuildContext context, double seconds) builder;

  @override
  State<StoryTime> createState() => _StoryTimeState();
}

class _StoryTimeState extends State<StoryTime>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker = createTicker((elapsed) {
    setState(() => _seconds = elapsed.inMicroseconds / 1e6);
  });
  double _seconds = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(StoryTime old) {
    super.didUpdateWidget(old);
    if (old.active != widget.active) _sync();
  }

  bool get _still => MediaQuery.disableAnimationsOf(context);

  void _sync() {
    if (widget.active && !_still) {
      if (!_ticker.isActive) _ticker.start();
    } else {
      if (_ticker.isActive) _ticker.stop();
      _seconds = 0;
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final seconds = _still ? widget.stillTime : _seconds;
    return widget.builder(context, seconds);
  }
}

/// Değişen turuncu kelime: eskisi yukarı kayıp söner, yenisi alttan gelir.
///
/// Kelimenin kapladığı genişlik yumuşakça değişir; yanındaki sabit metin
/// ("nerede?") solmaz, yalnızca yana kayar. Giden kelime genişliğe
/// katılmıyor (Positioned); yoksa geçiş bitince yan metin bir kez daha
/// zıplıyordu.
class SwapWord extends StatelessWidget {
  const SwapWord({super.key, required this.text, required this.style});

  final String text;
  final TextStyle style;

  static const duration = Duration(milliseconds: 420);

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: duration,
      curve: Curves.easeInOutCubic,
      alignment: Alignment.centerLeft,
      clipBehavior: Clip.none,
      // Kelime satırının içinde kayar; yukarı çıkan kelime üst satırın
      // üstüne binmesin. Yalnız dikeyde kırpılır: kısa kelimeye geçerken
      // giden uzun kelimenin sağı kesilmesin.
      child: ClipRect(
        clipper: const _LineClipper(),
        child: AnimatedSwitcher(
          duration: duration,
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          layoutBuilder: (current, previous) => Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.centerLeft,
            children: [
              for (final p in previous) Positioned(left: 0, top: 0, child: p),
              if (current != null) current,
            ],
          ),
          transitionBuilder: (child, animation) {
            final incoming = child.key == ValueKey(text);
            final slide = Tween(
              begin: incoming ? const Offset(0, 0.55) : const Offset(0, -0.55),
              end: Offset.zero,
            ).animate(animation);
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(position: slide, child: child),
            );
          },
          child: Text(text, key: ValueKey(text), style: style),
        ),
      ),
    );
  }
}

class _LineClipper extends CustomClipper<Rect> {
  const _LineClipper();

  // Altta satır yüksekliğinin %30'u kadar pay: g, ğ, y, ş gibi harflerin
  // alt uzantısı satır kutusundan taşıyor, kesilmesin.
  @override
  Rect getClip(Size size) =>
      Rect.fromLTRB(-size.width, 0, size.width * 3, size.height * 1.3);

  @override
  bool shouldReclip(_LineClipper oldClipper) => false;
}

/// Parmak dokunuşu: [p] 0→1 boyunca büyüyüp sönen yarı saydam halka.
class TapRipple extends StatelessWidget {
  const TapRipple({super.key, required this.p, this.size = 44});

  final double p;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (p <= 0 || p >= 1) return SizedBox(width: size, height: size);
    // Önce belirir, sonra büyüyerek söner.
    final opacity = p < 0.25 ? p / 0.25 : 1 - (p - 0.25) / 0.75;
    return SizedBox(
      width: size,
      height: size,
      child: Transform.scale(
        scale: 0.6 + 0.6 * Curves.easeOut.transform(p),
        child: Opacity(
          opacity: opacity.clamp(0.0, 1.0) * 0.9,
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.28),
              border: Border.all(
                  color: Colors.white.withValues(alpha: 0.6), width: 1.5),
            ),
          ),
        ),
      ),
    );
  }
}

/// Sayfa kalıbı: üstte sahne, altında sola yaslı başlık.
///
/// Sayfalar kaydırılırken sahne sayfadan yavaş kayar ve kenara yaklaştıkça
/// söner (derinlik hissi); başlık biraz daha az kayar. [controller] sayfanın
/// o anki konumunu verir.
class StoryPageLayout extends StatelessWidget {
  const StoryPageLayout({
    super.key,
    required this.controller,
    required this.index,
    required this.scene,
    required this.sceneSize,
    required this.headline,
  });

  final PageController controller;
  final int index;
  final Widget scene;

  /// Sahnenin tasarım ölçüsü. Küçük ekranda ya da büyük yazıda sahne
  /// orantılı küçülür, taşmaz.
  final Size sceneSize;
  final Widget headline;

  /// Başlık ile ekranın altı arası: boşluk + düğme + alt boşluk.
  static const double buttonArea = 28 + 52 + AppSpace.lg;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final width = MediaQuery.sizeOf(context).width;
        final page = controller.hasClients && controller.position.haveDimensions
            ? controller.page ?? index.toDouble()
            : controller.initialPage.toDouble();
        final offset = (page - index).clamp(-1.0, 1.0);
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
                    // Sahne ekran okuyucuya bir şey anlatmıyor; başlık anlatıyor.
                    child: ExcludeSemantics(
                      child: Center(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          // Sahne bir çizim: içindeki yazılar sistem yazı
                          // boyutuyla büyürse sabit ölçülü kartlardan taşıyor.
                          // Sahne zaten ekrana göre ölçekleniyor; başlık ve
                          // düğmeler sistem boyutunu izlemeye devam ediyor.
                          child: MediaQuery.withNoTextScaling(
                            child: SizedBox.fromSize(
                                size: sceneSize, child: scene),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpace.xl),
              Transform.translate(
                offset: Offset(offset * width * 0.2, 0),
                child: Opacity(
                  opacity: (1 - offset.abs() * 1.4).clamp(0.0, 1.0),
                  child: headline,
                ),
              ),
              // Ortak "Devam et" düğmesinin yeri (OnboardingScreen çiziyor).
              const SizedBox(height: buttonArea),
            ],
          ),
        );
      },
    );
  }
}

/// Başlık: beyaz satırlar + turuncu değişen kelime. Ekran okuyucu için tek
/// cümle olarak okunur ([semanticLabel]).
class StoryHeadline extends StatelessWidget {
  const StoryHeadline({
    super.key,
    required this.semanticLabel,
    required this.lines,
  });

  final String semanticLabel;
  final List<Widget> lines;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      label: semanticLabel,
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final line in lines)
            // %130 yazıda uzun satır ekrana sığmazsa satır küçülür, kırılmaz.
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: line,
            ),
        ],
      ),
    );
  }
}

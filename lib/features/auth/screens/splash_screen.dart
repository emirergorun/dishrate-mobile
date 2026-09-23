import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_metrics.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/dishrate_logo.dart';

/// Açılış ekranındaki logonun genişliği. Sistem açılış ekranındaki logoyla
/// aynı: ikisi arasında logo büyüyüp küçülmesin. `LaunchImage` 300 pt ama
/// kenarlarında boşluk var; simülatörde ölçülen logo genişliği 278 pt.
/// Giriş ekranı da logosunu bu boyuttan başlatıp yerine kaydırıyor.
const double splashLogoWidth = 278;

/// Uygulama açılışında gösterilen yükleme ekranı.
/// AuthProvider token kontrolü yaparken görünür.
///
/// Sistem açılış karesi turuncudur ve temadan bağımsızdır: o kareyi iOS,
/// uygulamanın kodu çalışmadan çiziyor, kullanıcının tema tercihini bilemiyor.
/// Bu ekran da aynı turuncu kareyle başlar (aynı logo, aynı ölçü, aynı yer),
/// sonra temanın rengine geçer. Böylece sistemden uygulamaya geçiş görünmez ve
/// hiçbir açılışta ters temada kare kalmaz (karar 23 Eylül).
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, this.onRetry});

  /// Verilirse sunucuya ulaşılamamıştır: gösterge yerine mesaj ve
  /// "Tekrar dene" çıkar. Logo yerinden oynamaz.
  final VoidCallback? onRetry;

  /// Turuncu karenin ekranda tutulduğu süre.
  static const Duration brandHold = Duration(milliseconds: 220);

  /// Turuncudan temaya geçiş.
  static const Duration brandFade = Duration(milliseconds: 320);

  /// Açılış ekranının en az görüneceği süre; geçiş yarıda kesilip ekran
  /// turuncudan doğrudan ana ekrana zıplamasın diye `main.dart` bunu bekler.
  static const Duration introDuration = Duration(milliseconds: 600);

  /// Açılış ekranı bu oturumda gösterildi mi?
  ///
  /// Giriş ekranı logosunu ancak buradan geldiyse ortadan kaydırıyor. Önceden
  /// giriş ekranının kendi "bir kez oynat" bayrağı vardı; ekran yeniden
  /// kurulursa (auth durumu iki kez değişirse, sıcak yenilemede) animasyon
  /// sessizce atlanıyordu.
  static bool wasShown = false;

  /// Turuncu kare bu oturumda bir kez oynar. Ekran yeniden kurulursa (ör.
  /// "Tekrar dene" sonrası) baştan turuncuya dönmez.
  static bool brandShown = false;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fade;
  late final Animation<double> _t;

  @override
  void initState() {
    super.initState();
    _fade = AnimationController(vsync: this, duration: SplashScreen.brandFade);
    _t = CurvedAnimation(parent: _fade, curve: Curves.easeInOut);
    if (SplashScreen.brandShown) {
      _fade.value = 1;
      return;
    }
    SplashScreen.brandShown = true;
    Future.delayed(SplashScreen.brandHold, () {
      if (mounted) _fade.forward();
    });
  }

  @override
  void dispose() {
    _fade.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SplashScreen.wasShown = true;
    return AnimatedBuilder(
      animation: _t,
      builder: (context, _) {
        final t = _t.value;
        return Scaffold(
          backgroundColor: Color.lerp(AppColors.primary, context.bgColor, t),
          body: Stack(
            alignment: Alignment.center,
            children: [
              // İki logo üst üste: turuncu zemindeki beyaz sürüm sönerken
              // temanın sürümü yanıyor. Dosyalarda logo aynı yerde olduğu için
              // geçişte kaymıyor.
              if (t < 1)
                Opacity(
                  opacity: 1 - t,
                  child: const DishrateWordmark(
                      width: splashLogoWidth, onBrand: true),
                ),
              if (t > 0)
                Opacity(
                  opacity: t,
                  child: const DishrateWordmark(width: splashLogoWidth),
                ),
              // Gösterge ve hata mesajı turuncu karede görünmez; tema geldikçe
              // birlikte beliriyor.
              Align(
                alignment: const Alignment(0, 0.35),
                child: Opacity(opacity: t, child: _belowLogo(context)),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _belowLogo(BuildContext context) {
    if (widget.onRetry == null) {
      return const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(
          color: AppColors.primary,
          strokeWidth: 2.5,
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.xxl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Sunucuya ulaşılamadı',
            style: AppTextStyles.titleMedium
                .copyWith(color: context.textPrimaryColor),
          ),
          const SizedBox(height: AppSpace.xs),
          Text(
            'Bağlantını kontrol edip tekrar dene.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium
                .copyWith(color: context.textSecondaryColor),
          ),
          const SizedBox(height: AppSpace.sm),
          TextButton(
            onPressed: widget.onRetry,
            child: const Text('Tekrar dene'),
          ),
        ],
      ),
    );
  }
}

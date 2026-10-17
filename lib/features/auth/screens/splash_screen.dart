import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_metrics.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/brand_logo.dart';

/// Açılış ekranındaki dikey logonun genişliği. Sistem açılış ekranındaki
/// logoyla aynı (`assets/brand/splash/splash.png`'de 680 px, görsel @4x
/// okunuyor): ikisi arasında logo büyüyüp küçülmesin.
const double splashLogoWidth = 170;

/// Uygulama açılışında gösterilen yükleme ekranı.
/// AuthProvider token kontrolü yaparken görünür.
///
/// Sistem açılış karesi siyahtır (#0D0D0D, dikey logo) ve temadan bağımsızdır:
/// o kareyi iOS, uygulamanın kodu çalışmadan çiziyor, kullanıcının tema
/// tercihini bilemiyor. Bu ekran da aynı kareyle başlar (aynı logo, aynı ölçü,
/// aynı yer), sonra temanın rengine geçer. Böylece sistemden uygulamaya geçiş
/// görünmez ve hiçbir açılışta ters temada kare kalmaz (karar 23 Eylül; kare
/// 17 Ekim'de yeni logoyla turuncudan siyaha döndü).
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, this.onRetry});

  /// Verilirse sunucuya ulaşılamamıştır: gösterge yerine mesaj ve
  /// "Tekrar dene" çıkar. Logo yerinden oynamaz.
  final VoidCallback? onRetry;

  /// Sistem karesinin ekranda tutulduğu süre.
  static const Duration brandHold = Duration(milliseconds: 220);

  /// Kareden temaya geçiş.
  static const Duration brandFade = Duration(milliseconds: 320);

  /// Açılış ekranının en az görüneceği süre; geçiş yarıda kesilip ekran
  /// kareden doğrudan ana ekrana zıplamasın diye `main.dart` bunu bekler.
  static const Duration introDuration = Duration(milliseconds: 600);

  /// Kare bu oturumda bir kez oynar. Ekran yeniden kurulursa (ör.
  /// "Tekrar dene" sonrası) baştan kareye dönmez.
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
    return AnimatedBuilder(
      animation: _t,
      builder: (context, _) {
        final t = _t.value;
        return Scaffold(
          backgroundColor:
              Color.lerp(AppColors.background, context.bgColor, t),
          body: Stack(
            alignment: Alignment.center,
            children: [
              // İki logo üst üste: koyu zemin sürümü (beyaz yazı) sönerken
              // temanın sürümü yanıyor. Amblem iki dosyada da aynı yerde,
              // geçişte kaymıyor; açık temada yalnız yazı siyaha döner.
              if (t < 1)
                Opacity(
                  opacity: 1 - t,
                  child: const BrandLogo(
                      width: splashLogoWidth, vertical: true, onDark: true),
                ),
              if (t > 0)
                Opacity(
                  opacity: t,
                  child:
                      const BrandLogo(width: splashLogoWidth, vertical: true),
                ),
              // Gösterge ve hata mesajı sistem karesinde görünmez; tema
              // geldikçe birlikte beliriyor. Dikey logo uzun: küçük ekranda
              // (iPhone SE) hata mesajı logoya değmesin diye aşağıda.
              Align(
                alignment: const Alignment(0, 0.5),
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

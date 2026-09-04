import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/dishrate_logo.dart';

/// Uygulama açılışında gösterilen yükleme ekranı.
/// AuthProvider token kontrolü yaparken görünür.
///
/// Native açılış ekranıyla (flutter_native_splash) aynı logoyu kullanır ki
/// sistem açılışından uygulamaya geçiş sıçramasız olsun.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bgColor,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const DishrateWordmark(width: 220),
            const SizedBox(height: 40),
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                color: AppColors.primary,
                strokeWidth: 2.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

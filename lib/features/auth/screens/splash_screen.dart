import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/dishrate_logo.dart';

/// Açılış ekranındaki logonun genişliği. Sistem açılış ekranındaki logoyla
/// aynı: ikisi arasında logo büyüyüp küçülmesin. `LaunchImage` 300 pt ama
/// kenarlarında boşluk var; simülatörde ölçülen logo genişliği 278 pt.
/// Giriş ekranı da logosunu bu boyuttan başlatıp yerine kaydırıyor.
const double splashLogoWidth = 278;

/// Uygulama açılışında gösterilen yükleme ekranı.
/// AuthProvider token kontrolü yaparken görünür.
///
/// Logo ekranın tam ortasında, sistem açılış ekranındakiyle aynı yerde ve
/// boyutta. Önceden yükleme göstergesiyle birlikte ortalanıyor, bu yüzden
/// sistem ekranına göre biraz yukarıda ve daha küçük duruyordu.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  /// Açılış ekranı bu oturumda gösterildi mi?
  ///
  /// Giriş ekranı logosunu ancak buradan geldiyse ortadan kaydırıyor. Önceden
  /// giriş ekranının kendi "bir kez oynat" bayrağı vardı; ekran yeniden
  /// kurulursa (auth durumu iki kez değişirse, sıcak yenilemede) animasyon
  /// sessizce atlanıyordu.
  static bool wasShown = false;

  @override
  Widget build(BuildContext context) {
    wasShown = true;
    return Scaffold(
      backgroundColor: context.bgColor,
      body: const Stack(
        alignment: Alignment.center,
        children: [
          DishrateWordmark(width: splashLogoWidth),
          Align(
            alignment: Alignment(0, 0.35),
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                color: AppColors.primary,
                strokeWidth: 2.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

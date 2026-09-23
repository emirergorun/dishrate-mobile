import 'package:flutter/material.dart';

import '../../core/theme/app_metrics.dart';

/// Görünen boyutu değiştirmeden dokunma alanını en az [AppSize.minTap] yapar.
///
/// Çipler ve küçük simge düğmeleri 30–36 pt'de kalıyordu; parmak kenara denk
/// gelince dokunuş kaçıyordu. Çocuk ortada kalır, çevresindeki saydam alan
/// dokunuşu yakalar — bu yüzden dokunma dinleyicisi bu widget'ın **dışında**
/// ve `HitTestBehavior.opaque` ile olmalı.
///
/// Burada `Container(alignment: ...)` **kullanılmaz**: boyutu olmayan ama
/// hizalaması olan bir `Container`, sınırlı kısıt aldığında kendini kısıtın en
/// büyüğüne yayar. İlk sürüm öyleydi ve haritayı bozdu (23 Eylül): üst sıradaki
/// düğmeler `Row`'un verdiği tüm ekran yüksekliğine, sağdaki kategori çipleri
/// sütunun tüm genişliğine yayıldı; piller ortaya kaydı, dokunma alanları
/// ekranı kapladı ve geri düğmesine basılamaz oldu. `Center` kendini çocuğunun
/// boyutuna göre ölçer, `ConstrainedBox` da alt sınırı 44 pt'ye çeker: kutu ya
/// çocuk kadar ya 44 pt olur, daha fazlası olmaz.
class MinTapArea extends StatelessWidget {
  const MinTapArea({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(
        minWidth: AppSize.minTap,
        minHeight: AppSize.minTap,
      ),
      child: Center(widthFactor: 1, heightFactor: 1, child: child),
    );
  }
}

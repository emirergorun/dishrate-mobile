import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_metrics.dart';

/// Yükleme iskeleti.
///
/// Dönen çember yerine gelecek içeriğin şeklini gösteriyor: içerik geldiğinde
/// sayfa zıplamıyor ve kullanıcı neyin yüklendiğini önceden görüyor. İçindeki
/// [SkeletonBox]'lar birlikte nefes alır; tek tek yanıp sönmeleri gürültülüydü.
class SkeletonPulse extends StatefulWidget {
  const SkeletonPulse({super.key, required this.child});
  final Widget child;

  @override
  State<SkeletonPulse> createState() => _SkeletonPulseState();
}

class _SkeletonPulseState extends State<SkeletonPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // "Hareketi azalt" açıksa nabız durur, iskelet sabit kalır.
    if (MediaQuery.disableAnimationsOf(context)) {
      _c.stop();
      _c.value = 1;
    } else if (!_c.isAnimating) {
      _c.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.45, end: 1).animate(
        CurvedAnimation(parent: _c, curve: Curves.easeInOut),
      ),
      child: widget.child,
    );
  }
}

/// Liste satırı iskeleti: solda kare görsel, sağda iki satır metin.
/// Menü, restoran araması ve yorum listesi bu şekilde yükleniyor.
class SkeletonRows extends StatelessWidget {
  const SkeletonRows({super.key, this.count = 3, this.leadingSize = 48});

  final int count;
  final double leadingSize;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < count; i++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              children: [
                SkeletonBox(
                  width: leadingSize,
                  height: leadingSize,
                  radius: AppRadius.sm,
                ),
                const SizedBox(width: AppSpace.md),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SkeletonBox(width: 150, height: 14),
                      SizedBox(height: 6),
                      SkeletonBox(width: 100, height: 12),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class SkeletonBox extends StatelessWidget {
  const SkeletonBox({
    super.key,
    this.width,
    required this.height,
    this.radius = 6,
  });

  final double? width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        // Nötr dolgu. `surfaceElevated` koyu temada panel zemininin kendisiydi;
        // yemek panelinde ve değerlendirme akışında iskelet görünmüyordu.
        color: context.fillColor,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

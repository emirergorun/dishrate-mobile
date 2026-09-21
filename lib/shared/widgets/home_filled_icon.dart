import 'package:flutter/material.dart';

/// Tabler "home-filled" ikonu, fonttan değil çizimden.
///
/// Fonttaki karakter kodu (U+FE2B) Unicode'un "birleşen işaret" aralığında;
/// Flutter onu önceki karakterin üstüne binen işaret sanıp sola kaydırıyor,
/// ikon kutusunun dışına taşıyordu. Çizim aynı fonttaki glyph'ten (Tabler,
/// MIT) çıkarıldı: 1 birimlik kareye ölçeklenmiş, `Icon` ile aynı yerde durur.
class HomeFilledIcon extends StatelessWidget {
  const HomeFilledIcon({super.key, required this.color, this.size = 24});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(painter: _HomeFilledPainter(color)),
    );
  }
}

class _HomeFilledPainter extends CustomPainter {
  _HomeFilledPainter(this.color);
  final Color color;

  // Glyph ana hatları; x ve y 0–1 arasında (y aşağı doğru).
  static final Path _unitPath = Path()
    ..moveTo(0.4950, 0.0930)
    ..quadraticBezierTo(0.5000, 0.0910, 0.5110, 0.0930)
    ..lineTo(0.5150, 0.0930)
    ..quadraticBezierTo(0.5210, 0.0950, 0.5290, 0.1020)
    ..quadraticBezierTo(0.5410, 0.1120, 0.5820, 0.1520)
    ..lineTo(0.8260, 0.3960)
    ..quadraticBezierTo(0.9090, 0.4780, 0.9100, 0.4800)
    ..quadraticBezierTo(0.9170, 0.4890, 0.9170, 0.5050)
    ..quadraticBezierTo(0.9170, 0.5250, 0.9010, 0.5380)
    ..quadraticBezierTo(0.8930, 0.5440, 0.8870, 0.5455)
    ..quadraticBezierTo(0.8810, 0.5470, 0.8600, 0.5470)
    ..lineTo(0.8360, 0.5470)
    ..lineTo(0.8360, 0.6770)
    ..quadraticBezierTo(0.8360, 0.7640, 0.8350, 0.7910)
    ..quadraticBezierTo(0.8340, 0.8090, 0.8330, 0.8170)
    ..lineTo(0.8330, 0.8180)
    ..quadraticBezierTo(0.8240, 0.8590, 0.7945, 0.8855)
    ..quadraticBezierTo(0.7650, 0.9120, 0.7250, 0.9170)
    ..quadraticBezierTo(0.7200, 0.9180, 0.6930, 0.9180)
    ..lineTo(0.6690, 0.9170)
    ..lineTo(0.6690, 0.7620)
    ..lineTo(0.6680, 0.6080)
    ..quadraticBezierTo(0.6600, 0.5750, 0.6450, 0.5540)
    ..quadraticBezierTo(0.6150, 0.5140, 0.5600, 0.5060)
    ..quadraticBezierTo(0.5510, 0.5050, 0.5045, 0.5050)
    ..quadraticBezierTo(0.4580, 0.5050, 0.4500, 0.5060)
    ..quadraticBezierTo(0.4180, 0.5090, 0.3930, 0.5270)
    ..quadraticBezierTo(0.3550, 0.5530, 0.3420, 0.6080)
    ..lineTo(0.3410, 0.7620)
    ..lineTo(0.3410, 0.9170)
    ..lineTo(0.3120, 0.9170)
    ..quadraticBezierTo(0.2820, 0.9170, 0.2750, 0.9160)
    ..quadraticBezierTo(0.2380, 0.9080, 0.2120, 0.8820)
    ..quadraticBezierTo(0.1860, 0.8560, 0.1770, 0.8180)
    ..lineTo(0.1770, 0.8170)
    ..quadraticBezierTo(0.1750, 0.8090, 0.1750, 0.7910)
    ..quadraticBezierTo(0.1740, 0.7640, 0.1740, 0.6770)
    ..lineTo(0.1740, 0.5470)
    ..lineTo(0.1500, 0.5470)
    ..quadraticBezierTo(0.1290, 0.5470, 0.1225, 0.5455)
    ..quadraticBezierTo(0.1160, 0.5440, 0.1090, 0.5380)
    ..quadraticBezierTo(0.0930, 0.5250, 0.0930, 0.5050)
    ..quadraticBezierTo(0.0930, 0.4970, 0.0950, 0.4915)
    ..quadraticBezierTo(0.0970, 0.4860, 0.1010, 0.4800)
    ..quadraticBezierTo(0.1030, 0.4770, 0.2930, 0.2870)
    ..lineTo(0.4440, 0.1360)
    ..quadraticBezierTo(0.4730, 0.1080, 0.4820, 0.1000)
    ..quadraticBezierTo(0.4890, 0.0950, 0.4940, 0.0930)
    ..close()
    ..moveTo(0.4530, 0.5890)
    ..quadraticBezierTo(0.4420, 0.5920, 0.4330, 0.6020)
    ..quadraticBezierTo(0.4240, 0.6120, 0.4230, 0.6250)
    ..quadraticBezierTo(0.4220, 0.6300, 0.4220, 0.7740)
    ..lineTo(0.4220, 0.9170)
    ..lineTo(0.5880, 0.9170)
    ..lineTo(0.5880, 0.7740)
    ..quadraticBezierTo(0.5880, 0.6300, 0.5870, 0.6250)
    ..quadraticBezierTo(0.5860, 0.6170, 0.5820, 0.6080)
    ..quadraticBezierTo(0.5730, 0.5940, 0.5550, 0.5890)
    ..quadraticBezierTo(0.5500, 0.5880, 0.5045, 0.5880)
    ..quadraticBezierTo(0.4590, 0.5880, 0.4530, 0.5890)
    ..close();

  @override
  void paint(Canvas canvas, Size size) {
    final matrix = Matrix4.diagonal3Values(size.width, size.height, 1);
    canvas.drawPath(
      _unitPath.transform(matrix.storage),
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(_HomeFilledPainter old) => old.color != color;
}

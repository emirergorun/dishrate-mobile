import 'dart:typed_data';

import 'package:crop_your_image/crop_your_image.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// Kırpma ekranının sonucu: kırpılmış baytlar ve bu kırpmanın özgün görsel
/// üzerindeki dikdörtgeni. Dikdörtgen saklanırsa kullanıcı fotoğrafını daha
/// sonra aynı çerçevelemeyle açıp ince ayar yapabilir.
class CropOutcome {
  const CropOutcome({required this.bytes, required this.area});

  final Uint8List bytes;

  /// Özgün görsel koordinatlarında kırpma dikdörtgeni. Sunucuda
  /// "x,y,genişlik,yükseklik" olarak saklanır.
  final Rect? area;

  /// Sunucuya gönderilecek biçim.
  String? get areaAsString => area == null
      ? null
      : '${area!.left.round()},${area!.top.round()},'
          '${area!.width.round()},${area!.height.round()}';

  /// Sunucudan gelen "x,y,genişlik,yükseklik" metnini çözer.
  static Rect? parseArea(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final parts = raw.trim().split(',');
    if (parts.length != 4) return null;
    final values = parts.map((p) => double.tryParse(p.trim())).toList();
    if (values.any((v) => v == null)) return null;
    final w = values[2]!, h = values[3]!;
    if (w <= 0 || h <= 0) return null;
    return Rect.fromLTWH(values[0]!, values[1]!, w, h);
  }
}

/// Seçilen görseli yüklemeden önce kırpma/konumlandırma ekranı.
/// Çerçeve sabittir; kullanıcı görseli sürükler ve iki parmakla yakınlaştırır.
/// Onaylarsa [CropOutcome] döner, vazgeçerse null.
class ImageCropDialog extends StatefulWidget {
  const ImageCropDialog({
    super.key,
    required this.imageBytes,
    this.circular = true,
    this.title = 'Fotoğrafı Ayarla',
    this.initialArea,
  });

  final Uint8List imageBytes;

  /// Profil fotoğrafı için dairesel maske, logo/menü için kare.
  final bool circular;
  final String title;

  /// Önceki kırpma dikdörtgeni — verilirse ekran o çerçevelemeyle açılır.
  final Rect? initialArea;

  /// Kırpma ekranını açar; sonuç [CropOutcome] veya null.
  static Future<CropOutcome?> show(
    BuildContext context, {
    required Uint8List imageBytes,
    bool circular = true,
    String title = 'Fotoğrafı Ayarla',
    Rect? initialArea,
  }) {
    return showDialog<CropOutcome>(
      context: context,
      barrierDismissible: false,
      builder: (_) => ImageCropDialog(
        imageBytes: imageBytes,
        circular: circular,
        title: title,
        initialArea: initialArea,
      ),
    );
  }

  @override
  State<ImageCropDialog> createState() => _ImageCropDialogState();
}

class _ImageCropDialogState extends State<ImageCropDialog> {
  final _controller = CropController();
  bool _processing = false;

  /// Kullanıcı her hareket ettiğinde güncellenen, özgün görsel
  /// koordinatlarındaki güncel kırpma dikdörtgeni.
  Rect? _currentArea;

  // ── Önceki çerçevelemeyi geri yükleme ──────────────────────────────────────
  //
  // `initialRectBuilder` bu iş için yetmiyor: `interactive: true` olduğunda
  // kırpıcı, çerçeveyi kurduktan hemen sonra görseli "kapla" ölçeğine
  // getiriyor ve verdiğimiz çerçeveyi eziyor. Kütüphane görselin ölçeğini
  // dışarı açmadığı için ölçeği ölçerek buluyoruz:
  //
  //   alan verilir  →  geri okunan dikdörtgen = alan / ölçek
  //
  // Bağıntı doğrusal, o yüzden bir ölçüm + bir düzeltme yetiyor. Düzeltme
  // tutmazsa ekran varsayılan çerçevelemeyle açılır — yani en kötü ihtimalde
  // eski davranış.
  static const int _idle = 0, _measuring = 1, _done = 2;
  int _restoreState = _idle;

  @override
  void initState() {
    super.initState();
    if (widget.initialArea != null) _restoreState = _measuring;
  }

  void _onReady() {
    if (_restoreState != _measuring) return;
    // Kırpıcı kendi setState'i içinden çağırıyor; kareyi bekliyoruz.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _controller.area = widget.initialArea!;
    });
  }

  void _onMoved(Rect rectToCrop) {
    _currentArea = rectToCrop;
    if (_restoreState != _measuring) return;
    _restoreState = _done;

    final target = widget.initialArea!;
    if (rectToCrop.width <= 0) return;

    final scaleFactor = target.width / rectToCrop.width;
    if ((scaleFactor - 1).abs() < 0.01) return; // ölçek 1 — düzeltmeye gerek yok

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _controller.area = Rect.fromLTWH(
        target.left * scaleFactor,
        target.top * scaleFactor,
        target.width * scaleFactor,
        target.height * scaleFactor,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Dialog(
      backgroundColor: context.surfaceColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.all(20),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 520,
          maxHeight: size.height * 0.85,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 4),
              child: Row(
                children: [
                  const Icon(Icons.crop_rounded,
                      color: AppColors.primary, size: 20),
                  const SizedBox(width: 8),
                  Text(widget.title, style: AppTextStyles.titleSmall),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Sürükleyerek konumlandır, iki parmakla yakınlaştır.',
                style: AppTextStyles.bodySmall
                    .copyWith(color: context.textSecondaryColor),
              ),
            ),
            const SizedBox(height: 12),

            // Kırpma alanı
            Flexible(
              child: Container(
                color: Colors.black,
                child: Crop(
                  image: widget.imageBytes,
                  controller: _controller,
                  aspectRatio: 1, // profil/logo için kare
                  withCircleUi: widget.circular,
                  baseColor: Colors.black,
                  maskColor: Colors.black.withValues(alpha: 0.6),
                  // Çerçeveyi sabitleyip görseli hareket ettiriyoruz:
                  // kullanıcı iki parmakla yakınlaştırıp istediği yeri
                  // (örn. yüzü) çerçeveye getirebilsin. interactive olmadan
                  // yalnızca çerçeve taşınabiliyor, yakınlaştırma yapılamıyordu.
                  interactive: true,
                  fixCropRect: true,
                  cornerDotBuilder: (dotSize, _) => const SizedBox.shrink(),
                  // Görsel çözümlenip çerçeve kurulduğunda önceki
                  // çerçevelemeyi geri yüklemeye başlarız.
                  onStatusChanged: (status) {
                    if (status == CropStatus.ready) _onReady();
                  },
                  // Kullanıcı görseli her oynattığında güncel dikdörtgeni
                  // sakla; "Uygula"da bunu da geri döndüreceğiz.
                  onMoved: (_, rectToCrop) => _onMoved(rectToCrop),
                  onCropped: (result) {
                    if (!mounted) return;
                    switch (result) {
                      case CropSuccess(:final croppedImage):
                        Navigator.pop(
                          context,
                          CropOutcome(
                            bytes: croppedImage,
                            area: _currentArea ?? widget.initialArea,
                          ),
                        );
                      case CropFailure():
                        setState(() => _processing = false);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Görsel kırpılamadı, tekrar dene.'),
                            backgroundColor: AppColors.error,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                    }
                  },
                ),
              ),
            ),

            // Butonlar
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _processing
                          ? null
                          : () => Navigator.pop(context, null),
                      child: const Text('Vazgeç'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: _processing
                          ? null
                          : () {
                              setState(() => _processing = true);
                              _controller.crop();
                            },
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: _processing
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : Text('Uygula',
                              style: AppTextStyles.labelLarge
                                  .copyWith(color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

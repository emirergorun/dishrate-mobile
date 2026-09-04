import 'dart:typed_data';

import 'package:crop_your_image/crop_your_image.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// Seçilen görseli yüklemeden önce kırpma/konumlandırma ekranı.
/// Kullanıcı sürükleyerek konumu, köşelerden çekerek boyutu ayarlar.
/// Onaylarsa kırpılmış görselin baytlarını döner, vazgeçerse null.
class ImageCropDialog extends StatefulWidget {
  const ImageCropDialog({
    super.key,
    required this.imageBytes,
    this.circular = true,
    this.title = 'Fotoğrafı Ayarla',
  });

  final Uint8List imageBytes;

  /// Profil fotoğrafı için dairesel maske, logo/menü için kare.
  final bool circular;
  final String title;

  /// Kırpma ekranını açar; sonuç kırpılmış baytlar veya null.
  static Future<Uint8List?> show(
    BuildContext context, {
    required Uint8List imageBytes,
    bool circular = true,
    String title = 'Fotoğrafı Ayarla',
  }) {
    return showDialog<Uint8List>(
      context: context,
      barrierDismissible: false,
      builder: (_) => ImageCropDialog(
        imageBytes: imageBytes,
        circular: circular,
        title: title,
      ),
    );
  }

  @override
  State<ImageCropDialog> createState() => _ImageCropDialogState();
}

class _ImageCropDialogState extends State<ImageCropDialog> {
  final _controller = CropController();
  bool _processing = false;

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
                'Sürükleyerek konumlandır, köşelerden çekerek boyutlandır.',
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
                  cornerDotBuilder: (dotSize, _) => widget.circular
                      ? const SizedBox.shrink()
                      : const DotControl(color: AppColors.primary),
                  onCropped: (result) {
                    if (!mounted) return;
                    switch (result) {
                      case CropSuccess(:final croppedImage):
                        Navigator.pop(context, croppedImage);
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

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/network/file_repository.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/models/user_model.dart';
import '../../../shared/widgets/image_crop_dialog.dart';

/// Profil fotoğrafı düzenlemesinin sonucu — sunucuya gönderilecek üç alan.
class ProfilePhotoResult {
  const ProfilePhotoResult({
    required this.photoUrl,
    required this.originalUrl,
    required this.crop,
  });

  /// Kırpılmış, ekranda gösterilecek görsel. Boş metin → fotoğraf kaldırıldı.
  final String photoUrl;

  /// Kırpılmamış özgün görsel. Yeniden çerçeveleme bunun üzerinden yapılır.
  final String originalUrl;

  /// Özgün görsel üzerindeki kırpma dikdörtgeni: "x,y,genişlik,yükseklik".
  final String crop;
}

/// Profil fotoğrafı seçme / yeniden çerçeveleme akışı.
///
/// Hem profil başlığındaki avatardan hem de "Profili Düzenle" panelinden
/// çağrılır; ikisinin de aynı davranışı göstermesi için tek yerde durur.
abstract final class ProfilePhotoEditor {
  /// Seçenek listesini açar ve seçime göre yükleme yapar.
  /// Kullanıcı vazgeçerse null döner.
  static Future<ProfilePhotoResult?> edit(
    BuildContext context, {
    required UserModel user,
  }) async {
    final choice = await _askChoice(context, user: user);
    if (choice == null || !context.mounted) return null;

    switch (choice) {
      case _PhotoAction.pickNew:
        return _pickFromGallery(context);
      case _PhotoAction.recrop:
        return _recropExisting(context, user: user);
      case _PhotoAction.remove:
        return const ProfilePhotoResult(photoUrl: '', originalUrl: '', crop: '');
    }
  }

  // ── Seçenek listesi ────────────────────────────────────────────────────────

  static Future<_PhotoAction?> _askChoice(
    BuildContext context, {
    required UserModel user,
  }) {
    final hasPhoto = user.profilePhotoUrl != null &&
        user.profilePhotoUrl!.trim().isNotEmpty;

    return showModalBottomSheet<_PhotoAction>(
      context: context,
      backgroundColor: context.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: ctx.dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            _tile(
              ctx,
              icon: Icons.photo_library_rounded,
              label: 'Yeni fotoğraf seç',
              onTap: () => Navigator.pop(ctx, _PhotoAction.pickNew),
            ),
            // Yalnızca özgün görsel saklanmışsa gösterilir. Eski kayıtlarda
            // yalnızca kırpılmış hâli var; onu tekrar kırpmak kaliteyi düşürür.
            if (user.canRecropPhoto)
              _tile(
                ctx,
                icon: Icons.crop_rotate_rounded,
                label: 'Mevcut fotoğrafı düzenle',
                onTap: () => Navigator.pop(ctx, _PhotoAction.recrop),
              ),
            if (hasPhoto)
              _tile(
                ctx,
                icon: Icons.delete_outline_rounded,
                label: 'Fotoğrafı kaldır',
                destructive: true,
                onTap: () => Navigator.pop(ctx, _PhotoAction.remove),
              ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  static Widget _tile(
    BuildContext context, {
    required IconData icon,
    required String label,
    String? subtitle,
    bool destructive = false,
    required VoidCallback onTap,
  }) {
    final color = destructive ? AppColors.error : context.textPrimaryColor;
    return ListTile(
      leading: Icon(icon,
          color: destructive ? AppColors.error : AppColors.primary, size: 22),
      title: Text(label, style: AppTextStyles.bodyLarge.copyWith(color: color)),
      subtitle: subtitle == null
          ? null
          : Text(subtitle,
              style: AppTextStyles.bodySmall
                  .copyWith(color: context.textSecondaryColor)),
      onTap: onTap,
    );
  }

  // ── Galeriden yeni fotoğraf ────────────────────────────────────────────────

  static Future<ProfilePhotoResult?> _pickFromGallery(
      BuildContext context) async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
    );
    if (picked == null || !context.mounted) return null;

    final bytes = await picked.readAsBytes();
    if (!context.mounted) return null;

    return _cropAndUpload(context, original: bytes);
  }

  // ── Kayıtlı özgün görseli yeniden çerçevele ────────────────────────────────

  static Future<ProfilePhotoResult?> _recropExisting(
    BuildContext context, {
    required UserModel user,
  }) async {
    final Uint8List bytes;
    try {
      bytes = await FileRepository.instance
          .downloadBytes(user.profilePhotoOriginalUrl!);
    } catch (_) {
      if (context.mounted) {
        _snack(context, 'Özgün fotoğraf indirilemedi, tekrar dene.');
      }
      return null;
    }
    if (!context.mounted) return null;

    return _cropAndUpload(
      context,
      original: bytes,
      // Önceki çerçeveleme geri yüklenir; kullanıcı kaldığı yerden devam eder.
      initialArea: CropOutcome.parseArea(user.profilePhotoCrop),
      // Özgün görsel zaten sunucuda; tekrar yüklemeye gerek yok.
      existingOriginalUrl: user.profilePhotoOriginalUrl,
    );
  }

  // ── Ortak: kırp, yükle ─────────────────────────────────────────────────────

  static Future<ProfilePhotoResult?> _cropAndUpload(
    BuildContext context, {
    required Uint8List original,
    Rect? initialArea,
    String? existingOriginalUrl,
  }) async {
    final outcome = await ImageCropDialog.show(
      context,
      imageBytes: original,
      circular: true,
      title: 'Profil Fotoğrafı',
      initialArea: initialArea,
    );
    if (outcome == null || !context.mounted) return null;

    try {
      // Özgün görsel yalnızca ilk kez yüklenir; yeniden çerçevelemede
      // sunucudaki kopya korunur.
      final originalUrl = existingOriginalUrl ??
          await FileRepository.instance
              .uploadBytes(original, filename: 'avatar-original.png');

      final photoUrl = await FileRepository.instance
          .uploadBytes(outcome.bytes, filename: 'avatar.png');

      return ProfilePhotoResult(
        photoUrl: photoUrl,
        originalUrl: originalUrl,
        crop: outcome.areaAsString ?? '',
      );
    } catch (_) {
      if (context.mounted) {
        _snack(context, 'Fotoğraf yüklenemedi, tekrar dene.');
      }
      return null;
    }
  }

  static void _snack(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

enum _PhotoAction { pickNew, recrop, remove }

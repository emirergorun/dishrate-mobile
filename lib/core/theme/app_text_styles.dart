import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_fonts.dart';

/// Dishrate tipografi sistemi.
///
/// Font ailesi [AppFonts.active] ile belirlenir — burada elle yazılmaz.
///
/// Ağırlık skalası:
///   300 → Light  |  400 → Regular  |  500 → Medium
///   600 → SemiBold  |  700 → Bold  |  900 → Black
abstract final class AppTextStyles {
  static const _font = AppFonts.active;

  // ─── Büyük başlıklar — Black (900) ────────────────────────────────────────
  static const TextStyle displayLarge = TextStyle(
    fontFamily: _font,
    fontSize: 32,
    fontWeight: AppFonts.display,
    height: 1.15,
    letterSpacing: -0.5,
  );

  static const TextStyle headlineLarge = TextStyle(
    fontFamily: _font,
    fontSize: 26,
    fontWeight: AppFonts.display,
    height: 1.2,
    letterSpacing: -0.3,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontFamily: _font,
    fontSize: 22,
    fontWeight: AppFonts.heading,
    height: 1.25,
    letterSpacing: -0.2,
  );

  // ─── UI başlıkları — Bold / SemiBold (700 / 600) ─────────────────────────
  static const TextStyle titleLarge = TextStyle(
    fontFamily: _font,
    fontSize: 18,
    fontWeight: AppFonts.heading,
    letterSpacing: -0.2,
  );

  static const TextStyle titleMedium = TextStyle(
    fontFamily: _font,
    fontSize: 16,
    fontWeight: AppFonts.heading,
    letterSpacing: -0.1,
  );

  static const TextStyle titleSmall = TextStyle(
    fontFamily: _font,
    fontSize: 14,
    fontWeight: AppFonts.title,
    letterSpacing: 0,
  );

  // ─── Gövde metinleri — Medium / Regular (500 / 400) ──────────────────────
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: _font,
    fontSize: 16,
    fontWeight: AppFonts.body,
    height: 1.5,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: _font,
    fontSize: 14,
    fontWeight: AppFonts.body,
    height: 1.5,
  );

  /// İkincil / meta metin — açık ve koyu tema için nötr gri.
  static TextStyle get bodySmall => const TextStyle(
        fontFamily: _font,
        fontSize: 12,
        fontWeight: AppFonts.body,
        color: AppColors.textSecondary,
        height: 1.4,
      );

  // ─── Etiket / UI metni — Medium (500) ────────────────────────────────────
  static const TextStyle labelLarge = TextStyle(
    fontFamily: _font,
    fontSize: 14,
    fontWeight: AppFonts.title,
    letterSpacing: 0.1,
  );

  static TextStyle get labelSmall => const TextStyle(
        fontFamily: _font,
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
        letterSpacing: 0.4,
      );

  // ─── Görsel üstü metin ────────────────────────────────────────────────────
  // Fotoğrafın üzerine koyu degradeyle yerleştirilen yazılar. Zemin her iki
  // temada da koyu olduğundan renkler SABİTTİR. Buraya tema rengi miras alan
  // bir stil (örn. titleSmall) koyulursa açık modda yazı siyaha döner ve
  // koyu degradenin üstünde okunmaz olur — bu stiller tam olarak onu önler.
  static const TextStyle onImageTitle = TextStyle(
    fontFamily: _font,
    fontSize: 14,
    fontWeight: AppFonts.title,
    color: Colors.white,
    height: 1.25,
  );

  static const TextStyle onImageTitleLarge = TextStyle(
    fontFamily: _font,
    fontSize: 18,
    fontWeight: AppFonts.heading,
    color: Colors.white,
    letterSpacing: -0.2,
  );

  /// Görsel üstü ikincil metin — restoran adı, konum gibi.
  static const TextStyle onImageCaption = TextStyle(
    fontFamily: _font,
    fontSize: 11,
    fontWeight: AppFonts.body,
    color: Color(0xCCFFFFFF),
    height: 1.4,
  );

  /// Görsel üstü ikincil metnin ikon rengiyle eşleşen tonu.
  static const Color onImageMuted = Color(0xCCFFFFFF);

  // ─── Puan gösterimi ───────────────────────────────────────────────────────
  static const TextStyle ratingLarge = TextStyle(
    fontFamily: _font,
    fontSize: 28,
    fontWeight: AppFonts.heading,
    color: AppColors.star,
    letterSpacing: -0.5,
  );

  static const TextStyle ratingSmall = TextStyle(
    fontFamily: _font,
    fontSize: 13,
    fontWeight: AppFonts.title,
    color: AppColors.star,
  );
}

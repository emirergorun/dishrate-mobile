import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Dishrate tipografi sistemi — Satoshi font ailesi.
///
/// Ağırlık skalası:
///   300 → Light  |  400 → Regular  |  500 → Medium
///   700 → Bold   |  900 → Black
abstract final class AppTextStyles {
  static const _font = 'Urbanist';

  // ─── Büyük başlıklar — Black (900) ────────────────────────────────────────
  static const TextStyle displayLarge = TextStyle(
    fontFamily: _font,
    fontSize: 32,
    fontWeight: FontWeight.w900,
    height: 1.15,
    letterSpacing: -0.5,
  );

  static const TextStyle headlineLarge = TextStyle(
    fontFamily: _font,
    fontSize: 26,
    fontWeight: FontWeight.w900,
    height: 1.2,
    letterSpacing: -0.3,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontFamily: _font,
    fontSize: 22,
    fontWeight: FontWeight.w700,
    height: 1.25,
    letterSpacing: -0.2,
  );

  // ─── UI başlıkları — Bold / SemiBold (700 / 600) ─────────────────────────
  static const TextStyle titleLarge = TextStyle(
    fontFamily: _font,
    fontSize: 18,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.2,
  );

  static const TextStyle titleMedium = TextStyle(
    fontFamily: _font,
    fontSize: 16,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.1,
  );

  static const TextStyle titleSmall = TextStyle(
    fontFamily: _font,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
  );

  // ─── Gövde metinleri — Medium / Regular (500 / 400) ──────────────────────
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: _font,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: _font,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  /// İkincil / meta metin — açık ve koyu tema için nötr gri.
  static TextStyle get bodySmall => const TextStyle(
        fontFamily: _font,
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
        height: 1.4,
      );

  // ─── Etiket / UI metni — Medium (500) ────────────────────────────────────
  static const TextStyle labelLarge = TextStyle(
    fontFamily: _font,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
  );

  static TextStyle get labelSmall => const TextStyle(
        fontFamily: _font,
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
        letterSpacing: 0.4,
      );

  // ─── Puan gösterimi ───────────────────────────────────────────────────────
  static const TextStyle ratingLarge = TextStyle(
    fontFamily: _font,
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: AppColors.star,
    letterSpacing: -0.5,
  );

  static const TextStyle ratingSmall = TextStyle(
    fontFamily: _font,
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: AppColors.star,
  );
}

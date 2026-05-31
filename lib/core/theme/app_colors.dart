import 'package:flutter/material.dart';

// ignore_for_file: avoid_classes_with_only_static_members

/// Dishrate renk paleti — sabit marka renkleri + koyu tema varsayılanları.
abstract final class AppColors {
  // ─── Arka plan katmanları ──────────────────────────────────────────────────
  /// Ana sayfa arka planı: en derin siyah
  static const Color background = Color(0xFF0D0D0D);

  /// Kart / bileşen yüzeyi
  static const Color surface = Color(0xFF1A1A1A);

  /// Hafif yükseltilmiş yüzey (bottom sheet, modal)
  static const Color surfaceElevated = Color(0xFF242424);

  /// Ayırıcı çizgiler / ince kenarlıklar
  static const Color divider = Color(0xFF2C2C2C);

  // ─── Marka rengi ──────────────────────────────────────────────────────────
  /// Dishrate ana turuncu — puan yıldızları, CTA butonları
  static const Color primary = Color(0xFFFF6B35);

  /// Hover / pressed durumu için koyulaştırılmış turuncu
  static const Color primaryDark = Color(0xFFD45A28);

  /// Puan yıldızlarının dolgu rengi (amber tonu)
  static const Color star = Color(0xFFFFC107);

  // ─── Metin ────────────────────────────────────────────────────────────────
  /// Birincil metin: başlıklar, önemli içerik
  static const Color textPrimary = Color(0xFFF5F5F5);

  /// İkincil metin: açıklamalar, meta bilgiler
  static const Color textSecondary = Color(0xFF8A8A8E);

  /// Devre dışı / yer tutucu metin
  static const Color textDisabled = Color(0xFF48484A);

  // ─── Durum renkleri ───────────────────────────────────────────────────────
  static const Color success = Color(0xFF30D158);
  static const Color error = Color(0xFFFF453A);
  static const Color warning = Color(0xFFFFD60A);

  // ─── Bottom nav ───────────────────────────────────────────────────────────
  static const Color navBackground = Color(0xFF141414);
  static const Color navSelected = Color(0xFFFF6B35);
  static const Color navUnselected = Color(0xFF636366);

  // ─── Açık tema eşdeğerleri ────────────────────────────────────────────────
  static const Color lightBackground = Color(0xFFF5F5F5);
  static const Color lightSurface = Colors.white;
  static const Color lightSurfaceElevated = Color(0xFFEFEFEF);
  static const Color lightDivider = Color(0xFFE0E0E0);
  static const Color lightTextPrimary = Color(0xFF111111);
  static const Color lightTextSecondary = Color(0xFF6B6B6B);
  static const Color lightTextDisabled = Color(0xFFBBBBBB);
  static const Color lightNavBackground = Colors.white;
  static const Color lightNavUnselected = Color(0xFF9E9E9E);
}

/// Tema'ya duyarlı renk erişimi — widget build metodlarında kullanılır.
/// Örn: `context.scheme.surface`
extension ThemeColors on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  Color get bgColor =>
      isDark ? AppColors.background : AppColors.lightBackground;

  Color get surfaceColor =>
      isDark ? AppColors.surface : AppColors.lightSurface;

  Color get surfaceElevatedColor =>
      isDark ? AppColors.surfaceElevated : AppColors.lightSurfaceElevated;

  Color get dividerColor =>
      isDark ? AppColors.divider : AppColors.lightDivider;

  Color get textPrimaryColor =>
      isDark ? AppColors.textPrimary : AppColors.lightTextPrimary;

  Color get textSecondaryColor =>
      isDark ? AppColors.textSecondary : AppColors.lightTextSecondary;

  Color get navBgColor =>
      isDark ? AppColors.navBackground : AppColors.lightNavBackground;

  Color get navUnselectedColor =>
      isDark ? AppColors.navUnselected : AppColors.lightNavUnselected;
}

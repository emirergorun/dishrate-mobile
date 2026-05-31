import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';

final class AppTheme {
  const AppTheme._();

  static const _font = 'Urbanist';

  // ─── Satoshi tabanlı textTheme yardımcısı ───────────────────────────────────
  static TextTheme _satoshiTextTheme(TextTheme base, Color bodyColor) {
    return base.copyWith(
      displayLarge:  base.displayLarge?.copyWith(fontFamily: _font, fontWeight: FontWeight.w900, color: bodyColor),
      displayMedium: base.displayMedium?.copyWith(fontFamily: _font, fontWeight: FontWeight.w900, color: bodyColor),
      displaySmall:  base.displaySmall?.copyWith(fontFamily: _font, fontWeight: FontWeight.w900, color: bodyColor),
      headlineLarge: base.headlineLarge?.copyWith(fontFamily: _font, fontWeight: FontWeight.w900, color: bodyColor),
      headlineMedium:base.headlineMedium?.copyWith(fontFamily: _font, fontWeight: FontWeight.w700, color: bodyColor),
      headlineSmall: base.headlineSmall?.copyWith(fontFamily: _font, fontWeight: FontWeight.w700, color: bodyColor),
      titleLarge:    base.titleLarge?.copyWith(fontFamily: _font, fontWeight: FontWeight.w700, color: bodyColor),
      titleMedium:   base.titleMedium?.copyWith(fontFamily: _font, fontWeight: FontWeight.w700, color: bodyColor),
      titleSmall:    base.titleSmall?.copyWith(fontFamily: _font, fontWeight: FontWeight.w600, color: bodyColor),
      bodyLarge:     base.bodyLarge?.copyWith(fontFamily: _font, fontWeight: FontWeight.w400, color: bodyColor),
      bodyMedium:    base.bodyMedium?.copyWith(fontFamily: _font, fontWeight: FontWeight.w400, color: bodyColor),
      bodySmall:     base.bodySmall?.copyWith(fontFamily: _font, fontWeight: FontWeight.w400, color: AppColors.textSecondary),
      labelLarge:    base.labelLarge?.copyWith(fontFamily: _font, fontWeight: FontWeight.w600, color: bodyColor),
      labelMedium:   base.labelMedium?.copyWith(fontFamily: _font, fontWeight: FontWeight.w500, color: bodyColor),
      labelSmall:    base.labelSmall?.copyWith(fontFamily: _font, fontWeight: FontWeight.w500, color: AppColors.textSecondary),
    );
  }

  // ─── Koyu Tema ───────────────────────────────────────────────────────────────
  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        onPrimary: Colors.white,
        secondary: AppColors.star,
        surface: AppColors.surface,
        onSurface: AppColors.textPrimary,
        onSurfaceVariant: AppColors.textSecondary,
        outline: AppColors.textDisabled,
        outlineVariant: AppColors.divider,
        error: AppColors.error,
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: TextStyle(
          fontFamily: _font,
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
      ),

      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.navBackground,
        selectedItemColor: AppColors.navSelected,
        unselectedItemColor: AppColors.navUnselected,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        selectedLabelStyle: TextStyle(fontFamily: _font, fontSize: 10, fontWeight: FontWeight.w600),
        unselectedLabelStyle: TextStyle(fontFamily: _font, fontSize: 10, fontWeight: FontWeight.w400),
      ),

      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: EdgeInsets.zero,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontFamily: _font, fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          side: const BorderSide(color: AppColors.divider),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontFamily: _font, fontSize: 15, fontWeight: FontWeight.w500),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        hintStyle: const TextStyle(fontFamily: _font, color: AppColors.textDisabled, fontSize: 15),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.divider, width: 1)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),

      dividerTheme: const DividerThemeData(color: AppColors.divider, thickness: 1, space: 1),

      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surface,
        selectedColor: AppColors.primary.withValues(alpha: 0.15),
        labelStyle: const TextStyle(fontFamily: _font, fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
        side: const BorderSide(color: AppColors.divider),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),

      textTheme: _satoshiTextTheme(ThemeData.dark().textTheme, AppColors.textPrimary),
    );
  }

  // ─── Açık Tema ───────────────────────────────────────────────────────────────
  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.lightBackground,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        onPrimary: Colors.white,
        secondary: AppColors.star,
        surface: AppColors.lightSurface,
        onSurface: AppColors.lightTextPrimary,
        onSurfaceVariant: AppColors.lightTextSecondary,
        outline: AppColors.lightTextDisabled,
        outlineVariant: AppColors.lightDivider,
        error: AppColors.error,
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.lightBackground,
        foregroundColor: AppColors.lightTextPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        titleTextStyle: TextStyle(
          fontFamily: _font,
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: AppColors.lightTextPrimary,
        ),
      ),

      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.lightNavBackground,
        selectedItemColor: AppColors.navSelected,
        unselectedItemColor: AppColors.lightNavUnselected,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        selectedLabelStyle: TextStyle(fontFamily: _font, fontSize: 10, fontWeight: FontWeight.w600),
        unselectedLabelStyle: TextStyle(fontFamily: _font, fontSize: 10, fontWeight: FontWeight.w400),
      ),

      cardTheme: CardThemeData(
        color: AppColors.lightSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: EdgeInsets.zero,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontFamily: _font, fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.lightTextPrimary,
          side: const BorderSide(color: AppColors.lightDivider),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontFamily: _font, fontSize: 15, fontWeight: FontWeight.w500),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.lightSurface,
        hintStyle: const TextStyle(fontFamily: _font, color: AppColors.lightTextDisabled, fontSize: 15),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.lightDivider, width: 1)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),

      dividerTheme: const DividerThemeData(color: AppColors.lightDivider, thickness: 1, space: 1),

      chipTheme: ChipThemeData(
        backgroundColor: AppColors.lightSurface,
        selectedColor: AppColors.primary.withValues(alpha: 0.12),
        labelStyle: const TextStyle(fontFamily: _font, fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.lightTextPrimary),
        side: const BorderSide(color: AppColors.lightDivider),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),

      textTheme: _satoshiTextTheme(ThemeData.light().textTheme, AppColors.lightTextPrimary),
    );
  }
}

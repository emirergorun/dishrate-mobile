import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';
import 'app_fonts.dart';
import 'app_metrics.dart';
import 'app_text_styles.dart';

final class AppTheme {
  const AppTheme._();

  static ThemeData get dark => _build(Brightness.dark);
  static ThemeData get light => _build(Brightness.light);

  /// İki tema tek yerden kuruluyor. Önceden iki ayrı 100 satırlık blok vardı
  /// ve biri güncellenip diğeri unutuluyordu — "bir renk yalnızca tek temada
  /// tanımlıysa hatadır" kuralını yapısal olarak garanti etmenin yolu bu.
  static ThemeData _build(Brightness brightness) {
    final dark = brightness == Brightness.dark;

    final bg = dark ? AppColors.background : AppColors.lightBackground;
    final surface = dark ? AppColors.surface : AppColors.lightSurface;
    final elevated =
        dark ? AppColors.surfaceElevated : AppColors.lightSurfaceElevated;
    final divider = dark ? AppColors.divider : AppColors.lightDivider;
    final textPrimary =
        dark ? AppColors.textPrimary : AppColors.lightTextPrimary;
    final textSecondary =
        dark ? AppColors.textSecondary : AppColors.lightTextSecondary;
    final textTertiary =
        dark ? AppColors.textDisabled : AppColors.lightTextDisabled;
    final accentText = dark ? AppColors.primary : AppColors.lightAccentText;

    final radiusMd = BorderRadius.circular(AppRadius.md);

    // Butonlar 52 yüksekliğinde: parmakla rahat basılan boyut, ve iki yan yana
    // buton farklı yazı uzunluğunda olsa da aynı hizada kalsın.
    const buttonSize = Size(0, 52);
    final buttonText = AppTextStyles.labelLarge.copyWith(fontSize: 16);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      // Ham `TextStyle(...)` yazılan yerler de aktif fontu miras alsın.
      fontFamily: AppFonts.active,
      scaffoldBackgroundColor: bg,
      canvasColor: bg,
      // Material dalgası iOS'ta yabancı duruyor; basılma geri bildirimi
      // bileşenlerin kendi ölçek/opaklık animasyonlarından geliyor.
      splashFactory: NoSplash.splashFactory,
      highlightColor: textPrimary.withValues(alpha: 0.04),

      colorScheme: ColorScheme(
        brightness: brightness,
        primary: AppColors.primary,
        onPrimary: AppColors.onPrimary,
        secondary: dark ? AppColors.star : AppColors.lightStar,
        onSecondary: AppColors.onPrimary,
        error: AppColors.error,
        onError: Colors.white,
        surface: surface,
        onSurface: textPrimary,
        onSurfaceVariant: textSecondary,
        surfaceContainerHighest: elevated,
        outline: textTertiary,
        outlineVariant: divider,
        surfaceTint: Colors.transparent,
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        foregroundColor: textPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        systemOverlayStyle:
            dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
        titleTextStyle: AppTextStyles.titleMedium.copyWith(color: textPrimary),
        iconTheme: IconThemeData(color: textPrimary, size: 22),
      ),

      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: bg,
        selectedItemColor: AppColors.primary,
        unselectedItemColor:
            dark ? AppColors.navUnselected : AppColors.lightNavUnselected,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),

      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: radiusMd),
        margin: EdgeInsets.zero,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.35),
          disabledForegroundColor: AppColors.onPrimary.withValues(alpha: 0.6),
          elevation: 0,
          minimumSize: buttonSize,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          shape: RoundedRectangleBorder(borderRadius: radiusMd),
          textStyle: buttonText,
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          minimumSize: buttonSize,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          shape: RoundedRectangleBorder(borderRadius: radiusMd),
          textStyle: buttonText,
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textPrimary,
          side: BorderSide(color: divider),
          minimumSize: buttonSize,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          shape: RoundedRectangleBorder(borderRadius: radiusMd),
          textStyle: buttonText,
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: accentText,
          textStyle: AppTextStyles.labelLarge,
          shape: RoundedRectangleBorder(borderRadius: radiusMd),
        ),
      ),

      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(foregroundColor: textPrimary),
      ),

      // Giriş alanları kenarlıksız dolgu: her alanın çerçevesi olunca form
      // kutu kutu görünüyordu. Odakta turuncu çerçeve hangi alanda
      // olunduğunu gösteriyor.
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: dark ? surface : elevated,
        hintStyle: AppTextStyles.bodyLarge.copyWith(color: textTertiary),
        prefixIconColor: textSecondary,
        suffixIconColor: textSecondary,
        border: OutlineInputBorder(
            borderRadius: radiusMd, borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
            borderRadius: radiusMd, borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: radiusMd,
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        counterStyle: AppTextStyles.caption.copyWith(color: textTertiary),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      ),

      dividerTheme: DividerThemeData(color: divider, thickness: 1, space: 1),

      chipTheme: ChipThemeData(
        backgroundColor: surface,
        selectedColor: textPrimary,
        labelStyle: AppTextStyles.label.copyWith(color: textPrimary),
        side: BorderSide.none,
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: elevated,
        surfaceTintColor: Colors.transparent,
        modalBarrierColor: Colors.black.withValues(alpha: 0.55),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
        ),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg)),
        titleTextStyle: AppTextStyles.titleMedium.copyWith(color: textPrimary),
        contentTextStyle:
            AppTextStyles.bodyMedium.copyWith(color: textSecondary),
      ),

      // Bildirimler zeminin tersi tonda: yeşil/kırmızı dolgu yerine nötr
      // yüzey, ton yalnızca gerekirse içerikteki ikonda.
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: dark ? AppColors.lightSurface : AppColors.textPrimary,
        contentTextStyle:
            AppTextStyles.bodyMedium.copyWith(color: AppColors.lightTextPrimary),
        actionTextColor: AppColors.lightAccentText,
        shape: RoundedRectangleBorder(borderRadius: radiusMd),
        elevation: 0,
      ),

      progressIndicatorTheme:
          const ProgressIndicatorThemeData(color: AppColors.primary),

      iconTheme: IconThemeData(color: textPrimary, size: 22),

      textTheme: _textTheme(
        dark ? ThemeData.dark().textTheme : ThemeData.light().textTheme,
        textPrimary,
        textSecondary,
      ),
    );
  }

  static TextTheme _textTheme(
      TextTheme base, Color primary, Color secondary) {
    TextStyle? apply(TextStyle? s, TextStyle from, Color color) =>
        s?.merge(from).copyWith(color: color);

    return base.copyWith(
      displayLarge: apply(base.displayLarge, AppTextStyles.displayLarge, primary),
      displayMedium: apply(base.displayMedium, AppTextStyles.displayLarge, primary),
      displaySmall: apply(base.displaySmall, AppTextStyles.headlineLarge, primary),
      headlineLarge: apply(base.headlineLarge, AppTextStyles.headlineLarge, primary),
      headlineMedium: apply(base.headlineMedium, AppTextStyles.headlineMedium, primary),
      headlineSmall: apply(base.headlineSmall, AppTextStyles.titleLarge, primary),
      titleLarge: apply(base.titleLarge, AppTextStyles.titleLarge, primary),
      titleMedium: apply(base.titleMedium, AppTextStyles.titleMedium, primary),
      titleSmall: apply(base.titleSmall, AppTextStyles.titleSmall, primary),
      bodyLarge: apply(base.bodyLarge, AppTextStyles.bodyLarge, primary),
      bodyMedium: apply(base.bodyMedium, AppTextStyles.bodyMedium, primary),
      bodySmall: apply(base.bodySmall, AppTextStyles.caption, secondary),
      labelLarge: apply(base.labelLarge, AppTextStyles.labelLarge, primary),
      labelMedium: apply(base.labelMedium, AppTextStyles.label, primary),
      labelSmall: apply(base.labelSmall, AppTextStyles.label, secondary),
    );
  }
}

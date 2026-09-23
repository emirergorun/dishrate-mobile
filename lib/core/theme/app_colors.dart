import 'package:flutter/material.dart';

// ignore_for_file: avoid_classes_with_only_static_members

/// Dishrate renk paleti.
///
/// Turuncu ve yıldız sarısı logodan gelir. Nötrler tek bir aileden (hafif
/// sıcak kömür) türetildi: önceki palette soğuk iOS grileri ile nötr griler
/// yan yana duruyordu ve yüzeyler farklı uygulamalardan toplanmış gibiydi.
///
/// **Ekranlarda sabit değil `context.*Color` erişimcisi kullan.** Sabitin
/// kendisi rengi tek temaya kilitler; açık modda koyu leke olarak dönen
/// hataların hepsi `AppColors.surface` gibi doğrudan kullanımlardan çıktı.
/// Sabitler, henüz taşınmamış eski ekranlar derlenmeye devam etsin diye duruyor.
abstract final class AppColors {
  // ─── Marka ────────────────────────────────────────────────────────────────
  /// Ana eylem, seçili sekme, kelime markası. Başka hiçbir yerde "süs" olarak
  /// kullanılmaz — her yerde turuncu olunca hiçbir şey öne çıkmıyordu.
  static const Color primary = Color(0xFFFF6B35);

  /// Turuncu dolgunun üstündeki yazı. Beyaz bu turuncunun üstünde 2.8:1
  /// kalıyordu (AA 4.5 ister); koyu yazı 6.9:1 veriyor.
  static const Color onPrimary = Color(0xFF140B06);

  /// Yıldız glifi (koyu tema). Puan RAKAMLARI bu renkte yazılmaz: sarı metin
  /// açık zeminde 1.5:1 kalıyor, okunmuyordu.
  ///
  /// 23 Eylül'de marka sarısından (#FFC107) kehribara alındı (#E09900);
  /// cihaz testinde koyu bulunup 24 Eylül'de bir ton açıldı. Açık temadaki
  /// [lightStar] ile aynı renk ailesinde. Koyu kartta 8.5:1.
  static const Color star = Color(0xFFEBA500);

  // ─── Durum ────────────────────────────────────────────────────────────────
  static const Color success = Color(0xFF30D158);
  static const Color error = Color(0xFFFF453A);

  // ─── Koyu tema ────────────────────────────────────────────────────────────
  /// Açılış ekranıyla birebir aynı; splash'ten uygulamaya geçişte ton kaymasın.
  static const Color background = Color(0xFF0D0D0D);
  static const Color surface = Color(0xFF171615);
  static const Color surfaceElevated = Color(0xFF211F1D);
  static const Color divider = Color(0xFF2B2926);
  static const Color textPrimary = Color(0xFFF3F1EE);

  /// Zemin üstünde 5.7:1. Eski ekranlar bu sabiti iki temada da kullandığı
  /// için açık zeminde de önceki değerden (3.15:1) geri kalmayacak ton seçildi.
  static const Color textSecondary = Color(0xFF8F8A84);

  /// Yer tutucu, pasif ikon. İkincil metinden bilerek daha soluk.
  static const Color textDisabled = Color(0xFF6F6A64);

  static const Color navBackground = background;
  /// 1.4 turunda bir ton açıldı: 4.3:1 → 4.5:1.
  static const Color navUnselected = Color(0xFF7E7973);

  // ─── Açık tema ────────────────────────────────────────────────────────────
  static const Color lightBackground = Color(0xFFF6F6F5);
  static const Color lightSurface = Color(0xFFFDFDFC);
  static const Color lightSurfaceElevated = Color(0xFFEDECEA);
  static const Color lightDivider = Color(0xFFE2E0DD);
  static const Color lightTextPrimary = Color(0xFF161412);
  static const Color lightTextSecondary = Color(0xFF5E5953);
  static const Color lightTextDisabled = Color(0xFF8A847E);
  static const Color lightNavBackground = lightBackground;
  /// 1.4 erişilebilirlik turunda bir ton koyulaştı: 3.4:1 → 4.5:1.
  static const Color lightNavUnselected = Color(0xFF75706B);

  /// Açık temada seçili alt menü sekmesi. `primary` ile aynı olunca + butonu
  /// ile sekme birbirine karışıyordu; ikisinin ortası bu ton seçildi (3.5:1).
  /// 1.4 turunda 4.8:1 için `lightAccentText` denendi ama gözle fazla koyu
  /// bulundu (cihaz testi, 23 Eylül). Seçili sekme renkten başka iki sinyalle
  /// daha ayrılıyor — dolu ikon ve konum — bu yüzden 3.5:1 kabul edildi.
  static const Color lightNavSelected = Color(0xFFE05620);

  /// Açık zeminde küçük turuncu metin. Marka turuncusu burada 2.6:1 kalıyordu;
  /// bu ton 4.8:1 veriyor ve yan yana görüldüğünde hâlâ "aynı turuncu" okunuyor.
  static const Color lightAccentText = Color(0xFFC2410C);

  /// Açık zeminde yıldız glifi. Parlak sarı beyaza yakın zeminde şekil olarak
  /// eriyordu; bu kehribar tonu yıldızın biçimini koruyor.
  ///
  /// 1.4 turunda kontrast için #B98300'e (3.1:1) koyulaştırıldı, cihaz
  /// testlerinde iki kez koyu bulundu: 23 Eylül'de #D99400'e, 24 Eylül'de
  /// buraya açıldı (beyaz kartta 2.2:1). Grafik eşiği 3:1'in altında kalıyor;
  /// kabul edilebilir çünkü puanı yalnızca yıldızın rengi taşımıyor — yanında
  /// rakam yazıyor, dolu yıldız ile boş yıldız da renkle değil biçimle
  /// (dolgu ve çerçeve) ayrılıyor.
  static const Color lightStar = Color(0xFFE6A000);

  /// Açık zeminde hata metni. [error] burada 3.3:1 kalıyor, küçük yazı için az.
  static const Color lightErrorText = Color(0xFFD70015);
}

/// Temaya duyarlı renk erişimi — widget build metodlarında kullanılır.
extension ThemeColors on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  Color get bgColor =>
      isDark ? AppColors.background : AppColors.lightBackground;

  Color get surfaceColor =>
      isDark ? AppColors.surface : AppColors.lightSurface;

  Color get surfaceElevatedColor =>
      isDark ? AppColors.surfaceElevated : AppColors.lightSurfaceElevated;

  /// Nötr dolgu: çip, iskelet, fotoğraf yer tutucusu, baş harf kutusu.
  ///
  /// Metin renginin yarı saydam hâli, bu yüzden sayfada da alt panelde de
  /// zeminin bir kademe üstünde durur. Sabit yüzey tonları bunu yapamıyordu:
  /// `surfaceElevated` koyu temada panel zemininin kendisi olduğu için
  /// panellerdeki iskelet görünmüyordu; `surface` de sayfa zemininden ancak
  /// 1.06–1.08:1 ayrıldığı için çipin şekli kayboluyordu.
  Color get fillColor => textPrimaryColor.withValues(alpha: 0.08);

  Color get dividerColor =>
      isDark ? AppColors.divider : AppColors.lightDivider;

  Color get textPrimaryColor =>
      isDark ? AppColors.textPrimary : AppColors.lightTextPrimary;

  Color get textSecondaryColor =>
      isDark ? AppColors.textSecondary : AppColors.lightTextSecondary;

  /// Üçüncül metin: yer tutucu, pasif ikon, sıra numarası.
  Color get textTertiaryColor =>
      isDark ? AppColors.textDisabled : AppColors.lightTextDisabled;

  /// Küçük boyutta turuncu yazı (bağlantı, "Sen" etiketi). Dolgu için değil —
  /// dolgu her iki temada da [AppColors.primary].
  Color get accentTextColor =>
      isDark ? AppColors.primary : AppColors.lightAccentText;

  Color get starColor => isDark ? AppColors.star : AppColors.lightStar;

  /// Puan GİRİŞİNDEKİ boş yıldızın çerçeve rengi (değerlendirme akışı, günlük
  /// düzenleme). Yıldızın kendi renginin soluğu: dolu ile boş biçimle ayrılır,
  /// çerçeve de aynı aileden kalsın. %55'te silik duruyordu (cihaz testi,
  /// 23 Eylül), %75'e çıkarıldı.
  Color get starOutlineColor => starColor.withValues(alpha: 0.75);

  Color get errorTextColor =>
      isDark ? AppColors.error : AppColors.lightErrorText;

  /// Alt panel zemini. Koyu temada zeminden bir ton açık ki panel sayfadan
  /// ayrılsın; açık temada beyaza yakın ki içindeki dolgulu giriş alanları
  /// (elevated tonunda) panelin üstünde seçilebilsin.
  Color get sheetColor =>
      isDark ? AppColors.surfaceElevated : AppColors.lightSurface;

  Color get navBgColor =>
      isDark ? AppColors.navBackground : AppColors.lightNavBackground;

  Color get navUnselectedColor =>
      isDark ? AppColors.navUnselected : AppColors.lightNavUnselected;
}

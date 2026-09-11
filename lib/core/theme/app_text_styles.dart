import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_fonts.dart';

/// Dishrate tipografi sistemi.
///
/// Font ailesi ve ağırlıklar [AppFonts] üzerinden gelir — burada sayı yazılmaz.
///
/// Stillerin çoğu **renksizdir**: rengi ekran `context.textSecondaryColor`
/// gibi temaya duyarlı erişimcilerle verir. Stile sabit renk gömmek onu tek
/// temaya kilitliyordu. İstisnalar bilerek sabittir: görsel üstü stiller
/// (zemin iki temada da koyu) ve eski ekranların kullandığı [bodySmall] /
/// [labelSmall].
///
/// Harf aralığı Urbanist'e göre: font zaten sıkı çiziyor, bu yüzden yalnızca
/// 20px üstündeki başlıklarda hafif eksi aralık var. Geist'e göre ayarlanmış
/// daha büyük eksi değerler Urbanist'te harfleri birbirine yapıştırıyordu.
abstract final class AppTextStyles {
  static const _font = AppFonts.active;

  /// Sabit genişlikli rakam isteği. Urbanist bu özelliği taşımıyor (rakamlar
  /// orantılı çizili, "1" diğerlerinden dar), yani şu an etkisiz; puan
  /// listelerinde hizayı rakamların satır sonuna yaslanması sağlıyor. Font
  /// değişirse ve yeni font destekliyorsa kendiliğinden devreye girer.
  static const List<FontFeature> tabular = [FontFeature.tabularFigures()];

  // ─── Başlıklar ────────────────────────────────────────────────────────────
  /// Akışın soru başlıkları ("Nerede yedin?").
  static const TextStyle displayLarge = TextStyle(
    fontFamily: _font,
    fontSize: 30,
    fontWeight: AppFonts.display,
    height: 1.12,
    letterSpacing: -0.3,
  );

  /// Detay ekranlarının başlığı (restoran adı, yemek adı).
  static const TextStyle headlineLarge = TextStyle(
    fontFamily: _font,
    fontSize: 26,
    fontWeight: AppFonts.display,
    height: 1.15,
    letterSpacing: -0.3,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontFamily: _font,
    fontSize: 21,
    fontWeight: AppFonts.heading,
    height: 1.2,
    letterSpacing: -0.2,
  );

  /// Keşfet bölüm başlıkları.
  static const TextStyle titleLarge = TextStyle(
    fontFamily: _font,
    fontSize: 19,
    fontWeight: AppFonts.heading,
    height: 1.25,
    letterSpacing: -0.1,
  );

  static const TextStyle titleMedium = TextStyle(
    fontFamily: _font,
    fontSize: 16,
    fontWeight: AppFonts.heading,
    height: 1.3,
  );

  /// Liste öğesi adları.
  static const TextStyle titleSmall = TextStyle(
    fontFamily: _font,
    fontSize: 15,
    fontWeight: AppFonts.title,
    height: 1.3,
  );

  // ─── Gövde ────────────────────────────────────────────────────────────────
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: _font,
    fontSize: 16,
    fontWeight: AppFonts.body,
    height: 1.5,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: _font,
    fontSize: 15,
    fontWeight: AppFonts.body,
    height: 1.5,
  );

  /// Meta bilgi (restoran · ilçe, tarih). Renksiz — rengi ekran verir.
  static const TextStyle caption = TextStyle(
    fontFamily: _font,
    fontSize: 13,
    fontWeight: AppFonts.body,
    height: 1.4,
  );

  /// Küçük vurgulu etiket ("Tümü", "Sen").
  static const TextStyle label = TextStyle(
    fontFamily: _font,
    fontSize: 13,
    fontWeight: AppFonts.title,
    height: 1.3,
  );

  /// Eski ekranların ikincil metni. Rengi sabit, çünkü 99 yerde context'siz
  /// kullanılıyor; yeni kodda [caption] + `context.textSecondaryColor` yaz.
  static TextStyle get bodySmall => const TextStyle(
        fontFamily: _font,
        fontSize: 13,
        fontWeight: AppFonts.body,
        color: AppColors.textSecondary,
        height: 1.4,
      );

  // ─── Etiket ───────────────────────────────────────────────────────────────
  static const TextStyle labelLarge = TextStyle(
    fontFamily: _font,
    fontSize: 15,
    fontWeight: AppFonts.title,
  );

  /// Eski ekranların küçük etiketi — [bodySmall] ile aynı gerekçeyle sabit renkli.
  static TextStyle get labelSmall => const TextStyle(
        fontFamily: _font,
        fontSize: 12,
        fontWeight: AppFonts.title,
        color: AppColors.textSecondary,
        letterSpacing: 0.2,
      );

  // ─── Görsel üstü metin ────────────────────────────────────────────────────
  // Fotoğrafın üzerine koyu degradeyle yerleştirilen yazılar. Zemin her iki
  // temada da koyu olduğundan renkler SABİTTİR. Buraya tema rengi miras alan
  // bir stil (örn. titleSmall) koyulursa açık modda yazı siyaha döner ve
  // koyu degradenin üstünde okunmaz olur — bu stiller tam olarak onu önler.
  static const TextStyle onImageTitle = TextStyle(
    fontFamily: _font,
    fontSize: 15,
    fontWeight: AppFonts.title,
    color: Colors.white,
    height: 1.25,
  );

  static const TextStyle onImageTitleLarge = TextStyle(
    fontFamily: _font,
    fontSize: 20,
    fontWeight: AppFonts.heading,
    color: Colors.white,
    height: 1.2,
    letterSpacing: -0.2,
  );

  /// Görsel üstü ikincil metin — restoran adı, konum gibi.
  static const TextStyle onImageCaption = TextStyle(
    fontFamily: _font,
    fontSize: 12,
    fontWeight: AppFonts.body,
    color: Color(0xCCFFFFFF),
    height: 1.4,
  );

  /// Görsel üstü ikincil metnin ikon rengiyle eşleşen tonu.
  static const Color onImageMuted = Color(0xCCFFFFFF);

  // ─── Puan ─────────────────────────────────────────────────────────────────
  // Rakamlar metin renginde; sarı yalnızca yıldız glifinde. Rakamın kendisi
  // sarı olunca açık zeminde okunmuyordu, koyu zeminde de her kart ekranda
  // iki ayrı vurgu rengiyle (turuncu + sarı) bağırıyordu.

  /// Değerlendirme adımındaki büyük puan.
  static const TextStyle scoreDisplay = TextStyle(
    fontFamily: _font,
    fontSize: 56,
    fontWeight: AppFonts.title,
    height: 1,
    letterSpacing: -1,
    fontFeatures: tabular,
  );

  /// Detay başlığındaki ortalama puan.
  static const TextStyle ratingLarge = TextStyle(
    fontFamily: _font,
    fontSize: 34,
    fontWeight: AppFonts.title,
    height: 1,
    letterSpacing: -0.6,
    fontFeatures: tabular,
  );

  /// Satır içi puan (4.8).
  static const TextStyle ratingSmall = TextStyle(
    fontFamily: _font,
    fontSize: 13,
    fontWeight: AppFonts.title,
    fontFeatures: tabular,
  );
}

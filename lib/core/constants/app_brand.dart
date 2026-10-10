/// Uygulamanın adı — tek yerde (Ekim 2026: Dishrate → Decouva).
///
/// Ad bir daha değişirse metinler buradan okur; değişmesi gereken diğer
/// yerler: `assets/branding/` görselleri (logo yazısı, açılış), iOS
/// `Info.plist` ve Android etiketi, paket kimliği. Türkçe ekler ada göre
/// elle yazılı ("Decouva’ya", "Decouva’yı", "Decouva’da"); ad değişirse
/// onlar da gözden geçirilmeli.
abstract final class AppBrand {
  /// Metinlerde geçen ad.
  static const String name = 'Decouva';

  /// Logo yazısı — hep küçük harf (Keşfet başlığı Poppins ile yazıyor).
  static const String wordmark = 'decouva';

  /// Adisyondaki üye kodunun ön eki ("DC-QFS2RG"). Yalnız gösterimde;
  /// sunucudaki kod ön eksiz.
  static const String memberCodePrefix = 'DC';
}

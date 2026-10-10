/// Uygulamanın dışarıya açılan adresleri — tek yerde.
///
/// Adresi `null` olan bağlantının satırı arayüzde hiç çizilmez: basınca bir
/// şey yapmayan öğe mağaza incelemesinde "yarım içerik" sayılıyor (1.6).
abstract final class AppLinks {
  /// Destek e-postası ("Bize ulaş"). Alan adı alındı (decouva.com, 9 Ekim);
  /// e-posta sağlayıcısı kurulana kadar (2.6) bu adrese giden posta geri döner.
  static const String supportEmail = 'destek@decouva.com';

  /// Gizlilik politikası sayfası. Web sitesi yayına girince (2.10)
  /// doldurulacak; o zamana kadar Ayarlar'daki satır görünmez.
  static const String? privacyPolicy = null;
}

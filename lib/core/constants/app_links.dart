/// Uygulamanın dışarıya açılan adresleri — tek yerde.
///
/// Adresi olmayan bağlantı için arayüze satır konmaz: basınca bir şey
/// yapmayan öğe mağaza incelemesinde "yarım içerik" sayılıyor (1.6).
abstract final class AppLinks {
  /// Destek e-postası ("Bize ulaş"). Gelen posta Cloudflare yönlendirmesiyle
  /// destek kutusuna düşer (2.6).
  static const String supportEmail = 'destek@decouva.com';

  /// Gizlilik politikası sayfası (2.10); Ayarlar'daki satır.
  static const String privacyPolicy = 'https://decouva.com/gizlilik';

  /// Kullanım şartlarının web'deki tam metni (2.10); şartlar panelinin
  /// altındaki bağlantı.
  static const String termsOfUse = 'https://decouva.com/kullanim-sartlari';
}

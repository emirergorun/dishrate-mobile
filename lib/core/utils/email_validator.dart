/// E-posta biçim kuralı — kayıt ekranında kullanılır.
/// Aynı kural backend'de `ValidEmail` ile de uygulanır (istemciye güvenilmez);
/// buradaki amaç kullanıcıya sunucuya gitmeden anında geri bildirim vermek.
///
/// Dart'ın veya Jakarta'nın gevşek kurallarından farklı olarak alan adında
/// nokta ve en az iki harflik uzantı arar; yani `ali@user` reddedilir.
/// Hiçbir biçim kuralı adresin gerçekten var olduğunu kanıtlamaz — onun için
/// doğrulama postası gerekir.
abstract final class EmailValidator {
  /// RFC 5321 üst sınırları.
  static const int maxLength = 254;
  static const int maxLocalPart = 64;

  static final _pattern = RegExp(
    r"^[A-Za-z0-9!#$%&'*+/=?^_`{|}~-]+"
    r"(?:\.[A-Za-z0-9!#$%&'*+/=?^_`{|}~-]+)*"
    r'@'
    r'(?:[A-Za-z0-9](?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?\.)+'
    r'[A-Za-z]{2,}$',
  );

  /// Geçersizse hata mesajı, geçerliyse null döner.
  static String? validate(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return 'E-posta gerekli';
    if (v.length > maxLength) return 'E-posta adresi çok uzun';

    final at = v.indexOf('@');
    if (at < 0) return 'E-posta adresi @ işareti içermeli';
    if (at > maxLocalPart) return 'E-posta adresinin @ öncesi kısmı çok uzun';

    if (!_pattern.hasMatch(v.toLowerCase())) {
      // En sık yapılan hata: uzantıyı unutmak. Ona özel mesaj verelim.
      final domain = v.substring(at + 1);
      if (!domain.contains('.')) {
        return 'Alan adı eksik görünüyor (örn. ad@ornek.com)';
      }
      return 'Geçerli bir e-posta adresi gir (örn. ad@ornek.com)';
    }
    return null;
  }

  static bool isValid(String? value) => validate(value) == null;
}

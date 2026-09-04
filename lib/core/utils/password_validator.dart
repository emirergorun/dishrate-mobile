/// Şifre kuralları — kayıt ve şifre değiştirme ekranlarında ortak kullanılır.
/// Aynı kurallar backend'de de doğrulanır (istemciye güvenilmez).
abstract final class PasswordValidator {
  static const int minLength = 8;

  // Türkçe harfler de büyük/küçük sayılır
  static final _upper = RegExp(r'[A-ZÇĞİÖŞÜ]');
  static final _lower = RegExp(r'[a-zçğıöşü]');
  static final _digit = RegExp(r'\d');
  static final _special = RegExp(r'[^A-Za-zÇĞİÖŞÜçğıöşü0-9]');

  /// Kurallara uymuyorsa hata mesajı, uyuyorsa null döner.
  static String? validate(String? value) {
    final v = value ?? '';
    if (v.isEmpty) return 'Şifre gerekli';
    if (v.length < minLength) return 'Şifre en az $minLength karakter olmalı';
    if (!_upper.hasMatch(v)) return 'En az bir büyük harf içermeli';
    if (!_lower.hasMatch(v)) return 'En az bir küçük harf içermeli';
    if (!_digit.hasMatch(v)) return 'En az bir rakam içermeli';
    if (!_special.hasMatch(v)) return 'En az bir özel karakter içermeli (örn. !, ?, *)';
    return null;
  }

  static bool isValid(String? value) => validate(value) == null;

  /// Kullanıcıya gösterilecek kural listesi (canlı kontrol için).
  static List<({String label, bool Function(String) test})> get rules => [
        (label: 'En az $minLength karakter', test: (v) => v.length >= minLength),
        (label: 'Bir büyük harf', test: (v) => _upper.hasMatch(v)),
        (label: 'Bir küçük harf', test: (v) => _lower.hasMatch(v)),
        (label: 'Bir rakam', test: (v) => _digit.hasMatch(v)),
        (label: 'Bir özel karakter', test: (v) => _special.hasMatch(v)),
      ];
}

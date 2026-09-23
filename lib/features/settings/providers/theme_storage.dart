import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Tema tercihini cihazda saklar.
///
/// Kayıt yoksa [ThemeMode.system] geçerlidir: uygulama ilk kurulduğunda
/// cihazın görünüm ayarını izler. Kullanıcı Ayarlar'dan bir seçim yaptığı
/// anda o seçim yazılır ve uygulama kapanıp açılsa da korunur.
///
/// Konum tercihi gibi bu da `flutter_secure_storage` üzerinde duruyor:
/// cihazda veri saklamanın uygulamadaki tek yolu bu.
class ThemeStorage {
  ThemeStorage._();
  static final ThemeStorage instance = ThemeStorage._();

  static const _storage = FlutterSecureStorage();

  /// Kalıcı anahtar — değiştirilirse kullanıcının seçimi kaybolur.
  static const _themeModeKey = 'dishrate_theme_mode';

  Future<ThemeMode> read() async {
    try {
      final value = await _storage.read(key: _themeModeKey);
      return switch (value) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };
    } catch (_) {
      // Okunamazsa cihaz ayarı geçerli; açılışı bloklamaz.
      return ThemeMode.system;
    }
  }

  Future<void> write(ThemeMode mode) async {
    final value = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };
    try {
      await _storage.write(key: _themeModeKey, value: value);
    } catch (_) {
      // Yazılamazsa tercih bu oturumda geçerli kalır, sessiz geçilir.
    }
  }
}

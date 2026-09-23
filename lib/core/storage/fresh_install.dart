import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Uygulama silinip yeniden kurulduğunda cihazda kalan verileri temizler.
///
/// iOS Keychain (ve Android Keystore) uygulamayla birlikte silinmiyor:
/// kullanıcı uygulamayı silip yeniden kursa bile oturumu, tema tercihi ve
/// kayıtlı şehri yerinde duruyordu — yeniden kuran kişi eski hesaba girmiş
/// olarak açıyordu. Telefonunu satan ya da başkasına veren biri için bu
/// sessiz bir veri sızıntısı (karar 23 Eylül).
///
/// Ayrım şuradan geliyor: `SharedPreferences` (iOS'ta NSUserDefaults)
/// uygulamayla **birlikte siliniyor**. Bayrağı orada tutuyoruz; bayrak yoksa
/// bu, kurulumdan sonraki ilk açılıştır.
class FreshInstall {
  FreshInstall._();

  static const _flagKey = 'dishrate_installed';

  /// Kurulumdan sonraki ilk açılışta güvenli depoyu boşaltır.
  ///
  /// `main`'de, tema okunmadan ve `runApp`'tan **önce** çağrılmalı; sonra
  /// çağrılırsa silinecek tercih okunmuş olur.
  static Future<void> clearIfNeeded() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(_flagKey) ?? false) return;
      // Token, tema ve kayıtlı konum aynı depoda; hepsi birden gitsin.
      await const FlutterSecureStorage().deleteAll();
      await prefs.setBool(_flagKey, true);
    } catch (_) {
      // Depo okunamazsa uygulama yine de açılmalı: temizlik bir sonraki
      // açılışta tekrar denenir, kullanıcı en fazla oturumunu korumuş olur.
    }
  }
}

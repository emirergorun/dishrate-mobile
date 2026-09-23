import 'dart:io';

import '../constants/api_constants.dart';

/// Sunucu yerel ağdaysa iOS'un yerel ağ izin penceresini açılışta çıkarır.
///
/// Yalnızca geliştirmeyi ilgilendirir. Telefondaki sürüm sunucuya Mac'in yerel
/// adresinden bağlanıyor (`*.local`); iOS yerel ağa ilk bağlantıda izin
/// soruyor ve o bağlantı izin beklenirken düşüyor. Uygulama silinip
/// kurulunca izin sıfırlanıyor, oturum da kapandığı için açılışta ağ isteği
/// yok — ilk bağlantı giriş isteği oluyordu ve kullanıcı ilk denemede
/// "sunucuya bağlanılamadı" görüyordu (24 Eylül). Burada sunucunun portuna
/// kısa bir bağlantı açıp kapatıyoruz; pencere kullanıcı daha bir şey
/// yazmadan çıkıyor.
///
/// Yayındaki sunucu internette olduğu için orada hiçbir şey yapmaz.
Future<void> warmUpLocalNetwork() async {
  final uri = Uri.tryParse(ApiConstants.baseUrl);
  if (uri == null || !_isLocalHost(uri.host)) return;
  try {
    final socket = await Socket.connect(
      uri.host,
      uri.port,
      timeout: const Duration(seconds: 3),
    );
    socket.destroy();
  } catch (_) {
    // Bağlantının kendisi önemli değil; amaç yalnızca izni sordurmak.
  }
}

bool _isLocalHost(String host) {
  if (host.endsWith('.local')) return true;
  final parts = host.split('.').map(int.tryParse).toList();
  if (parts.length != 4 || parts.contains(null)) return false;
  final a = parts[0]!, b = parts[1]!;
  return a == 10 ||
      (a == 172 && b >= 16 && b <= 31) ||
      (a == 192 && b == 168) ||
      (a == 169 && b == 254);
}

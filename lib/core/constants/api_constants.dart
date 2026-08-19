abstract final class ApiConstants {
  /// API adresi. Derleme sırasında dışarıdan verilebilir:
  ///   flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080/api/v1
  ///
  /// Verilmezse localhost kullanılır (web ve iOS simülatörü için doğru).
  /// Android emülatör: 10.0.2.2 · Fiziksel cihaz: bilgisayarın LAN IP'si
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8080/api/v1',
  );

  // Auth endpoint'leri
  static const String authLogin = '/auth/login';
  static const String authRegister = '/auth/register';
  static const String authRefresh = '/auth/refresh';
  static const String authLogout = '/auth/logout';

  // Restoran başvurusu
  static const String applications = '/applications';

  // Admin
  static const String admin = '/admin';

  // Dosya yükleme & bildirimler
  static const String files = '/files';
  static const String notifications = '/notifications';

  // Diğer endpoint'ler
  static const String users = '/users';
  static const String restaurants = '/restaurants';
  static const String menuItems = '/menu-items';
  static const String ratings = '/ratings';
  static const String wishlist = '/wishlist';
  static const String categories = '/menu-items/categories';
  static const String addresses = '/restaurants/addresses';

  // Zaman aşımı (saniye)
  static const int connectTimeout = 10;
  static const int receiveTimeout = 15;
}

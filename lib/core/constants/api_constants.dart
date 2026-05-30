abstract final class ApiConstants {
  // Geliştirme ortamında localhost.
  // Android emülatörde 10.0.2.2, fiziksel cihazda bilgisayarın LAN IP'si kullanılır.
  // Web: localhost | Android emülatör: 10.0.2.2 | Fiziksel cihaz: LAN IP
  static const String baseUrl = 'http://localhost:8080/api/v1';

  // Endpoint'ler
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

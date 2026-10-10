import 'package:dio/dio.dart';

/// Sunucu hatasından kullanıcıya gösterilecek metin.
///
/// Yalnızca 400 ve 429'da sunucunun `message`'ı kullanılır: 400'de mesaj
/// kullanıcının düzeltebileceği bir şeyi anlatıyor ("Yorumunda uygunsuz bir
/// ifade var…"), 429'da ne kadar beklemesi gerektiğini (2.9).
/// Diğer hatalarda çağıranın genel mesajı ([fallback]) gösterilir; 500'ün
/// metni kullanıcıya bir şey söylemez.
String userMessageFor(Object error, {required String fallback}) {
  if (error is DioException && error.response?.statusCode == 429) {
    final data = error.response?.data;
    return data is Map && data['message'] is String
        ? data['message'] as String
        : 'Çok fazla istek, biraz sonra tekrar dene.';
  }
  if (error is DioException && error.response?.statusCode == 400) {
    final data = error.response?.data;
    // Alan doğrulamasında genel mesaj ("alanları kontrol et") yerine alana
    // özel olan ("username: …") gösterilir.
    final details = data is Map ? data['validationErrors'] : null;
    if (details is List && details.isNotEmpty && details.first is String) {
      final first = details.first as String;
      final i = first.indexOf(': ');
      return i == -1 ? first : first.substring(i + 2);
    }
    if (data is Map && data['message'] is String) {
      return data['message'] as String;
    }
  }
  return fallback;
}

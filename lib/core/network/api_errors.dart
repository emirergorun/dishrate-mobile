import 'package:dio/dio.dart';

/// Sunucu hatasından kullanıcıya gösterilecek metin.
///
/// Yalnızca 400'de sunucunun `message`'ı kullanılır: orada mesaj kullanıcının
/// düzeltebileceği bir şeyi anlatıyor ("Yorumunda uygunsuz bir ifade var…").
/// Diğer hatalarda çağıranın genel mesajı ([fallback]) gösterilir; 500'ün
/// metni kullanıcıya bir şey söylemez.
String userMessageFor(Object error, {required String fallback}) {
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

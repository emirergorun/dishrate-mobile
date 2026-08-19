import '../constants/api_constants.dart';
import 'dio_client.dart';
import '../../shared/models/notification_model.dart';

class NotificationRepository {
  NotificationRepository._();
  static final NotificationRepository instance = NotificationRepository._();

  final _dio = DioClient.instance;

  /// Giriş yapmış kullanıcının bildirimleri (en yeni önce).
  Future<List<NotificationModel>> getMyNotifications() async {
    final response = await _dio.get(ApiConstants.notifications);
    final list = response.data as List<dynamic>;
    return list
        .map((e) => NotificationModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<int> unreadCount() async {
    final response =
        await _dio.get('${ApiConstants.notifications}/unread-count');
    return (response.data as Map)['count'] as int? ?? 0;
  }

  Future<void> markRead(int id) async {
    await _dio.patch('${ApiConstants.notifications}/$id/read');
  }

  Future<void> markAllRead() async {
    await _dio.patch('${ApiConstants.notifications}/read-all');
  }
}

import 'api_client.dart';
import '../../models/app_notification.dart';

/// Mirrors NotificationBell.js's three calls:
/// GET /notifications, PUT /notifications/:id/read, PUT /notifications/read-all/mark.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  Future<List<AppNotification>> getNotifications() async {
    final res = await ApiClient.instance.dio.get('/notifications');
    final data = res.data as List;
    return data.map((e) => AppNotification.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> markRead(int id) async {
    await ApiClient.instance.dio.put('/notifications/$id/read');
  }

  Future<void> markAllRead() async {
    await ApiClient.instance.dio.put('/notifications/read-all/mark');
  }
}
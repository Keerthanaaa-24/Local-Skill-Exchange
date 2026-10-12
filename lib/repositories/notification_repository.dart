import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/notification_model.dart';
import '../services/api_client.dart';

class NotificationRepository {
  final ApiClient _apiClient;

  NotificationRepository(this._apiClient);

  Future<List<NotificationModel>> getNotifications() async {
    try {
      final response = await _apiClient.dio.get('/notifications');
      final data = response.data as List;
      return data.map((e) => NotificationModel.fromJson(e)).toList();
    } catch (e) {
      throw Exception('Failed to load notifications: $e');
    }
  }

  Future<List<NotificationModel>> getUnreadNotifications() async {
  // Unread endpoint not implemented; compute locally from fetched notifications.
  throw UnimplementedError('getUnreadNotifications is not supported; use local unread count.');
}

  Future<void> markAsRead(int id) async {
    try {
      await _apiClient.dio.post('/notifications/$id/read');
    } catch (e) {
      throw Exception('Failed to mark notification as read: $e');
    }
  }

  Future<void> markAllAsRead() async {
    try {
      await _apiClient.dio.post('/notifications/read-all');
    } catch (e) {
      throw Exception('Failed to mark all notifications as read: $e');
    }
  }

  Future<void> deleteNotification(int id) async {
    try {
      await _apiClient.dio.delete('/notifications/$id');
    } catch (e) {
      throw Exception('Failed to delete notification: $e');
    }
  }

  Future<void> clearAllNotifications() async {
    try {
      await _apiClient.dio.delete('/notifications');
    } catch (e) {
      throw Exception('Failed to clear notifications: $e');
    }
  }
}

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository(apiClient);
});

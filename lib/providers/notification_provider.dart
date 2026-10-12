import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/notification_model.dart';
import '../repositories/notification_repository.dart';

class NotificationNotifier extends AsyncNotifier<List<NotificationModel>> {
  @override
  Future<List<NotificationModel>> build() async {
    return _fetchNotifications();
  }

  Future<List<NotificationModel>> _fetchNotifications() async {
    final repo = ref.read(notificationRepositoryProvider);
    return await repo.getNotifications();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchNotifications());
  }

  Future<void> markAsRead(int id) async {
    if (!state.hasValue) return;

    final currentNotifications = state.value!;
    final index = currentNotifications.indexWhere((n) => n.id == id);
    if (index == -1 || currentNotifications[index].isRead) return;

    // Optimistically update state
    final updatedNotification = currentNotifications[index].copyWith(isRead: true);
    final updatedList = List<NotificationModel>.from(currentNotifications)..[index] = updatedNotification;
    state = AsyncValue.data(updatedList);

    try {
      await ref.read(notificationRepositoryProvider).markAsRead(id);
    } catch (e) {
      // Revert if API fails
      state = AsyncValue.data(currentNotifications);
      throw Exception('Failed to mark notification as read');
    }
  }

  Future<void> markAllAsRead() async {
    if (!state.hasValue) return;

    final currentNotifications = state.value!;
    
    // Optimistically update
    final updatedList = currentNotifications.map((n) => n.copyWith(isRead: true)).toList();
    state = AsyncValue.data(updatedList);

    try {
      await ref.read(notificationRepositoryProvider).markAllAsRead();
    } catch (e) {
      state = AsyncValue.data(currentNotifications);
      throw Exception('Failed to mark all as read');
    }
  }

  Future<void> deleteNotification(int id) async {
    if (!state.hasValue) return;

    final currentNotifications = state.value!;
    final index = currentNotifications.indexWhere((n) => n.id == id);
    if (index == -1) return;

    // Optimistically update
    final updatedList = List<NotificationModel>.from(currentNotifications)..removeAt(index);
    state = AsyncValue.data(updatedList);

    try {
      await ref.read(notificationRepositoryProvider).deleteNotification(id);
    } catch (e) {
      state = AsyncValue.data(currentNotifications);
      throw Exception('Failed to delete notification');
    }
  }
}

final notificationNotifierProvider = AsyncNotifierProvider<NotificationNotifier, List<NotificationModel>>(() {
  return NotificationNotifier();
});

final unreadNotificationCountProvider = Provider<int>((ref) {
  final notificationsState = ref.watch(notificationNotifierProvider);
  return notificationsState.maybeWhen(
    data: (notifications) => notifications.where((n) => !n.isRead).length,
    orElse: () => 0,
  );
});

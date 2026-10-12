import 'package:flutter/foundation.dart';

/// Stub interface for handling Push Notifications / FCM.
/// Do NOT integrate Firebase yet.
class PushNotificationService {
  Future<void> initialize() async {
    // TODO: Initialize Firebase Messaging & Local Notifications
    debugPrint('PushNotificationService: initialize() called.');
  }

  Future<String?> getToken() async {
    // TODO: Get FCM device token
    debugPrint('PushNotificationService: getToken() called.');
    return null;
  }

  void setupForegroundHandlers() {
    // TODO: Listen to FirebaseMessaging.onMessage
    debugPrint('PushNotificationService: setupForegroundHandlers() called.');
  }

  void setupBackgroundHandlers() {
    // TODO: Register FirebaseMessaging.onBackgroundMessage
    debugPrint('PushNotificationService: setupBackgroundHandlers() called.');
  }

  void handleNotificationClick() {
    // TODO: Handle routing when clicking a system notification
    debugPrint('PushNotificationService: handleNotificationClick() called.');
  }
}

final pushNotificationService = PushNotificationService();

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

import '../services/api_client.dart';

final userProvider = StateNotifierProvider<UserNotifier, User?>((ref) {
  return UserNotifier();
});

class UserNotifier extends StateNotifier<User?> {
  UserNotifier() : super(null) {
    refreshUser();
  }

  Future<void> refreshUser() async {
    final user = await authService.getCurrentUser();
    state = user;
  }
}

final nearbyUsersProvider = FutureProvider<List<User>>((ref) async {
  try {
    final response = await apiClient.dio.get('/users/nearby');
    final List<dynamic> data = (response.data is List) ? response.data : (response.data['data'] ?? []);
    return data.map((e) => User.fromJson(Map<String, dynamic>.from(e))).toList();
  } catch (e) {
    debugPrint('Error fetching nearby users: $e');
    throw Exception('Failed to connect to the server. Please try again later.');
  }
});

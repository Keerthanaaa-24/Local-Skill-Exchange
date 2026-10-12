import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/api_client.dart';

class AdminStatsNotifier extends AsyncNotifier<Map<String, dynamic>> {
  @override
  Future<Map<String, dynamic>> build() async => _fetchStats();

  Future<Map<String, dynamic>> _fetchStats() async {
    final response = await apiClient.dio.get('/admin/stats');
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchStats());
  }
}

final adminStatsProvider = AsyncNotifierProvider<AdminStatsNotifier, Map<String, dynamic>>(() => AdminStatsNotifier());

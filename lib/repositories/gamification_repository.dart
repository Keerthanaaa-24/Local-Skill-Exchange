import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/network/api_client.dart';
import '../providers/auth_provider.dart';
import '../models/gamification_models.dart';

class GamificationRepository {
  final ApiClient _apiClient;

  GamificationRepository(this._apiClient);

  Future<GamificationDashboardModel> getDashboard() async {
    try {
      final response = await _apiClient.dio.get('/gamification/dashboard');
      return GamificationDashboardModel.fromJson(Map<String, dynamic>.from(response.data));
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<AchievementModel>> getAchievements() async {
    try {
      final response = await _apiClient.dio.get('/gamification/achievements');
      final List raw = response.data is List ? response.data : [];
      return raw.map((e) => AchievementModel.fromJson(Map<String, dynamic>.from(e))).toList();
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<LeaderboardEntryModel>> getLeaderboard({int limit = 20}) async {
    try {
      final response = await _apiClient.dio.get('/gamification/leaderboard', queryParameters: {'limit': limit});
      final List raw = response.data is List ? response.data : [];
      return raw.map((e) => LeaderboardEntryModel.fromJson(Map<String, dynamic>.from(e))).toList();
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<GrowthMilestoneModel>> getGrowthTimeline(int userId, {int limit = 25}) async {
    try {
      final response = await _apiClient.dio.get('/gamification/timeline/$userId', queryParameters: {'limit': limit});
      final List raw = response.data is List ? response.data : [];
      return raw.map((e) => GrowthMilestoneModel.fromJson(Map<String, dynamic>.from(e))).toList();
    } catch (e) {
      throw _handleError(e);
    }
  }

  Exception _handleError(dynamic error) {
    if (error is DioException) {
      final data = error.response?.data;
      String? msg;
      if (data is Map) {
        msg = data['detail'] ?? data['message'];
      }
      return Exception(msg ?? 'Gamification operation failed');
    }
    return Exception(error.toString());
  }
}

final gamificationRepositoryProvider = Provider<GamificationRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return GamificationRepository(apiClient);
});

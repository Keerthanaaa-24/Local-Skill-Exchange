import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/network/api_client.dart';
import '../providers/auth_provider.dart';
import '../models/community_models.dart';

class CommunityRepository {
  final ApiClient _apiClient;

  CommunityRepository(this._apiClient);

  Future<List<CommunityActivityItem>> getCommunityActivity({int limit = 20}) async {
    try {
      final response = await _apiClient.dio.get('/community/activity', queryParameters: {'limit': limit});
      final List raw = response.data is List ? response.data : [];
      return raw.map((e) => CommunityActivityItem.fromJson(Map<String, dynamic>.from(e))).toList();
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<CommunityActivityItem>> getUserActivity(int userId, {int limit = 10}) async {
    try {
      final response = await _apiClient.dio.get('/community/activity/user/$userId', queryParameters: {'limit': limit});
      final List raw = response.data is List ? response.data : [];
      return raw.map((e) => CommunityActivityItem.fromJson(Map<String, dynamic>.from(e))).toList();
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<CommunityProfileModel> getCommunityProfile(int userId) async {
    try {
      final response = await _apiClient.dio.get('/community/profile/$userId');
      final Map<String, dynamic> data = Map<String, dynamic>.from(response.data);
      return CommunityProfileModel.fromJson(data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<CommunityDiscoveryModel> getCommunityDiscovery() async {
    try {
      final response = await _apiClient.dio.get('/community/discovery');
      final Map<String, dynamic> data = Map<String, dynamic>.from(response.data);
      return CommunityDiscoveryModel.fromJson(data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> reportUser(int reportedUserId, String reason, {String? description}) async {
    try {
      await _apiClient.dio.post('/safety/report', data: {
        'reported_user_id': reportedUserId,
        'reason': reason,
        'description': description,
      });
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> blockUser(int userId) async {
    try {
      await _apiClient.dio.post('/safety/block/$userId');
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> unblockUser(int userId) async {
    try {
      await _apiClient.dio.delete('/safety/block/$userId');
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<int>> getBlockedUsers() async {
    try {
      final response = await _apiClient.dio.get('/safety/blocks');
      final List raw = response.data is List ? response.data : [];
      return raw.map((e) => e as int).toList();
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<UserReportModel>> getAdminReports({String? status}) async {
    try {
      final response = await _apiClient.dio.get(
        '/admin/reports',
        queryParameters: status != null ? {'status': status} : null,
      );
      final List raw = response.data is List ? response.data : [];
      return raw.map((e) => UserReportModel.fromJson(Map<String, dynamic>.from(e))).toList();
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> updateReportStatus(int reportId, String status) async {
    try {
      await _apiClient.dio.post('/admin/reports/$reportId/status', data: {'status': status});
    } catch (e) {
      throw _handleError(e);
    }
  }

  Exception _handleError(dynamic error) {
    if (error is DioException) {
      final msg = error.response?.data is Map
          ? error.response?.data['detail'] ?? error.message
          : error.message;
      return Exception(msg ?? 'Community operation failed');
    }
    return Exception(error.toString());
  }
}

final communityRepositoryProvider = Provider<CommunityRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return CommunityRepository(apiClient);
});

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../models/skill_model.dart';
import '../models/recommendation_model.dart';
import '../services/api_client.dart';

class SkillRepository {
  final ApiClient _apiClient;

  SkillRepository(this._apiClient);

  Future<List<RecommendationModel>> getRecommendations({int page = 1, int limit = 20}) async {
    try {
      final response = await _apiClient.dio.get('/recommendations/', queryParameters: {
        'page': page,
        'limit': limit,
      });
      final List<dynamic> data = response.data['data'] ?? response.data;
      return data.map((json) => RecommendationModel.fromJson(json)).toList();
    } catch (e) {
      throw _handleError(e);
    }
  }


  Future<List<SkillModel>> getSkills({int page = 1, int limit = 50, String? category, String? categories, String? q}) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
      };
      final cat = category ?? categories;
      if (cat != null && cat.isNotEmpty && cat != 'All') {
        queryParams['category'] = cat;
      }
      if (q != null && q.trim().isNotEmpty) {
        queryParams['q'] = q.trim();
      }

      final response = await _apiClient.dio.get('/skills/', queryParameters: queryParams);
      final List<dynamic> data = response.data['data'] ?? response.data;
      return data.map((json) => SkillModel.fromJson(json)).toList();
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, int>> getCategoryCounts() async {
    try {
      final response = await _apiClient.dio.get('/skills/categories');
      final List<dynamic> data = response.data is List ? response.data : response.data['data'] ?? [];
      final map = <String, int>{};
      for (final item in data) {
        if (item is Map && item['category'] != null && item['count'] != null) {
          map[item['category'].toString()] = int.tryParse(item['count'].toString()) ?? 0;
        }
      }
      return map;
    } catch (e) {
      return {};
    }
  }

  Future<SkillModel> getSkillById(int id) async {
    try {
      final response = await _apiClient.dio.get('/skills/$id');
      return SkillModel.fromJson(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<SkillModel>> searchSkills(String query) async {
    try {
      final response = await _apiClient.dio.get('/skills/search', queryParameters: {'q': query});
      final List<dynamic> data = response.data['data'] ?? response.data;
      return data.map((json) => SkillModel.fromJson(json)).toList();
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<SkillModel>> getSkillsByCategory(String categoryName) async {
    try {
      final response = await _apiClient.dio.get('/skills/category/$categoryName');
      final List<dynamic> data = response.data['data'] ?? response.data;
      return data.map((json) => SkillModel.fromJson(json)).toList();
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> createSkill(SkillModel skill) async {
    try {
      await _apiClient.dio.post('/skills/', data: skill.toJson());
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> updateSkill(int id, Map<String, dynamic> updates) async {
    try {
      await _apiClient.dio.patch('/skills/$id', data: updates);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> deleteSkill(int id) async {
    try {
      await _apiClient.dio.delete('/skills/$id');
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> offerSkill(int id) async {
    try {
      await _apiClient.dio.post('/skills/$id/offer');
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> requestSkill(int id) async {
    try {
      await _apiClient.dio.post('/skills/$id/request');
    } catch (e) {
      throw _handleError(e);
    }
  }

  Exception _handleError(dynamic error) {
    if (error is DioException) {
      if (error.response?.statusCode == 401) {
        return Exception('Unauthorized');
      } else if (error.response?.statusCode == 500) {
        return Exception('Server Error');
      } else if (error.type == DioExceptionType.connectionError || error.type == DioExceptionType.receiveTimeout) {
        return Exception('Network Error: Please check your connection.');
      }
      return Exception(error.response?.data['detail'] ?? 'An error occurred');
    }
    return Exception(error.toString());
  }
}

final skillRepositoryProvider = Provider<SkillRepository>((ref) {
  return SkillRepository(apiClient);
});

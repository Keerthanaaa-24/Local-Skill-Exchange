import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_client.dart';
import '../models/skill_passport_model.dart';

class PassportRepository {
  final ApiClient _apiClient;

  PassportRepository(this._apiClient);

  // Fetch current user's authenticated Skill Passport
  Future<SkillPassportModel> getMyPassport() async {
    try {
      final response = await _apiClient.dio.get('/passport/me');
      final dynamic raw = response.data;
      final Map<String, dynamic> data = (raw is Map && raw.containsKey('data')) ? raw['data'] : raw;
      return SkillPassportModel.fromJson(data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  // Fetch safe public Skill Passport for any user
  Future<SkillPassportModel> getPublicPassport(int userId) async {
    try {
      final response = await _apiClient.dio.get('/passport/user/$userId');
      final dynamic raw = response.data;
      final Map<String, dynamic> data = (raw is Map && raw.containsKey('data')) ? raw['data'] : raw;
      return SkillPassportModel.fromJson(data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Exception _handleError(dynamic error) {
    if (error is DioException) {
      if (error.response?.statusCode == 401) {
        return Exception('Unauthorized: Please log in');
      } else if (error.response?.statusCode == 404) {
        return Exception(error.response?.data['detail'] ?? 'Passport not found');
      } else if (error.response?.statusCode == 500) {
        return Exception('Server Error: Please try again later');
      } else if (error.type == DioExceptionType.connectionError || error.type == DioExceptionType.receiveTimeout) {
        return Exception('Network Error: Please check your connection.');
      }
      return Exception(error.response?.data['detail'] ?? error.message ?? 'An error occurred');
    }
    return Exception(error.toString());
  }
}

// Riverpod provider for PassportRepository
final passportRepositoryProvider = Provider<PassportRepository>((ref) {
  return PassportRepository(apiClient);
});

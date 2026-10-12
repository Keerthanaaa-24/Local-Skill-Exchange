import 'package:dio/dio.dart';


import '../services/api_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/learning_path_model.dart';
import '../models/lesson_model.dart';
import '../models/learning_progress_model.dart';
import '../models/practice_question_model.dart';
import '../models/practice_result_model.dart';
import '../models/practice_attempt_model.dart';
import '../models/quiz_models.dart';

class LearningRepository {
  final ApiClient _apiClient;

  LearningRepository(this._apiClient);

  List<dynamic> _extractList(dynamic responseData) {
    if (responseData is List) {
      return responseData;
    }
    if (responseData is Map && responseData.containsKey('data')) {
      final inner = responseData['data'];
      if (inner is List) return inner;
    }
    return [];
  }

  // Fetch all learning paths
  Future<List<LearningPathModel>> getLearningPaths() async {
    try {
      final response = await _apiClient.dio.get('/learning/paths');
      final list = _extractList(response.data);
      return list.map((json) => LearningPathModel.fromJson(Map<String, dynamic>.from(json))).toList();
    } catch (e) {
      throw _handleError(e);
    }
  }

  // Fetch learning path for a skill (dynamic on-demand generation)
  Future<LearningPathModel> getPathBySkill(int skillId) async {
    try {
      final response = await _apiClient.dio.get('/learning/paths/skill/$skillId');
      final dynamic raw = response.data;
      final Map<String, dynamic> data = (raw is Map && raw.containsKey('data'))
          ? Map<String, dynamic>.from(raw['data'])
          : Map<String, dynamic>.from(raw);
      return LearningPathModel.fromJson(data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  // Fetch a single learning path by ID
  Future<LearningPathModel> getLearningPathById(int id) async {
    try {
      final response = await _apiClient.dio.get('/learning/paths/$id');
      final dynamic raw = response.data;
      final Map<String, dynamic> data = (raw is Map && raw.containsKey('data'))
          ? Map<String, dynamic>.from(raw['data'])
          : Map<String, dynamic>.from(raw);
      return LearningPathModel.fromJson(data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  // Fetch lessons for a particular learning path
  Future<List<LessonModel>> getLessons(int learningPathId) async {
    try {
      final response = await _apiClient.dio.get('/learning/paths/$learningPathId/lessons');
      final list = _extractList(response.data);
      return list.map((json) => LessonModel.fromJson(Map<String, dynamic>.from(json))).toList();
    } catch (e) {
      throw _handleError(e);
    }
  }

  // Start learning for a specific path
  Future<void> startLearning(int learningPathId) async {
    try {
      await _apiClient.dio.post('/learning/paths/$learningPathId/start');
    } catch (e) {
      throw _handleError(e);
    }
  }

  // Get the current user's learning progress list
  Future<List<LearningProgressModel>> getUserProgress() async {
    try {
      final response = await _apiClient.dio.get('/learning/progress');
      final list = _extractList(response.data);
      return list.map((json) => LearningProgressModel.fromJson(Map<String, dynamic>.from(json))).toList();
    } catch (e) {
      throw _handleError(e);
    }
  }

  // Get user learning dashboard summary
  Future<LearningDashboardModel> getLearningDashboard() async {
    try {
      final response = await _apiClient.dio.get('/learning/dashboard/me');
      final dynamic raw = response.data;
      final Map<String, dynamic> data = (raw is Map && raw.containsKey('data'))
          ? Map<String, dynamic>.from(raw['data'])
          : Map<String, dynamic>.from(raw);
      return LearningDashboardModel.fromJson(data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  // Get a specific progress entry by ID
  Future<LearningProgressModel> getProgressById(int id) async {
    try {
      final response = await _apiClient.dio.get('/learning/progress/$id');
      final dynamic raw = response.data;
      final Map<String, dynamic> data = (raw is Map && raw.containsKey('data'))
          ? Map<String, dynamic>.from(raw['data'])
          : Map<String, dynamic>.from(raw);
      return LearningProgressModel.fromJson(data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  // Mark a lesson as completed
  Future<void> completeLesson(int lessonId) async {
    try {
      await _apiClient.dio.post('/learning/lessons/$lessonId/complete');
    } catch (e) {
      throw _handleError(e);
    }
  }

  // Fetch practice questions for a lesson
  Future<List<PracticeQuestionModel>> getPracticeQuestions(int lessonId) async {
    try {
      final response = await _apiClient.dio.get('/learning/lessons/$lessonId/practice');
      final list = _extractList(response.data);
      return list.map((json) => PracticeQuestionModel.fromJson(Map<String, dynamic>.from(json))).toList();
    } catch (e) {
      throw _handleError(e);
    }
  }

  // Submit practice answers for server-side evaluation
  Future<PracticeResultModel> submitPractice(int lessonId, List<Map<String, String>> answers) async {
    try {
      final response = await _apiClient.dio.post(
        '/learning/lessons/$lessonId/practice/submit',
        data: {'answers': answers},
      );
      final dynamic raw = response.data;
      final Map<String, dynamic> data = (raw is Map && raw.containsKey('data'))
          ? Map<String, dynamic>.from(raw['data'])
          : Map<String, dynamic>.from(raw);
      return PracticeResultModel.fromJson(data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  // Get practice attempt history for a lesson
  Future<List<PracticeAttemptModel>> getPracticeHistory(int lessonId) async {
    try {
      final response = await _apiClient.dio.get('/learning/lessons/$lessonId/practice/history');
      final list = _extractList(response.data);
      return list.map((json) => PracticeAttemptModel.fromJson(Map<String, dynamic>.from(json))).toList();
    } catch (e) {
      throw _handleError(e);
    }
  }

  // Fetch quiz for a learning path
  Future<QuizModel> getPathQuiz(int pathId) async {
    try {
      final response = await _apiClient.dio.get('/learning/paths/$pathId/quiz');
      final dynamic raw = response.data;
      final Map<String, dynamic> data = (raw is Map && raw.containsKey('data'))
          ? Map<String, dynamic>.from(raw['data'])
          : Map<String, dynamic>.from(raw);
      return QuizModel.fromJson(data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  // Submit quiz answers
  Future<QuizResultModel> submitQuiz(int quizId, List<Map<String, dynamic>> answers, int durationSeconds) async {
    try {
      final response = await _apiClient.dio.post(
        '/learning/quizzes/$quizId/submit',
        data: {
          'answers': answers,
          'duration_seconds': durationSeconds,
        },
      );
      final dynamic raw = response.data;
      final Map<String, dynamic> data = (raw is Map && raw.containsKey('data'))
          ? Map<String, dynamic>.from(raw['data'])
          : Map<String, dynamic>.from(raw);
      return QuizResultModel.fromJson(data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  // Get quiz attempt history
  Future<List<QuizAttemptModel>> getQuizAttempts(int quizId) async {
    try {
      final response = await _apiClient.dio.get('/learning/quizzes/$quizId/attempts');
      final list = _extractList(response.data);
      return list.map((json) => QuizAttemptModel.fromJson(Map<String, dynamic>.from(json))).toList();
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

// Riverpod provider for the repository
final learningRepositoryProvider = Provider<LearningRepository>((ref) {
  return LearningRepository(apiClient);
});

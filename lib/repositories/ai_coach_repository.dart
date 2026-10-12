import '../core/network/api_client.dart';
import '../models/ai_coach_models.dart';

class AiCoachRepository {
  final ApiClient _apiClient;

  AiCoachRepository(this._apiClient);

  Future<AiCoachSummaryModel> getCoachSummary() async {
    final response = await _apiClient.dio.get('/recommendations/coach/summary');
    return AiCoachSummaryModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<RoadmapStepModel>> getRoadmap() async {
    final response = await _apiClient.dio.get('/recommendations/coach/roadmap');
    final list = response.data as List;
    return list.map((e) => RoadmapStepModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<PracticeDiagnosticModel>> getPracticeDiagnostics() async {
    final response = await _apiClient.dio.get('/recommendations/coach/diagnostics');
    final list = response.data as List;
    return list.map((e) => PracticeDiagnosticModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<DailyGoalModel> getDailyGoal() async {
    final response = await _apiClient.dio.get('/recommendations/coach/daily-goal');
    return DailyGoalModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<SkillGrowthModel> getSkillGrowth() async {
    final response = await _apiClient.dio.get('/recommendations/coach/growth');
    return SkillGrowthModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<WeeklyGrowthInsightsModel> getWeeklyInsights() async {
    final response = await _apiClient.dio.get('/recommendations/coach/weekly-insights');
    return WeeklyGrowthInsightsModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<AdaptiveRecommendationModel>> getAdaptiveRecommendations() async {
    final response = await _apiClient.dio.get('/recommendations/coach/adaptive');
    final list = response.data as List;
    return list.map((e) => AdaptiveRecommendationModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<ExchangeSuggestionModel>> getExchangeSuggestions() async {
    final response = await _apiClient.dio.get('/recommendations/coach/exchanges');
    final list = response.data as List;
    return list.map((e) => ExchangeSuggestionModel.fromJson(e as Map<String, dynamic>)).toList();
  }
}

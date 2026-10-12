import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/ai_coach_models.dart';
import '../repositories/ai_coach_repository.dart';
import 'auth_provider.dart';

final aiCoachRepositoryProvider = Provider<AiCoachRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AiCoachRepository(apiClient);
});

final aiCoachSummaryProvider = FutureProvider.autoDispose<AiCoachSummaryModel>((ref) async {
  final repo = ref.watch(aiCoachRepositoryProvider);
  return await repo.getCoachSummary();
});

final aiCoachRoadmapProvider = FutureProvider.autoDispose<List<RoadmapStepModel>>((ref) async {
  final repo = ref.watch(aiCoachRepositoryProvider);
  return await repo.getRoadmap();
});

final aiCoachDailyGoalProvider = FutureProvider.autoDispose<DailyGoalModel>((ref) async {
  final repo = ref.watch(aiCoachRepositoryProvider);
  return await repo.getDailyGoal();
});

final aiCoachGrowthProvider = FutureProvider.autoDispose<SkillGrowthModel>((ref) async {
  final repo = ref.watch(aiCoachRepositoryProvider);
  return await repo.getSkillGrowth();
});

final aiCoachWeeklyInsightsProvider = FutureProvider.autoDispose<WeeklyGrowthInsightsModel>((ref) async {
  final repo = ref.watch(aiCoachRepositoryProvider);
  return await repo.getWeeklyInsights();
});

final aiCoachAdaptiveProvider = FutureProvider.autoDispose<List<AdaptiveRecommendationModel>>((ref) async {
  final repo = ref.watch(aiCoachRepositoryProvider);
  return await repo.getAdaptiveRecommendations();
});


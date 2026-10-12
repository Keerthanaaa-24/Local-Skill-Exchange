import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/gamification_models.dart';
import '../repositories/gamification_repository.dart';

final gamificationDashboardProvider = FutureProvider.autoDispose<GamificationDashboardModel>((ref) async {
  final repo = ref.watch(gamificationRepositoryProvider);
  return await repo.getDashboard();
});

final achievementsListProvider = FutureProvider.autoDispose<List<AchievementModel>>((ref) async {
  final repo = ref.watch(gamificationRepositoryProvider);
  return await repo.getAchievements();
});

final leaderboardProvider = FutureProvider.autoDispose<List<LeaderboardEntryModel>>((ref) async {
  final repo = ref.watch(gamificationRepositoryProvider);
  return await repo.getLeaderboard();
});

final growthTimelineProvider = FutureProvider.autoDispose.family<List<GrowthMilestoneModel>, int>((ref, userId) async {
  final repo = ref.watch(gamificationRepositoryProvider);
  return await repo.getGrowthTimeline(userId);
});

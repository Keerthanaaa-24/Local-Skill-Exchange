import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/community_models.dart';
import '../repositories/community_repository.dart';

final communityActivityProvider = FutureProvider.autoDispose<List<CommunityActivityItem>>((ref) async {
  final repo = ref.watch(communityRepositoryProvider);
  return await repo.getCommunityActivity();
});

final userActivityProvider = FutureProvider.autoDispose.family<List<CommunityActivityItem>, int>((ref, userId) async {
  final repo = ref.watch(communityRepositoryProvider);
  return await repo.getUserActivity(userId);
});

final communityProfileProvider = FutureProvider.autoDispose.family<CommunityProfileModel, int>((ref, userId) async {
  final repo = ref.watch(communityRepositoryProvider);
  return await repo.getCommunityProfile(userId);
});

final communityDiscoveryProvider = FutureProvider.autoDispose<CommunityDiscoveryModel>((ref) async {
  final repo = ref.watch(communityRepositoryProvider);
  return await repo.getCommunityDiscovery();
});

final blockedUsersProvider = FutureProvider.autoDispose<List<int>>((ref) async {
  final repo = ref.watch(communityRepositoryProvider);
  return await repo.getBlockedUsers();
});

final adminReportsProvider = FutureProvider.autoDispose.family<List<UserReportModel>, String?>((ref, status) async {
  final repo = ref.watch(communityRepositoryProvider);
  return await repo.getAdminReports(status: status);
});

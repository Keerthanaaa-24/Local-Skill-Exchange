import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/review_model.dart';
import '../models/rating_stats_model.dart';
import '../repositories/review_repository.dart';
import '../services/api_client.dart';

class UserReviewState {
  final List<ReviewModel> reviews;
  final RatingStatsModel stats;

  UserReviewState({required this.reviews, required this.stats});
}

final reviewRepositoryProvider = Provider<ReviewRepository>((ref) {
  return ReviewRepository(apiClient);
});

final userReviewsProvider = AsyncNotifierProviderFamily<UserReviewsNotifier, UserReviewState, int>(() {
  return UserReviewsNotifier();
});

class UserReviewsNotifier extends FamilyAsyncNotifier<UserReviewState, int> {
  @override
  Future<UserReviewState> build(int arg) async {
    return _fetchData(arg);
  }

  Future<UserReviewState> _fetchData(int userId) async {
    final repository = ref.read(reviewRepositoryProvider);
    final reviews = await repository.getReviews(userId);
    final stats = await repository.getRatingStatistics(userId);
    return UserReviewState(reviews: reviews, stats: stats);
  }

  Future<void> refreshReviews() async {
    state = const AsyncValue.loading();
    try {
      final data = await _fetchData(arg);
      state = AsyncValue.data(data);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> submitReview({
    required int bookingId,
    required double rating,
    required String comment,
  }) async {
    try {
      final repository = ref.read(reviewRepositoryProvider);
      await repository.submitReview(
        bookingId: bookingId,
        reviewedUserId: arg,
        rating: rating,
        comment: comment,
      );
      await refreshReviews();
    } catch (e) {
      throw Exception('Failed to submit review: $e');
    }
  }
}

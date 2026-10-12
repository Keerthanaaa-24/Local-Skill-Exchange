import '../services/api_client.dart';
import '../models/review_model.dart';
import '../models/rating_stats_model.dart';

class ReviewRepository {
  final ApiClient _apiClient;

  ReviewRepository(this._apiClient);

  Future<List<ReviewModel>> getReviews(int userId) async {
    try {
      final response = await _apiClient.dio.get('/reviews/user/$userId');
      return (response.data as List).map((e) => ReviewModel.fromJson(e)).toList();
    } catch (e) {
      throw Exception('Failed to fetch reviews: $e');
    }
  }

  Future<ReviewModel> getReview(int reviewId) async {
    try {
      final response = await _apiClient.dio.get('/reviews/$reviewId');
      return ReviewModel.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to fetch review details: $e');
    }
  }

  Future<RatingStatsModel> getRatingStatistics(int userId) async {
    try {
      final response = await _apiClient.dio.get('/reviews/user/$userId/statistics');
      return RatingStatsModel.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to fetch rating statistics: $e');
    }
  }

  Future<ReviewModel> submitReview({
    required int bookingId,
    required int reviewedUserId,
    required double rating,
    required String comment,
  }) async {
    try {
      final response = await _apiClient.dio.post('/reviews', data: {
        'booking_id': bookingId,
        'reviewed_user_id': reviewedUserId,
        'rating': rating,
        'comment': comment,
      });
      return ReviewModel.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to submit review: $e');
    }
  }

  Future<ReviewModel> updateReview({
    required int reviewId,
    required double rating,
    required String comment,
  }) async {
    try {
      final response = await _apiClient.dio.put('/reviews/$reviewId', data: {
        'rating': rating,
        'comment': comment,
      });
      return ReviewModel.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to update review: $e');
    }
  }

  Future<void> deleteReview(int reviewId) async {
    try {
      await _apiClient.dio.delete('/reviews/$reviewId');
    } catch (e) {
      throw Exception('Failed to delete review: $e');
    }
  }
}

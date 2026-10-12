class ReviewModel {
  final int reviewId;
  final int bookingId;
  final int reviewerId;
  final String reviewerName;
  final String? reviewerImageUrl;
  final int reviewedUserId;
  final double rating;
  final String comment;
  final String createdAt;
  final String updatedAt;

  ReviewModel({
    required this.reviewId,
    required this.bookingId,
    required this.reviewerId,
    required this.reviewerName,
    this.reviewerImageUrl,
    required this.reviewedUserId,
    required this.rating,
    required this.comment,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    return ReviewModel(
      reviewId: json['review_id'] ?? 0,
      bookingId: json['booking_id'] ?? 0,
      reviewerId: json['reviewer_id'] ?? 0,
      reviewerName: json['reviewer_name'] ?? 'Unknown User',
      reviewerImageUrl: json['reviewer_image_url'],
      reviewedUserId: json['reviewed_user_id'] ?? 0,
      rating: (json['rating'] ?? 0).toDouble(),
      comment: json['comment'] ?? '',
      createdAt: json['created_at'] ?? DateTime.now().toIso8601String(),
      updatedAt: json['updated_at'] ?? DateTime.now().toIso8601String(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'review_id': reviewId,
      'booking_id': bookingId,
      'reviewer_id': reviewerId,
      'reviewer_name': reviewerName,
      'reviewer_image_url': reviewerImageUrl,
      'reviewed_user_id': reviewedUserId,
      'rating': rating,
      'comment': comment,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}

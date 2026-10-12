class RecommendationModel {
  final int mentorId;
  final String mentorName;
  final String? mentorProfileImage;
  final double? mentorRating;
  final int? mentorReviewCount;
  final double? mentorLatitude;
  final double? mentorLongitude;
  final int skillId;
  final String skillTitle;
  final String? skillDescription;
  final String? skillCategory;
  final String? skillImageUrl;
  final double matchScore;
  final String explanation;
  final double? distanceKm;
  final double? rating;
  final String? reason;
  final bool canLearn;
  final bool canTeach;
  final int nearbyMentorsCount;

  RecommendationModel({
    required this.mentorId,
    required this.mentorName,
    this.mentorProfileImage,
    this.mentorRating,
    this.mentorReviewCount,
    this.mentorLatitude,
    this.mentorLongitude,
    required this.skillId,
    required this.skillTitle,
    this.skillDescription,
    this.skillCategory,
    this.skillImageUrl,
    required this.matchScore,
    required this.explanation,
    this.distanceKm,
    this.rating,
    this.reason,
    this.canLearn = true,
    this.canTeach = false,
    this.nearbyMentorsCount = 1,
  });

  factory RecommendationModel.fromSkill(dynamic skill) {
    return RecommendationModel(
      mentorId: skill.ownerId,
      mentorName: skill.ownerName,
      mentorProfileImage: skill.ownerProfileImage,
      mentorRating: skill.rating,
      mentorReviewCount: skill.reviewCount,
      mentorLatitude: skill.latitude,
      mentorLongitude: skill.longitude,
      skillId: skill.id,
      skillTitle: skill.title,
      skillDescription: skill.description,
      skillCategory: skill.categoryName,
      skillImageUrl: skill.imageUrl,
      matchScore: 100.0,
      explanation: 'Matched skill',
      rating: skill.rating,
      reason: 'Skill matched from catalog',
      canLearn: true,
      canTeach: false,
      nearbyMentorsCount: 1,
    );
  }

  factory RecommendationModel.fromJson(Map<String, dynamic> json) {
    return RecommendationModel(
      mentorId: json['mentor_id'] is int ? json['mentor_id'] : int.tryParse(json['mentor_id']?.toString() ?? '') ?? 0,
      mentorName: json['mentor_name'] ?? '',
      mentorProfileImage: json['mentor_profile_image'],
      mentorRating: json['mentor_rating'] is num ? (json['mentor_rating'] as num).toDouble() : double.tryParse(json['mentor_rating']?.toString() ?? ''),
      mentorReviewCount: json['mentor_review_count'] is int ? json['mentor_review_count'] : int.tryParse(json['mentor_review_count']?.toString() ?? ''),
      mentorLatitude: json['mentor_latitude'] is num ? (json['mentor_latitude'] as num).toDouble() : double.tryParse(json['mentor_latitude']?.toString() ?? ''),
      mentorLongitude: json['mentor_longitude'] is num ? (json['mentor_longitude'] as num).toDouble() : double.tryParse(json['mentor_longitude']?.toString() ?? ''),
      skillId: json['skill_id'] is int ? json['skill_id'] : int.tryParse(json['skill_id']?.toString() ?? '') ?? 0,
      skillTitle: json['skill_title'] ?? '',
      skillDescription: json['skill_description'],
      skillCategory: json['skill_category'],
      skillImageUrl: json['skill_image_url'],
      matchScore: json['match_score'] is num ? (json['match_score'] as num).toDouble() : double.tryParse(json['match_score']?.toString() ?? '') ?? 0.0,
      explanation: json['explanation'] ?? '',
      distanceKm: json['distance_km'] is num ? (json['distance_km'] as num).toDouble() : double.tryParse(json['distance_km']?.toString() ?? ''),
      rating: json['rating'] is num ? (json['rating'] as num).toDouble() : double.tryParse(json['rating']?.toString() ?? ''),
      reason: json['reason'] as String?,
      canLearn: json['can_learn'] is bool ? json['can_learn'] as bool : true,
      canTeach: json['can_teach'] is bool ? json['can_teach'] as bool : false,
      nearbyMentorsCount: json['nearby_mentors_count'] is int ? json['nearby_mentors_count'] as int : int.tryParse(json['nearby_mentors_count']?.toString() ?? '') ?? 1,
    );
  }

  Map<String, dynamic> toJson() => {
        'mentor_id': mentorId,
        'mentor_name': mentorName,
        'mentor_profile_image': mentorProfileImage,
        'mentor_rating': mentorRating,
        'mentor_review_count': mentorReviewCount,
        'mentor_latitude': mentorLatitude,
        'mentor_longitude': mentorLongitude,
        'skill_id': skillId,
        'skill_title': skillTitle,
        'skill_description': skillDescription,
        'skill_category': skillCategory,
        'skill_image_url': skillImageUrl,
        'match_score': matchScore,
        'explanation': explanation,
        'distance_km': distanceKm,
        'rating': rating,
        'reason': reason,
        'can_learn': canLearn,
        'can_teach': canTeach,
        'nearby_mentors_count': nearbyMentorsCount,
      };
}

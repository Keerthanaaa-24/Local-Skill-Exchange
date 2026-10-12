class CommunityActivityItem {
  final String id;
  final String type; // certificate, path_completed, exchange_completed, review
  final String title;
  final String description;
  final DateTime timestamp;
  final int userId;
  final String userName;
  final String? userAvatar;
  final int? skillId;
  final String? skillName;
  final double? rating;

  CommunityActivityItem({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.timestamp,
    required this.userId,
    required this.userName,
    this.userAvatar,
    this.skillId,
    this.skillName,
    this.rating,
  });

  factory CommunityActivityItem.fromJson(Map<String, dynamic> json) {
    return CommunityActivityItem(
      id: json['id']?.toString() ?? '',
      type: json['type'] ?? 'general',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'].toString()) ?? DateTime.now()
          : DateTime.now(),
      userId: json['user_id'] is int ? json['user_id'] : int.tryParse(json['user_id']?.toString() ?? '') ?? 0,
      userName: json['user_name'] ?? 'Community Member',
      userAvatar: json['user_avatar'],
      skillId: json['skill_id'] is int ? json['skill_id'] : int.tryParse(json['skill_id']?.toString() ?? ''),
      skillName: json['skill_name'],
      rating: json['rating'] is num ? (json['rating'] as num).toDouble() : double.tryParse(json['rating']?.toString() ?? ''),
    );
  }
}

class CommunityTrustIndicators {
  final int verifiedCertificatesCount;
  final int completedExchanges;
  final double rating;
  final int reviewCount;
  final int skillsOfferedCount;
  final int skillsLearnedCount;
  final double learningProgressPercent;
  final bool isVerifiedMentor;

  CommunityTrustIndicators({
    this.verifiedCertificatesCount = 0,
    this.completedExchanges = 0,
    this.rating = 5.0,
    this.reviewCount = 0,
    this.skillsOfferedCount = 0,
    this.skillsLearnedCount = 0,
    this.learningProgressPercent = 0.0,
    this.isVerifiedMentor = false,
  });

  factory CommunityTrustIndicators.fromJson(Map<String, dynamic> json) {
    return CommunityTrustIndicators(
      verifiedCertificatesCount: json['verified_certificates_count'] ?? 0,
      completedExchanges: json['completed_exchanges'] ?? 0,
      rating: json['rating'] is num ? (json['rating'] as num).toDouble() : 5.0,
      reviewCount: json['review_count'] ?? 0,
      skillsOfferedCount: json['skills_offered_count'] ?? 0,
      skillsLearnedCount: json['skills_learned_count'] ?? 0,
      learningProgressPercent: json['learning_progress_percent'] is num
          ? (json['learning_progress_percent'] as num).toDouble()
          : 0.0,
      isVerifiedMentor: json['is_verified_mentor'] ?? false,
    );
  }
}

class CommunityProfileModel {
  final int userId;
  final String name;
  final String? title;
  final String? avatarUrl;
  final String? bio;
  final CommunityTrustIndicators trustIndicators;
  final List<Map<String, dynamic>> skillsOffered;
  final List<Map<String, dynamic>> skillsWanted;
  final List<CommunityActivityItem> recentActivity;
  final bool isBlocked;

  CommunityProfileModel({
    required this.userId,
    required this.name,
    this.title,
    this.avatarUrl,
    this.bio,
    required this.trustIndicators,
    this.skillsOffered = const [],
    this.skillsWanted = const [],
    this.recentActivity = const [],
    this.isBlocked = false,
  });

  factory CommunityProfileModel.fromJson(Map<String, dynamic> json) {
    return CommunityProfileModel(
      userId: json['user_id'] is int ? json['user_id'] : int.tryParse(json['user_id']?.toString() ?? '') ?? 0,
      name: json['name'] ?? '',
      title: json['title'],
      avatarUrl: json['avatar_url'],
      bio: json['bio'],
      trustIndicators: json['trust_indicators'] != null
          ? CommunityTrustIndicators.fromJson(json['trust_indicators'])
          : CommunityTrustIndicators(),
      skillsOffered: json['skills_offered'] is List
          ? (json['skills_offered'] as List).map((e) => Map<String, dynamic>.from(e)).toList()
          : [],
      skillsWanted: json['skills_wanted'] is List
          ? (json['skills_wanted'] as List).map((e) => Map<String, dynamic>.from(e)).toList()
          : [],
      recentActivity: json['recent_activity'] is List
          ? (json['recent_activity'] as List).map((e) => CommunityActivityItem.fromJson(e)).toList()
          : [],
      isBlocked: json['is_blocked'] ?? false,
    );
  }
}

class CommunityDiscoveryPeer {
  final int userId;
  final String name;
  final String? title;
  final String? avatarUrl;
  final double rating;
  final int reviewCount;
  final double? distanceKm;
  final String? commonSkill;
  final String reason;
  final List<String> trustBadges;

  CommunityDiscoveryPeer({
    required this.userId,
    required this.name,
    this.title,
    this.avatarUrl,
    this.rating = 5.0,
    this.reviewCount = 0,
    this.distanceKm,
    this.commonSkill,
    required this.reason,
    this.trustBadges = const [],
  });

  factory CommunityDiscoveryPeer.fromJson(Map<String, dynamic> json) {
    return CommunityDiscoveryPeer(
      userId: json['user_id'] is int ? json['user_id'] : int.tryParse(json['user_id']?.toString() ?? '') ?? 0,
      name: json['name'] ?? '',
      title: json['title'],
      avatarUrl: json['avatar_url'],
      rating: json['rating'] is num ? (json['rating'] as num).toDouble() : 5.0,
      reviewCount: json['review_count'] ?? 0,
      distanceKm: json['distance_km'] is num ? (json['distance_km'] as num).toDouble() : null,
      commonSkill: json['common_skill'],
      reason: json['reason'] ?? '',
      trustBadges: json['trust_badges'] is List
          ? (json['trust_badges'] as List).map((e) => e.toString()).toList()
          : [],
    );
  }
}

class CommunityDiscoveryModel {
  final List<CommunityDiscoveryPeer> mentorsForYou;
  final List<CommunityDiscoveryPeer> learningPeers;
  final List<CommunityDiscoveryPeer> nearbyPartners;

  CommunityDiscoveryModel({
    this.mentorsForYou = const [],
    this.learningPeers = const [],
    this.nearbyPartners = const [],
  });

  factory CommunityDiscoveryModel.fromJson(Map<String, dynamic> json) {
    return CommunityDiscoveryModel(
      mentorsForYou: json['mentors_for_you'] is List
          ? (json['mentors_for_you'] as List).map((e) => CommunityDiscoveryPeer.fromJson(e)).toList()
          : [],
      learningPeers: json['learning_peers'] is List
          ? (json['learning_peers'] as List).map((e) => CommunityDiscoveryPeer.fromJson(e)).toList()
          : [],
      nearbyPartners: json['nearby_partners'] is List
          ? (json['nearby_partners'] as List).map((e) => CommunityDiscoveryPeer.fromJson(e)).toList()
          : [],
    );
  }
}

class UserReportModel {
  final int id;
  final int reporterId;
  final int reportedUserId;
  final String? reporterName;
  final String? reportedUserName;
  final String reason;
  final String? description;
  final String status;
  final DateTime createdAt;

  UserReportModel({
    required this.id,
    required this.reporterId,
    required this.reportedUserId,
    this.reporterName,
    this.reportedUserName,
    required this.reason,
    this.description,
    required this.status,
    required this.createdAt,
  });

  String? get details => description;

  factory UserReportModel.fromJson(Map<String, dynamic> json) {
    return UserReportModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '') ?? 0,
      reporterId: json['reporter_id'] is int ? json['reporter_id'] : int.tryParse(json['reporter_id']?.toString() ?? '') ?? 0,
      reportedUserId: json['reported_user_id'] is int ? json['reported_user_id'] : int.tryParse(json['reported_user_id']?.toString() ?? '') ?? 0,
      reporterName: json['reporter_name'],
      reportedUserName: json['reported_user_name'],
      reason: json['reason'] ?? 'General',
      description: json['description'],
      status: json['status'] ?? 'pending',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

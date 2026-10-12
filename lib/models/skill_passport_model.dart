class PassportProfileModel {
  final int userId;
  final String name;
  final String? email;
  final String? title;
  final String? bio;
  final String? avatarUrl;
  final String? location;
  final int xp;
  final int streakDays;
  final int? credits;

  PassportProfileModel({
    required this.userId,
    required this.name,
    this.email,
    this.title,
    this.bio,
    this.avatarUrl,
    this.location,
    required this.xp,
    required this.streakDays,
    this.credits,
  });

  factory PassportProfileModel.fromJson(Map<String, dynamic> json) {
    return PassportProfileModel(
      userId: json['user_id'] as int,
      name: json['name'] as String? ?? 'Learner',
      email: json['email'] as String?,
      title: json['title'] as String?,
      bio: json['bio'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      location: json['location'] as String?,
      xp: json['xp'] as int? ?? 0,
      streakDays: json['streak_days'] as int? ?? 0,
      credits: json['credits'] as int?,
    );
  }

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'name': name,
        'email': email,
        'title': title,
        'bio': bio,
        'avatar_url': avatarUrl,
        'location': location,
        'xp': xp,
        'streak_days': streakDays,
        'credits': credits,
      };
}

class PassportSkillModel {
  final int skillId;
  final String skillName;
  final String? category;
  final String level; // Beginner, Intermediate, Advanced
  final double learningProgress;
  final int completedLearningPaths;
  final int certificatesCount;
  final double? practiceAverage;
  final bool isCertified;

  PassportSkillModel({
    required this.skillId,
    required this.skillName,
    this.category,
    required this.level,
    required this.learningProgress,
    required this.completedLearningPaths,
    required this.certificatesCount,
    this.practiceAverage,
    required this.isCertified,
  });

  factory PassportSkillModel.fromJson(Map<String, dynamic> json) {
    return PassportSkillModel(
      skillId: json['skill_id'] as int,
      skillName: json['skill_name'] as String,
      category: json['category'] as String?,
      level: json['level'] as String? ?? 'Beginner',
      learningProgress: (json['learning_progress'] as num?)?.toDouble() ?? 0.0,
      completedLearningPaths: json['completed_learning_paths'] as int? ?? 0,
      certificatesCount: json['certificates_count'] as int? ?? 0,
      practiceAverage: (json['practice_average'] as num?)?.toDouble(),
      isCertified: json['is_certified'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'skill_id': skillId,
        'skill_name': skillName,
        'category': category,
        'level': level,
        'learning_progress': learningProgress,
        'completed_learning_paths': completedLearningPaths,
        'certificates_count': certificatesCount,
        'practice_average': practiceAverage,
        'is_certified': isCertified,
      };
}

class PassportCertificateModel {
  final int certificateId;
  final String certificateNumber;
  final String title;
  final String skill;
  final int skillId;
  final DateTime issuedAt;
  final String verificationCode;
  final String status;

  PassportCertificateModel({
    required this.certificateId,
    required this.certificateNumber,
    required this.title,
    required this.skill,
    required this.skillId,
    required this.issuedAt,
    required this.verificationCode,
    required this.status,
  });

  factory PassportCertificateModel.fromJson(Map<String, dynamic> json) {
    return PassportCertificateModel(
      certificateId: json['certificate_id'] as int,
      certificateNumber: json['certificate_number'] as String,
      title: json['title'] as String,
      skill: json['skill'] as String,
      skillId: json['skill_id'] as int,
      issuedAt: DateTime.parse(json['issued_at'] as String),
      verificationCode: json['verification_code'] as String,
      status: json['status'] as String? ?? 'valid',
    );
  }

  Map<String, dynamic> toJson() => {
        'certificate_id': certificateId,
        'certificate_number': certificateNumber,
        'title': title,
        'skill': skill,
        'skill_id': skillId,
        'issued_at': issuedAt.toIso8601String(),
        'verification_code': verificationCode,
        'status': status,
      };
}

class PassportPracticeSummaryModel {
  final int totalAttempts;
  final int passedAttempts;
  final double? averageScore;
  final int? highestScore;
  final int lessonsPracticed;

  PassportPracticeSummaryModel({
    required this.totalAttempts,
    required this.passedAttempts,
    this.averageScore,
    this.highestScore,
    required this.lessonsPracticed,
  });

  factory PassportPracticeSummaryModel.fromJson(Map<String, dynamic> json) {
    return PassportPracticeSummaryModel(
      totalAttempts: json['total_attempts'] as int? ?? 0,
      passedAttempts: json['passed_attempts'] as int? ?? 0,
      averageScore: (json['average_score'] as num?)?.toDouble(),
      highestScore: json['highest_score'] as int?,
      lessonsPracticed: json['lessons_practiced'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'total_attempts': totalAttempts,
        'passed_attempts': passedAttempts,
        'average_score': averageScore,
        'highest_score': highestScore,
        'lessons_practiced': lessonsPracticed,
      };
}

class PassportLearningSummaryModel {
  final int activePaths;
  final int completedPaths;
  final int totalLessonsCompleted;
  final int totalLessonsAvailable;
  final double overallProgress;

  PassportLearningSummaryModel({
    required this.activePaths,
    required this.completedPaths,
    required this.totalLessonsCompleted,
    required this.totalLessonsAvailable,
    required this.overallProgress,
  });

  factory PassportLearningSummaryModel.fromJson(Map<String, dynamic> json) {
    return PassportLearningSummaryModel(
      activePaths: json['active_paths'] as int? ?? 0,
      completedPaths: json['completed_paths'] as int? ?? 0,
      totalLessonsCompleted: json['total_lessons_completed'] as int? ?? 0,
      totalLessonsAvailable: json['total_lessons_available'] as int? ?? 0,
      overallProgress: (json['overall_progress'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
        'active_paths': activePaths,
        'completed_paths': completedPaths,
        'total_lessons_completed': totalLessonsCompleted,
        'total_lessons_available': totalLessonsAvailable,
        'overall_progress': overallProgress,
      };
}

class PassportExchangeSummaryModel {
  final int skillsOfferedCount;
  final int skillsRequestedCount;
  final int completedBookingsAsMentor;
  final int completedBookingsAsMentee;
  final int totalCompletedExchanges;
  final int? creditsEarned;
  final int? creditsSpent;
  final double averageRating;
  final int totalReviews;

  PassportExchangeSummaryModel({
    required this.skillsOfferedCount,
    required this.skillsRequestedCount,
    required this.completedBookingsAsMentor,
    required this.completedBookingsAsMentee,
    required this.totalCompletedExchanges,
    this.creditsEarned,
    this.creditsSpent,
    required this.averageRating,
    required this.totalReviews,
  });

  factory PassportExchangeSummaryModel.fromJson(Map<String, dynamic> json) {
    return PassportExchangeSummaryModel(
      skillsOfferedCount: json['skills_offered_count'] as int? ?? 0,
      skillsRequestedCount: json['skills_requested_count'] as int? ?? 0,
      completedBookingsAsMentor: json['completed_bookings_as_mentor'] as int? ?? 0,
      completedBookingsAsMentee: json['completed_bookings_as_mentee'] as int? ?? 0,
      totalCompletedExchanges: json['total_completed_exchanges'] as int? ?? 0,
      creditsEarned: json['credits_earned'] as int?,
      creditsSpent: json['credits_spent'] as int?,
      averageRating: (json['average_rating'] as num?)?.toDouble() ?? 5.0,
      totalReviews: json['total_reviews'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'skills_offered_count': skillsOfferedCount,
        'skills_requested_count': skillsRequestedCount,
        'completed_bookings_as_mentor': completedBookingsAsMentor,
        'completed_bookings_as_mentee': completedBookingsAsMentee,
        'total_completed_exchanges': totalCompletedExchanges,
        'credits_earned': creditsEarned,
        'credits_spent': creditsSpent,
        'average_rating': averageRating,
        'total_reviews': totalReviews,
      };
}

class SkillPassportModel {
  final PassportProfileModel profile;
  final PassportLearningSummaryModel learningSummary;
  final PassportPracticeSummaryModel practiceSummary;
  final List<PassportSkillModel> skills;
  final List<PassportCertificateModel> certificates;
  final PassportExchangeSummaryModel exchangeSummary;
  final bool isPublicView;

  SkillPassportModel({
    required this.profile,
    required this.learningSummary,
    required this.practiceSummary,
    required this.skills,
    required this.certificates,
    required this.exchangeSummary,
    this.isPublicView = false,
  });

  factory SkillPassportModel.fromJson(Map<String, dynamic> json) {
    return SkillPassportModel(
      profile: PassportProfileModel.fromJson(json['profile'] as Map<String, dynamic>),
      learningSummary: PassportLearningSummaryModel.fromJson(json['learning_summary'] as Map<String, dynamic>),
      practiceSummary: PassportPracticeSummaryModel.fromJson(json['practice_summary'] as Map<String, dynamic>),
      skills: (json['skills'] as List<dynamic>?)
              ?.map((s) => PassportSkillModel.fromJson(s as Map<String, dynamic>))
              .toList() ??
          [],
      certificates: (json['certificates'] as List<dynamic>?)
              ?.map((c) => PassportCertificateModel.fromJson(c as Map<String, dynamic>))
              .toList() ??
          [],
      exchangeSummary: PassportExchangeSummaryModel.fromJson(json['exchange_summary'] as Map<String, dynamic>),
      isPublicView: json['is_public_view'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'profile': profile.toJson(),
        'learning_summary': learningSummary.toJson(),
        'practice_summary': practiceSummary.toJson(),
        'skills': skills.map((s) => s.toJson()).toList(),
        'certificates': certificates.map((c) => c.toJson()).toList(),
        'exchange_summary': exchangeSummary.toJson(),
        'is_public_view': isPublicView,
      };
}

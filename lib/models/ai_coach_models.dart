class HeroRecommendationModel {
  final int skillId;
  final String skillName;
  final String category;
  final String gapLevel;
  final String reason;
  final bool hasLearningPath;
  final int? pathId;
  final int availableMentorsCount;
  final int confidenceScore;
  final String actionType;

  HeroRecommendationModel({
    required this.skillId,
    required this.skillName,
    required this.category,
    required this.gapLevel,
    required this.reason,
    required this.hasLearningPath,
    this.pathId,
    required this.availableMentorsCount,
    required this.confidenceScore,
    this.actionType = 'learning',
  });

  factory HeroRecommendationModel.fromJson(Map<String, dynamic> json) {
    return HeroRecommendationModel(
      skillId: json['skill_id'] ?? 0,
      skillName: json['skill_name'] ?? 'Skill',
      category: json['category'] ?? 'General',
      gapLevel: json['gap_level'] ?? 'Recommended',
      reason: json['reason'] ?? '',
      hasLearningPath: json['has_learning_path'] ?? false,
      pathId: json['path_id'],
      availableMentorsCount: json['available_mentors_count'] ?? 0,
      confidenceScore: json['confidence_score'] ?? 90,
      actionType: json['action_type'] ?? 'learning',
    );
  }
}

class SkillGapModel {
  final int skillId;
  final String skillName;
  final String category;
  final String gapLevel;
  final int priorityScore;
  final String reason;
  final String action;
  final String status;

  SkillGapModel({
    required this.skillId,
    required this.skillName,
    required this.category,
    required this.gapLevel,
    required this.priorityScore,
    required this.reason,
    required this.action,
    this.status = 'Goal Gap',
  });

  factory SkillGapModel.fromJson(Map<String, dynamic> json) {
    return SkillGapModel(
      skillId: json['skill_id'] ?? 0,
      skillName: json['skill_name'] ?? '',
      category: json['category'] ?? 'General',
      gapLevel: json['gap_level'] ?? 'Medium',
      priorityScore: json['priority_score'] ?? 50,
      reason: json['reason'] ?? '',
      action: json['action'] ?? 'explore',
      status: json['status'] ?? 'Goal Gap',
    );
  }
}

class SkillStrengthModel {
  final int skillId;
  final String skillName;
  final String category;
  final String level;
  final bool isCertified;
  final String badge;
  final String status;
  final String reason;

  SkillStrengthModel({
    required this.skillId,
    required this.skillName,
    required this.category,
    required this.level,
    required this.isCertified,
    required this.badge,
    this.status = 'Strong',
    this.reason = '',
  });

  factory SkillStrengthModel.fromJson(Map<String, dynamic> json) {
    return SkillStrengthModel(
      skillId: json['skill_id'] ?? 0,
      skillName: json['skill_name'] ?? '',
      category: json['category'] ?? 'General',
      level: json['level'] ?? 'Proficient',
      isCertified: json['is_certified'] ?? false,
      badge: json['badge'] ?? 'Verified Master',
      status: json['status'] ?? 'Strong',
      reason: json['reason'] ?? '',
    );
  }
}

class DevelopingSkillModel {
  final int skillId;
  final String skillName;
  final String category;
  final int progressPercent;
  final int completedLessons;
  final int totalLessons;
  final int? pathId;
  final String pathTitle;
  final String status;
  final String badge;
  final String reason;

  DevelopingSkillModel({
    required this.skillId,
    required this.skillName,
    required this.category,
    required this.progressPercent,
    required this.completedLessons,
    required this.totalLessons,
    this.pathId,
    required this.pathTitle,
    this.status = 'Improving',
    this.badge = 'Active Focus',
    this.reason = '',
  });

  factory DevelopingSkillModel.fromJson(Map<String, dynamic> json) {
    return DevelopingSkillModel(
      skillId: json['skill_id'] ?? 0,
      skillName: json['skill_name'] ?? '',
      category: json['category'] ?? 'General',
      progressPercent: json['progress_percent'] ?? 0,
      completedLessons: json['completed_lessons'] ?? 0,
      totalLessons: json['total_lessons'] ?? 0,
      pathId: json['path_id'],
      pathTitle: json['path_title'] ?? '',
      status: json['status'] ?? 'Improving',
      badge: json['badge'] ?? 'Active Focus',
      reason: json['reason'] ?? '',
    );
  }
}

class SkillPortfolioItemModel {
  final int skillId;
  final String skillName;
  final String category;
  final String status; // 'Strong', 'Improving', 'Needs Practice', 'Goal Gap'
  final String level;
  final String badge;
  final String reason;
  final int? progressPercent;

  SkillPortfolioItemModel({
    required this.skillId,
    required this.skillName,
    required this.category,
    required this.status,
    required this.level,
    required this.badge,
    required this.reason,
    this.progressPercent,
  });

  factory SkillPortfolioItemModel.fromJson(Map<String, dynamic> json) {
    return SkillPortfolioItemModel(
      skillId: json['skill_id'] ?? 0,
      skillName: json['skill_name'] ?? '',
      category: json['category'] ?? 'General',
      status: json['status'] ?? 'Improving',
      level: json['level'] ?? 'In Progress',
      badge: json['badge'] ?? 'Active Focus',
      reason: json['reason'] ?? '',
      progressPercent: json['progress_percent'],
    );
  }
}

class RoadmapStepModel {
  final int stepNumber;
  final int skillId;
  final int? pathId;
  final String title;
  final String subtitle;
  final String category;
  final String status;
  final int progressPercent;
  final String badge;
  final String actionType;

  RoadmapStepModel({
    required this.stepNumber,
    required this.skillId,
    this.pathId,
    required this.title,
    required this.subtitle,
    required this.category,
    required this.status,
    required this.progressPercent,
    required this.badge,
    required this.actionType,
  });

  factory RoadmapStepModel.fromJson(Map<String, dynamic> json) {
    return RoadmapStepModel(
      stepNumber: json['step_number'] ?? 1,
      skillId: json['skill_id'] ?? 0,
      pathId: json['path_id'],
      title: json['title'] ?? '',
      subtitle: json['subtitle'] ?? '',
      category: json['category'] ?? 'General',
      status: json['status'] ?? 'future_milestone',
      progressPercent: json['progress_percent'] ?? 0,
      badge: json['badge'] ?? 'Milestone',
      actionType: json['action_type'] ?? 'start_learning',
    );
  }
}

class PracticeDiagnosticModel {
  final int lessonId;
  final String lessonTitle;
  final int? pathId;
  final String pathTitle;
  final int lastScore;
  final String status;
  final String severity;
  final String message;
  final String recommendation;

  PracticeDiagnosticModel({
    required this.lessonId,
    required this.lessonTitle,
    this.pathId,
    required this.pathTitle,
    required this.lastScore,
    required this.status,
    required this.severity,
    required this.message,
    required this.recommendation,
  });

  factory PracticeDiagnosticModel.fromJson(Map<String, dynamic> json) {
    return PracticeDiagnosticModel(
      lessonId: json['lesson_id'] ?? 0,
      lessonTitle: json['lesson_title'] ?? 'Lesson',
      pathId: json['path_id'],
      pathTitle: json['path_title'] ?? 'Path',
      lastScore: json['last_score'] ?? 0,
      status: json['status'] ?? 'needs_revision',
      severity: json['severity'] ?? 'medium',
      message: json['message'] ?? '',
      recommendation: json['recommendation'] ?? 'Review Lesson',
    );
  }
}

class ExchangeSuggestionModel {
  final int peerId;
  final String peerName;
  final String? peerAvatar;
  final double peerRating;
  final int peerReviews;
  final bool isTwoWaySwap;
  final List<String> skillsYouTeach;
  final List<String> skillsYouLearn;
  final String explanation;
  final double matchScore;

  ExchangeSuggestionModel({
    required this.peerId,
    required this.peerName,
    this.peerAvatar,
    required this.peerRating,
    required this.peerReviews,
    required this.isTwoWaySwap,
    required this.skillsYouTeach,
    required this.skillsYouLearn,
    required this.explanation,
    required this.matchScore,
  });

  factory ExchangeSuggestionModel.fromJson(Map<String, dynamic> json) {
    return ExchangeSuggestionModel(
      peerId: json['peer_id'] ?? 0,
      peerName: json['peer_name'] ?? 'Peer',
      peerAvatar: json['peer_avatar'],
      peerRating: (json['peer_rating'] as num?)?.toDouble() ?? 5.0,
      peerReviews: json['peer_reviews'] ?? 0,
      isTwoWaySwap: json['is_two_way_swap'] ?? false,
      skillsYouTeach: (json['skills_you_teach'] as List?)?.map((e) => e.toString()).toList() ?? [],
      skillsYouLearn: (json['skills_you_learn'] as List?)?.map((e) => e.toString()).toList() ?? [],
      explanation: json['explanation'] ?? '',
      matchScore: (json['match_score'] as num?)?.toDouble() ?? 90.0,
    );
  }
}

class DailyPlanItemModel {
  final String id;
  final String title;
  final int durationMinutes;
  final String actionType;
  final int targetId;
  final int? pathId;
  final bool isCompleted;
  final int rewardXp;
  final String reason;

  DailyPlanItemModel({
    required this.id,
    required this.title,
    required this.durationMinutes,
    required this.actionType,
    required this.targetId,
    this.pathId,
    this.isCompleted = false,
    this.rewardXp = 20,
    required this.reason,
  });

  factory DailyPlanItemModel.fromJson(Map<String, dynamic> json) {
    return DailyPlanItemModel(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      durationMinutes: json['duration_minutes'] ?? 15,
      actionType: json['action_type'] ?? 'learning',
      targetId: json['target_id'] ?? 0,
      pathId: json['path_id'],
      isCompleted: json['is_completed'] ?? false,
      rewardXp: json['reward_xp'] ?? 20,
      reason: json['reason'] ?? '',
    );
  }
}

class DailyGoalModel {
  final String goalTitle;
  final String description;
  final String reason;
  final String priority;
  final String actionLabel;
  final String actionType;
  final int targetId;
  final bool isCompleted;
  final int streakDays;
  final int rewardXp;
  final List<DailyPlanItemModel> dailyPlan;

  DailyGoalModel({
    required this.goalTitle,
    required this.description,
    required this.reason,
    required this.priority,
    required this.actionLabel,
    required this.actionType,
    required this.targetId,
    required this.isCompleted,
    required this.streakDays,
    required this.rewardXp,
    this.dailyPlan = const [],
  });

  factory DailyGoalModel.fromJson(Map<String, dynamic> json) {
    return DailyGoalModel(
      goalTitle: json['goal_title'] ?? 'Daily Objective',
      description: json['description'] ?? '',
      reason: json['reason'] ?? '',
      priority: json['priority'] ?? 'medium',
      actionLabel: json['action_label'] ?? 'Start',
      actionType: json['action_type'] ?? 'explore',
      targetId: json['target_id'] ?? 0,
      isCompleted: json['is_completed'] ?? false,
      streakDays: json['streak_days'] ?? 0,
      rewardXp: json['reward_xp'] ?? 25,
      dailyPlan: (json['daily_plan'] as List?)
              ?.map((e) => DailyPlanItemModel.fromJson(Map<String, dynamic>.from(e)))
              .toList() ??
          [],
    );
  }
}

class SkillGrowthMetricModel {
  final int lessonId;
  final String lessonTitle;
  final String skillName;
  final int initialScore;
  final int currentScore;
  final int attemptsCount;
  final int improvementPct;
  final String trend;
  final String statusBadge;

  SkillGrowthMetricModel({
    required this.lessonId,
    required this.lessonTitle,
    required this.skillName,
    required this.initialScore,
    required this.currentScore,
    required this.attemptsCount,
    required this.improvementPct,
    required this.trend,
    required this.statusBadge,
  });

  factory SkillGrowthMetricModel.fromJson(Map<String, dynamic> json) {
    return SkillGrowthMetricModel(
      lessonId: json['lesson_id'] ?? 0,
      lessonTitle: json['lesson_title'] ?? '',
      skillName: json['skill_name'] ?? '',
      initialScore: json['initial_score'] ?? 0,
      currentScore: json['current_score'] ?? 0,
      attemptsCount: json['attempts_count'] ?? 1,
      improvementPct: json['improvement_pct'] ?? 0,
      trend: json['trend'] ?? 'stable',
      statusBadge: json['status_badge'] ?? 'Consistent',
    );
  }
}

class SkillGrowthModel {
  final int userId;
  final int masteryIndex;
  final double overallAverageAccuracy;
  final double initialAverageAccuracy;
  final double accuracyImprovementPct;
  final int totalPracticeAttempts;
  final int passingConsistencyPct;
  final int certifiedSkillsCount;
  final String growthNarrative;
  final bool hasSufficientHistory;
  final List<SkillGrowthMetricModel> metrics;

  SkillGrowthModel({
    required this.userId,
    required this.masteryIndex,
    required this.overallAverageAccuracy,
    required this.initialAverageAccuracy,
    required this.accuracyImprovementPct,
    required this.totalPracticeAttempts,
    required this.passingConsistencyPct,
    required this.certifiedSkillsCount,
    required this.growthNarrative,
    required this.hasSufficientHistory,
    required this.metrics,
  });

  factory SkillGrowthModel.fromJson(Map<String, dynamic> json) {
    return SkillGrowthModel(
      userId: json['user_id'] ?? 0,
      masteryIndex: json['mastery_index'] ?? 0,
      overallAverageAccuracy: (json['overall_average_accuracy'] as num?)?.toDouble() ?? 0.0,
      initialAverageAccuracy: (json['initial_average_accuracy'] as num?)?.toDouble() ?? 0.0,
      accuracyImprovementPct: (json['accuracy_improvement_pct'] as num?)?.toDouble() ?? 0.0,
      totalPracticeAttempts: json['total_practice_attempts'] ?? 0,
      passingConsistencyPct: json['passing_consistency_pct'] ?? 0,
      certifiedSkillsCount: json['certified_skills_count'] ?? 0,
      growthNarrative: json['growth_narrative'] ?? '',
      hasSufficientHistory: json['has_sufficient_history'] ?? false,
      metrics: (json['metrics'] as List?)?.map((e) => SkillGrowthMetricModel.fromJson(e)).toList() ?? [],
    );
  }
}

class WeeklyGrowthInsightsModel {
  final int userId;
  final String weekStart;
  final String weekEnd;
  final int xpGainedWeek;
  final int practiceAttemptsWeek;
  final double averageAccuracyWeek;
  final int certificatesEarnedWeek;
  final int exchangesCompletedWeek;
  final int timeSpentMinutesWeek;
  final int streakDays;
  final String consistencyRating;
  final List<String> highlights;
  final bool hasSufficientHistory;

  WeeklyGrowthInsightsModel({
    required this.userId,
    required this.weekStart,
    required this.weekEnd,
    required this.xpGainedWeek,
    required this.practiceAttemptsWeek,
    required this.averageAccuracyWeek,
    required this.certificatesEarnedWeek,
    required this.exchangesCompletedWeek,
    this.timeSpentMinutesWeek = 0,
    required this.streakDays,
    required this.consistencyRating,
    required this.highlights,
    required this.hasSufficientHistory,
  });

  factory WeeklyGrowthInsightsModel.fromJson(Map<String, dynamic> json) {
    return WeeklyGrowthInsightsModel(
      userId: json['user_id'] ?? 0,
      weekStart: json['week_start'] ?? '',
      weekEnd: json['week_end'] ?? '',
      xpGainedWeek: json['xp_gained_week'] ?? 0,
      practiceAttemptsWeek: json['practice_attempts_week'] ?? 0,
      averageAccuracyWeek: (json['average_accuracy_week'] as num?)?.toDouble() ?? 0.0,
      certificatesEarnedWeek: json['certificates_earned_week'] ?? 0,
      exchangesCompletedWeek: json['exchanges_completed_week'] ?? 0,
      timeSpentMinutesWeek: json['time_spent_minutes_week'] ?? 0,
      streakDays: json['streak_days'] ?? 0,
      consistencyRating: json['consistency_rating'] ?? 'Active Learner',
      highlights: (json['highlights'] as List?)?.map((e) => e.toString()).toList() ?? [],
      hasSufficientHistory: json['has_sufficient_history'] ?? false,
    );
  }
}

class AdaptiveRecommendationModel {
  final String id;
  final String categoryType;
  final String title;
  final String subtitle;
  final String priority;
  final int confidenceScore;
  final String actionLabel;
  final String actionType;
  final int targetId;
  final int? pathId;
  final String sourceSignal;

  AdaptiveRecommendationModel({
    required this.id,
    required this.categoryType,
    required this.title,
    required this.subtitle,
    required this.priority,
    required this.confidenceScore,
    required this.actionLabel,
    required this.actionType,
    required this.targetId,
    this.pathId,
    required this.sourceSignal,
  });

  factory AdaptiveRecommendationModel.fromJson(Map<String, dynamic> json) {
    return AdaptiveRecommendationModel(
      id: json['id'] ?? '',
      categoryType: json['category_type'] ?? 'LEARN_NEXT',
      title: json['title'] ?? '',
      subtitle: json['subtitle'] ?? '',
      priority: json['priority'] ?? 'medium',
      confidenceScore: json['confidence_score'] ?? 90,
      actionLabel: json['action_label'] ?? 'Open',
      actionType: json['action_type'] ?? 'learning',
      targetId: json['target_id'] ?? 0,
      pathId: json['path_id'],
      sourceSignal: json['source_signal'] ?? '',
    );
  }
}

class AiCoachSummaryModel {
  final int userId;
  final String userName;
  final int userXp;
  final int streakDays;
  final HeroRecommendationModel? heroRecommendation;
  final DailyGoalModel? dailyGoal;
  final List<DailyPlanItemModel> dailyPlan;
  final SkillGrowthModel? growthSummary;
  final WeeklyGrowthInsightsModel? weeklyInsights;
  final List<AdaptiveRecommendationModel> adaptiveRecommendations;
  final List<SkillGapModel> skillGaps;
  final List<SkillStrengthModel> strengths;
  final List<DevelopingSkillModel> developingSkills;
  final List<DevelopingSkillModel> needsPracticeSkills;
  final List<SkillPortfolioItemModel> skillPortfolio;
  final List<RoadmapStepModel> roadmapPreview;
  final List<PracticeDiagnosticModel> practiceDiagnostics;
  final List<ExchangeSuggestionModel> exchangeSuggestions;
  final List<String> learningInsights;

  AiCoachSummaryModel({
    required this.userId,
    required this.userName,
    required this.userXp,
    required this.streakDays,
    this.heroRecommendation,
    this.dailyGoal,
    this.dailyPlan = const [],
    this.growthSummary,
    this.weeklyInsights,
    this.adaptiveRecommendations = const [],
    this.skillGaps = const [],
    this.strengths = const [],
    this.developingSkills = const [],
    this.needsPracticeSkills = const [],
    this.skillPortfolio = const [],
    this.roadmapPreview = const [],
    this.practiceDiagnostics = const [],
    this.exchangeSuggestions = const [],
    this.learningInsights = const [],
  });

  factory AiCoachSummaryModel.fromJson(Map<String, dynamic> json) {
    return AiCoachSummaryModel(
      userId: json['user_id'] ?? 0,
      userName: json['user_name'] ?? 'Learner',
      userXp: json['user_xp'] ?? 0,
      streakDays: json['streak_days'] ?? 0,
      heroRecommendation: json['hero_recommendation'] != null
          ? HeroRecommendationModel.fromJson(json['hero_recommendation'])
          : null,
      dailyGoal: json['daily_goal'] != null
          ? DailyGoalModel.fromJson(json['daily_goal'])
          : null,
      dailyPlan: (json['daily_plan'] as List?)
              ?.map((e) => DailyPlanItemModel.fromJson(Map<String, dynamic>.from(e)))
              .toList() ??
          [],
      growthSummary: json['growth_summary'] != null
          ? SkillGrowthModel.fromJson(json['growth_summary'])
          : null,
      weeklyInsights: json['weekly_insights'] != null
          ? WeeklyGrowthInsightsModel.fromJson(json['weekly_insights'])
          : null,
      adaptiveRecommendations: (json['adaptive_recommendations'] as List?)
              ?.map((e) => AdaptiveRecommendationModel.fromJson(e))
              .toList() ??
          [],
      skillGaps: (json['skill_gaps'] as List?)?.map((e) => SkillGapModel.fromJson(e)).toList() ?? [],
      strengths: (json['strengths'] as List?)?.map((e) => SkillStrengthModel.fromJson(e)).toList() ?? [],
      developingSkills: (json['developing_skills'] as List?)?.map((e) => DevelopingSkillModel.fromJson(e)).toList() ?? [],
      needsPracticeSkills: (json['needs_practice_skills'] as List?)?.map((e) => DevelopingSkillModel.fromJson(e)).toList() ?? [],
      skillPortfolio: (json['skill_portfolio'] as List?)?.map((e) => SkillPortfolioItemModel.fromJson(e)).toList() ?? [],
      roadmapPreview: (json['roadmap_preview'] as List?)?.map((e) => RoadmapStepModel.fromJson(e)).toList() ?? [],
      practiceDiagnostics: (json['practice_diagnostics'] as List?)?.map((e) => PracticeDiagnosticModel.fromJson(e)).toList() ?? [],
      exchangeSuggestions: (json['exchange_suggestions'] as List?)?.map((e) => ExchangeSuggestionModel.fromJson(e)).toList() ?? [],
      learningInsights: (json['learning_insights'] as List?)?.map((e) => e.toString()).toList() ?? [],
    );
  }
}

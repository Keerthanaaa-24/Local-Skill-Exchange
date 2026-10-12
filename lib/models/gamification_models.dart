class UserLevelInfoModel {
  final int level;
  final int currentXp;
  final int nextLevelXp;
  final int currentLevelMinXp;
  final double levelProgressPercent;

  UserLevelInfoModel({
    required this.level,
    required this.currentXp,
    required this.nextLevelXp,
    required this.currentLevelMinXp,
    required this.levelProgressPercent,
  });

  factory UserLevelInfoModel.fromJson(Map<String, dynamic> json) {
    return UserLevelInfoModel(
      level: json['level'] is int ? json['level'] : int.tryParse(json['level']?.toString() ?? '') ?? 1,
      currentXp: json['current_xp'] is int ? json['current_xp'] : int.tryParse(json['current_xp']?.toString() ?? '') ?? 0,
      nextLevelXp: json['next_level_xp'] is int ? json['next_level_xp'] : int.tryParse(json['next_level_xp']?.toString() ?? '') ?? 100,
      currentLevelMinXp: json['current_level_min_xp'] is int ? json['current_level_min_xp'] : int.tryParse(json['current_level_min_xp']?.toString() ?? '') ?? 0,
      levelProgressPercent: json['level_progress_percent'] is num ? (json['level_progress_percent'] as num).toDouble() : 0.0,
    );
  }

  String get title {
    if (level <= 1) return 'Novice';
    if (level == 2) return 'Apprentice';
    if (level == 3) return 'Practitioner';
    if (level == 4) return 'Master';
    return 'Grandmaster';
  }

  int get xpToNextLevel => (nextLevelXp - currentXp).clamp(0, 99999);
}

class LearningStreakModel {
  final int currentStreak;
  final int longestStreak;
  final String? lastActiveDate;

  LearningStreakModel({
    required this.currentStreak,
    required this.longestStreak,
    this.lastActiveDate,
  });

  factory LearningStreakModel.fromJson(Map<String, dynamic> json) {
    return LearningStreakModel(
      currentStreak: json['current_streak'] is int ? json['current_streak'] : int.tryParse(json['current_streak']?.toString() ?? '') ?? 0,
      longestStreak: json['longest_streak'] is int ? json['longest_streak'] : int.tryParse(json['longest_streak']?.toString() ?? '') ?? 0,
      lastActiveDate: json['last_active_date']?.toString(),
    );
  }
}

class LearningStatsModel {
  final int totalPathsAvailable;
  final int pathsStarted;
  final int pathsCompleted;
  final int lessonsCompleted;
  final int practiceAttempts;
  final double practicePassRate;
  final int certificatesEarned;
  final int completedExchanges;

  LearningStatsModel({
    required this.totalPathsAvailable,
    required this.pathsStarted,
    required this.pathsCompleted,
    required this.lessonsCompleted,
    required this.practiceAttempts,
    required this.practicePassRate,
    required this.certificatesEarned,
    required this.completedExchanges,
  });

  factory LearningStatsModel.fromJson(Map<String, dynamic> json) {
    return LearningStatsModel(
      totalPathsAvailable: json['total_paths_available'] ?? 0,
      pathsStarted: json['paths_started'] ?? 0,
      pathsCompleted: json['paths_completed'] ?? 0,
      lessonsCompleted: json['lessons_completed'] ?? 0,
      practiceAttempts: json['practice_attempts'] ?? 0,
      practicePassRate: json['practice_pass_rate'] is num ? (json['practice_pass_rate'] as num).toDouble() : 0.0,
      certificatesEarned: json['certificates_earned'] ?? 0,
      completedExchanges: json['completed_exchanges'] ?? 0,
    );
  }
}

class AchievementModel {
  final int id;
  final String code;
  final String title;
  final String description;
  final String requirement;
  final String icon;
  final String category;
  final bool isUnlocked;
  final DateTime? earnedAt;

  AchievementModel({
    required this.id,
    required this.code,
    required this.title,
    required this.description,
    required this.requirement,
    required this.icon,
    required this.category,
    this.isUnlocked = false,
    this.earnedAt,
  });

  factory AchievementModel.fromJson(Map<String, dynamic> json) {
    return AchievementModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '') ?? 0,
      code: json['code'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      requirement: json['requirement'] ?? '',
      icon: json['icon'] ?? 'emoji_events',
      category: json['category'] ?? 'learning',
      isUnlocked: json['is_unlocked'] ?? false,
      earnedAt: json['earned_at'] != null ? DateTime.tryParse(json['earned_at'].toString()) : null,
    );
  }
}

class GrowthMilestoneModel {
  final String milestoneType;
  final String title;
  final String description;
  final DateTime timestamp;
  final String? badge;

  GrowthMilestoneModel({
    required this.milestoneType,
    required this.title,
    required this.description,
    required this.timestamp,
    this.badge,
  });

  factory GrowthMilestoneModel.fromJson(Map<String, dynamic> json) {
    return GrowthMilestoneModel(
      milestoneType: json['milestone_type'] ?? 'general',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'].toString()) ?? DateTime.now()
          : DateTime.now(),
      badge: json['badge'],
    );
  }
}

class LeaderboardEntryModel {
  final int rank;
  final int userId;
  final String name;
  final String? title;
  final String? avatarUrl;
  final int xp;
  final int level;
  final int completedPaths;
  final int certificatesCount;
  final int completedExchanges;

  LeaderboardEntryModel({
    required this.rank,
    required this.userId,
    required this.name,
    this.title,
    this.avatarUrl,
    required this.xp,
    required this.level,
    required this.completedPaths,
    required this.certificatesCount,
    required this.completedExchanges,
  });

  factory LeaderboardEntryModel.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntryModel(
      rank: json['rank'] ?? 0,
      userId: json['user_id'] is int ? json['user_id'] : int.tryParse(json['user_id']?.toString() ?? '') ?? 0,
      name: json['name'] ?? 'Learner',
      title: json['title'],
      avatarUrl: json['avatar_url'],
      xp: json['xp'] ?? 0,
      level: json['level'] ?? 1,
      completedPaths: json['completed_paths'] ?? 0,
      certificatesCount: json['certificates_count'] ?? 0,
      completedExchanges: json['completed_exchanges'] ?? 0,
    );
  }
}

class GamificationDashboardModel {
  final UserLevelInfoModel levelInfo;
  final LearningStreakModel streakInfo;
  final LearningStatsModel learningStats;
  final int unlockedAchievementsCount;
  final int totalAchievementsCount;
  final List<AchievementModel> recentAchievements;
  final AchievementModel? nextAchievement;
  final List<GrowthMilestoneModel> recentMilestones;

  GamificationDashboardModel({
    required this.levelInfo,
    required this.streakInfo,
    required this.learningStats,
    required this.unlockedAchievementsCount,
    required this.totalAchievementsCount,
    required this.recentAchievements,
    this.nextAchievement,
    required this.recentMilestones,
  });

  factory GamificationDashboardModel.fromJson(Map<String, dynamic> json) {
    return GamificationDashboardModel(
      levelInfo: UserLevelInfoModel.fromJson(Map<String, dynamic>.from(json['level_info'] ?? {})),
      streakInfo: LearningStreakModel.fromJson(Map<String, dynamic>.from(json['streak_info'] ?? {})),
      learningStats: LearningStatsModel.fromJson(Map<String, dynamic>.from(json['learning_stats'] ?? {})),
      unlockedAchievementsCount: json['unlocked_achievements_count'] ?? 0,
      totalAchievementsCount: json['total_achievements_count'] ?? 0,
      recentAchievements: json['recent_achievements'] is List
          ? (json['recent_achievements'] as List).map((e) => AchievementModel.fromJson(Map<String, dynamic>.from(e))).toList()
          : [],
      nextAchievement: json['next_achievement'] != null
          ? AchievementModel.fromJson(Map<String, dynamic>.from(json['next_achievement']))
          : null,
      recentMilestones: json['recent_milestones'] is List
          ? (json['recent_milestones'] as List).map((e) => GrowthMilestoneModel.fromJson(Map<String, dynamic>.from(e))).toList()
          : [],
    );
  }
}

class QuizQuestionModel {
  final int id;
  final int quizId;
  final String questionText;
  final String questionType;
  final List<String> options;
  final int points;

  QuizQuestionModel({
    required this.id,
    required this.quizId,
    required this.questionText,
    this.questionType = 'mcq',
    required this.options,
    this.points = 10,
  });

  factory QuizQuestionModel.fromJson(Map<String, dynamic> json) {
    return QuizQuestionModel(
      id: (json['id'] is int) ? json['id'] as int : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      quizId: (json['quiz_id'] is int) ? json['quiz_id'] as int : int.tryParse(json['quiz_id']?.toString() ?? '0') ?? 0,
      questionText: json['question_text']?.toString() ?? '',
      questionType: json['question_type']?.toString() ?? 'mcq',
      options: (json['options'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      points: (json['points'] is int) ? json['points'] as int : int.tryParse(json['points']?.toString() ?? '10') ?? 10,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'quiz_id': quizId,
        'question_text': questionText,
        'question_type': questionType,
        'options': options,
        'points': points,
      };
}

class QuizModel {
  final int id;
  final int learningPathId;
  final int? lessonId;
  final String title;
  final String? description;
  final int timeLimitMinutes;
  final int passingPercentage;
  final int maxAttempts;
  final List<QuizQuestionModel> questions;

  QuizModel({
    required this.id,
    required this.learningPathId,
    this.lessonId,
    required this.title,
    this.description,
    this.timeLimitMinutes = 15,
    this.passingPercentage = 70,
    this.maxAttempts = 10,
    this.questions = const [],
  });

  factory QuizModel.fromJson(Map<String, dynamic> json) {
    return QuizModel(
      id: (json['id'] is int) ? json['id'] as int : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      learningPathId: (json['learning_path_id'] is int)
          ? json['learning_path_id'] as int
          : int.tryParse(json['learning_path_id']?.toString() ?? '0') ?? 0,
      lessonId: json['lesson_id'] != null
          ? ((json['lesson_id'] is int) ? json['lesson_id'] as int : int.tryParse(json['lesson_id'].toString()))
          : null,
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString(),
      timeLimitMinutes: (json['time_limit_minutes'] is int)
          ? json['time_limit_minutes'] as int
          : int.tryParse(json['time_limit_minutes']?.toString() ?? '15') ?? 15,
      passingPercentage: (json['passing_percentage'] is int)
          ? json['passing_percentage'] as int
          : int.tryParse(json['passing_percentage']?.toString() ?? '70') ?? 70,
      maxAttempts: (json['max_attempts'] is int)
          ? json['max_attempts'] as int
          : int.tryParse(json['max_attempts']?.toString() ?? '10') ?? 10,
      questions: (json['questions'] as List<dynamic>?)
              ?.map((e) => QuizQuestionModel.fromJson(Map<String, dynamic>.from(e)))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'learning_path_id': learningPathId,
        'lesson_id': lessonId,
        'title': title,
        'description': description,
        'time_limit_minutes': timeLimitMinutes,
        'passing_percentage': passingPercentage,
        'max_attempts': maxAttempts,
        'questions': questions.map((e) => e.toJson()).toList(),
      };
}

class QuizFeedbackModel {
  final int questionId;
  final String questionText;
  final String userAnswer;
  final String correctAnswer;
  final bool isCorrect;
  final String? explanation;
  final int pointsEarned;
  final int pointsPossible;

  QuizFeedbackModel({
    required this.questionId,
    required this.questionText,
    required this.userAnswer,
    required this.correctAnswer,
    required this.isCorrect,
    this.explanation,
    required this.pointsEarned,
    required this.pointsPossible,
  });

  factory QuizFeedbackModel.fromJson(Map<String, dynamic> json) {
    return QuizFeedbackModel(
      questionId: (json['question_id'] is int) ? json['question_id'] as int : int.tryParse(json['question_id']?.toString() ?? '0') ?? 0,
      questionText: json['question_text']?.toString() ?? '',
      userAnswer: json['user_answer']?.toString() ?? '',
      correctAnswer: json['correct_answer']?.toString() ?? '',
      isCorrect: json['is_correct'] == true,
      explanation: json['explanation']?.toString(),
      pointsEarned: (json['points_earned'] is int) ? json['points_earned'] as int : int.tryParse(json['points_earned']?.toString() ?? '0') ?? 0,
      pointsPossible: (json['points_possible'] is int) ? json['points_possible'] as int : int.tryParse(json['points_possible']?.toString() ?? '0') ?? 0,
    );
  }
}

class QuizResultModel {
  final int quizId;
  final int attemptNumber;
  final int marksObtained;
  final int maximumMarks;
  final double percentage;
  final bool passed;
  final int xpEarned;
  final List<QuizFeedbackModel> feedback;
  final DateTime completedAt;

  QuizResultModel({
    required this.quizId,
    required this.attemptNumber,
    required this.marksObtained,
    required this.maximumMarks,
    required this.percentage,
    required this.passed,
    this.xpEarned = 0,
    this.feedback = const [],
    required this.completedAt,
  });

  factory QuizResultModel.fromJson(Map<String, dynamic> json) {
    return QuizResultModel(
      quizId: (json['quiz_id'] is int) ? json['quiz_id'] as int : int.tryParse(json['quiz_id']?.toString() ?? '0') ?? 0,
      attemptNumber: (json['attempt_number'] is int) ? json['attempt_number'] as int : int.tryParse(json['attempt_number']?.toString() ?? '1') ?? 1,
      marksObtained: (json['marks_obtained'] is int) ? json['marks_obtained'] as int : int.tryParse(json['marks_obtained']?.toString() ?? '0') ?? 0,
      maximumMarks: (json['maximum_marks'] is int) ? json['maximum_marks'] as int : int.tryParse(json['maximum_marks']?.toString() ?? '0') ?? 0,
      percentage: (json['percentage'] is num) ? (json['percentage'] as num).toDouble() : double.tryParse(json['percentage']?.toString() ?? '0.0') ?? 0.0,
      passed: json['passed'] == true,
      xpEarned: (json['xp_earned'] is int) ? json['xp_earned'] as int : int.tryParse(json['xp_earned']?.toString() ?? '0') ?? 0,
      feedback: (json['feedback'] as List<dynamic>?)
              ?.map((e) => QuizFeedbackModel.fromJson(Map<String, dynamic>.from(e)))
              .toList() ??
          [],
      completedAt: json['completed_at'] != null ? DateTime.tryParse(json['completed_at'].toString()) ?? DateTime.now() : DateTime.now(),
    );
  }
}

class QuizAttemptModel {
  final int id;
  final int userId;
  final int quizId;
  final int attemptNumber;
  final int marksObtained;
  final int maximumMarks;
  final double percentage;
  final bool passed;
  final int durationSeconds;
  final DateTime completedAt;

  QuizAttemptModel({
    required this.id,
    required this.userId,
    required this.quizId,
    required this.attemptNumber,
    required this.marksObtained,
    required this.maximumMarks,
    required this.percentage,
    required this.passed,
    required this.durationSeconds,
    required this.completedAt,
  });

  factory QuizAttemptModel.fromJson(Map<String, dynamic> json) {
    return QuizAttemptModel(
      id: (json['id'] is int) ? json['id'] as int : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      userId: (json['user_id'] is int) ? json['user_id'] as int : int.tryParse(json['user_id']?.toString() ?? '0') ?? 0,
      quizId: (json['quiz_id'] is int) ? json['quiz_id'] as int : int.tryParse(json['quiz_id']?.toString() ?? '0') ?? 0,
      attemptNumber: (json['attempt_number'] is int) ? json['attempt_number'] as int : int.tryParse(json['attempt_number']?.toString() ?? '1') ?? 1,
      marksObtained: (json['marks_obtained'] is int) ? json['marks_obtained'] as int : int.tryParse(json['marks_obtained']?.toString() ?? '0') ?? 0,
      maximumMarks: (json['maximum_marks'] is int) ? json['maximum_marks'] as int : int.tryParse(json['maximum_marks']?.toString() ?? '0') ?? 0,
      percentage: (json['percentage'] is num) ? (json['percentage'] as num).toDouble() : double.tryParse(json['percentage']?.toString() ?? '0.0') ?? 0.0,
      passed: json['passed'] == true,
      durationSeconds: (json['duration_seconds'] is int) ? json['duration_seconds'] as int : int.tryParse(json['duration_seconds']?.toString() ?? '0') ?? 0,
      completedAt: json['completed_at'] != null ? DateTime.tryParse(json['completed_at'].toString()) ?? DateTime.now() : DateTime.now(),
    );
  }
}

class LearningDashboardSkillModel {
  final int skillId;
  final String skillName;
  final int learningPathId;
  final String pathTitle;
  final int totalLessons;
  final int completedLessonsCount;
  final double progressPercentage;
  final int? nextLessonId;
  final String? nextLessonTitle;

  LearningDashboardSkillModel({
    required this.skillId,
    required this.skillName,
    required this.learningPathId,
    required this.pathTitle,
    required this.totalLessons,
    required this.completedLessonsCount,
    required this.progressPercentage,
    this.nextLessonId,
    this.nextLessonTitle,
  });

  factory LearningDashboardSkillModel.fromJson(Map<String, dynamic> json) {
    return LearningDashboardSkillModel(
      skillId: (json['skill_id'] is int) ? json['skill_id'] as int : int.tryParse(json['skill_id']?.toString() ?? '0') ?? 0,
      skillName: json['skill_name']?.toString() ?? '',
      learningPathId: (json['learning_path_id'] is int) ? json['learning_path_id'] as int : int.tryParse(json['learning_path_id']?.toString() ?? '0') ?? 0,
      pathTitle: json['path_title']?.toString() ?? '',
      totalLessons: (json['total_lessons'] is int) ? json['total_lessons'] as int : int.tryParse(json['total_lessons']?.toString() ?? '0') ?? 0,
      completedLessonsCount: (json['completed_lessons_count'] is int) ? json['completed_lessons_count'] as int : int.tryParse(json['completed_lessons_count']?.toString() ?? '0') ?? 0,
      progressPercentage: (json['progress_percentage'] is num) ? (json['progress_percentage'] as num).toDouble() : double.tryParse(json['progress_percentage']?.toString() ?? '0.0') ?? 0.0,
      nextLessonId: json['next_lesson_id'] != null ? ((json['next_lesson_id'] is int) ? json['next_lesson_id'] as int : int.tryParse(json['next_lesson_id'].toString())) : null,
      nextLessonTitle: json['next_lesson_title']?.toString(),
    );
  }
}

class LearningDashboardModel {
  final List<LearningDashboardSkillModel> activeSkills;
  final int totalEnrolledPaths;
  final int totalCompletedPaths;
  final int totalLessonsCompleted;
  final double overallProgressPercentage;
  final double quizAverageScore;
  final int totalQuizAttempts;
  final int totalCertificates;
  final int streakDays;
  final int totalXp;
  final List<QuizAttemptModel> recentQuizAttempts;

  LearningDashboardModel({
    this.activeSkills = const [],
    this.totalEnrolledPaths = 0,
    this.totalCompletedPaths = 0,
    this.totalLessonsCompleted = 0,
    this.overallProgressPercentage = 0.0,
    this.quizAverageScore = 0.0,
    this.totalQuizAttempts = 0,
    this.totalCertificates = 0,
    this.streakDays = 1,
    this.totalXp = 0,
    this.recentQuizAttempts = const [],
  });

  factory LearningDashboardModel.fromJson(Map<String, dynamic> json) {
    return LearningDashboardModel(
      activeSkills: (json['active_skills'] as List<dynamic>?)
              ?.map((e) => LearningDashboardSkillModel.fromJson(Map<String, dynamic>.from(e)))
              .toList() ??
          [],
      totalEnrolledPaths: (json['total_enrolled_paths'] is int) ? json['total_enrolled_paths'] as int : int.tryParse(json['total_enrolled_paths']?.toString() ?? '0') ?? 0,
      totalCompletedPaths: (json['total_completed_paths'] is int) ? json['total_completed_paths'] as int : int.tryParse(json['total_completed_paths']?.toString() ?? '0') ?? 0,
      totalLessonsCompleted: (json['total_lessons_completed'] is int) ? json['total_lessons_completed'] as int : int.tryParse(json['total_lessons_completed']?.toString() ?? '0') ?? 0,
      overallProgressPercentage: (json['overall_progress_percentage'] is num) ? (json['overall_progress_percentage'] as num).toDouble() : double.tryParse(json['overall_progress_percentage']?.toString() ?? '0.0') ?? 0.0,
      quizAverageScore: (json['quiz_average_score'] is num) ? (json['quiz_average_score'] as num).toDouble() : double.tryParse(json['quiz_average_score']?.toString() ?? '0.0') ?? 0.0,
      totalQuizAttempts: (json['total_quiz_attempts'] is int) ? json['total_quiz_attempts'] as int : int.tryParse(json['total_quiz_attempts']?.toString() ?? '0') ?? 0,
      totalCertificates: (json['total_certificates'] is int) ? json['total_certificates'] as int : int.tryParse(json['total_certificates']?.toString() ?? '0') ?? 0,
      streakDays: (json['streak_days'] is int) ? json['streak_days'] as int : int.tryParse(json['streak_days']?.toString() ?? '1') ?? 1,
      totalXp: (json['total_xp'] is int) ? json['total_xp'] as int : int.tryParse(json['total_xp']?.toString() ?? '0') ?? 0,
      recentQuizAttempts: (json['recent_quiz_attempts'] as List<dynamic>?)
              ?.map((e) => QuizAttemptModel.fromJson(Map<String, dynamic>.from(e)))
              .toList() ??
          [],
    );
  }
}

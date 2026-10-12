class PracticeAttemptModel {
  final int lessonId;
  final int totalQuestions;
  final int correctAnswers;
  final int incorrectAnswers;
  final double percentage;
  final bool passed;

  PracticeAttemptModel({
    required this.lessonId,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.incorrectAnswers,
    required this.percentage,
    required this.passed,
  });

  factory PracticeAttemptModel.fromJson(Map<String, dynamic> json) {
    return PracticeAttemptModel(
      lessonId: json['lesson_id'] as int,
      totalQuestions: json['total_questions'] as int,
      correctAnswers: json['correct_answers'] as int,
      incorrectAnswers: json['incorrect_answers'] as int,
      percentage: (json['percentage'] as num).toDouble(),
      passed: json['passed'] as bool,
    );
  }

  Map<String, dynamic> toJson() => {
        'lesson_id': lessonId,
        'total_questions': totalQuestions,
        'correct_answers': correctAnswers,
        'incorrect_answers': incorrectAnswers,
        'percentage': percentage,
        'passed': passed,
      };
}

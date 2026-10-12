class PracticeFeedbackItem {
  final int questionId;
  final bool correct;
  final String? explanation;

  PracticeFeedbackItem({
    required this.questionId,
    required this.correct,
    this.explanation,
  });

  factory PracticeFeedbackItem.fromJson(Map<String, dynamic> json) {
    return PracticeFeedbackItem(
      questionId: json['question_id'] as int,
      correct: json['correct'] as bool,
      explanation: json['explanation'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'question_id': questionId,
        'correct': correct,
        'explanation': explanation,
      };
}

class PracticeResultModel {
  final int lessonId;
  final int totalQuestions;
  final int correctAnswers;
  final int incorrectAnswers;
  final double percentage;
  final bool passed;
  final List<PracticeFeedbackItem> feedback;

  PracticeResultModel({
    required this.lessonId,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.incorrectAnswers,
    required this.percentage,
    required this.passed,
    required this.feedback,
  });

  factory PracticeResultModel.fromJson(Map<String, dynamic> json) {
    return PracticeResultModel(
      lessonId: json['lesson_id'] as int,
      totalQuestions: json['total_questions'] as int,
      correctAnswers: json['correct_answers'] as int,
      incorrectAnswers: json['incorrect_answers'] as int,
      percentage: (json['percentage'] as num).toDouble(),
      passed: json['passed'] as bool,
      feedback: (json['feedback'] as List<dynamic>?)
              ?.map((e) => PracticeFeedbackItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
        'lesson_id': lessonId,
        'total_questions': totalQuestions,
        'correct_answers': correctAnswers,
        'incorrect_answers': incorrectAnswers,
        'percentage': percentage,
        'passed': passed,
        'feedback': feedback.map((e) => e.toJson()).toList(),
      };
}

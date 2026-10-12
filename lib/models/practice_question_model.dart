class PracticeQuestionModel {
  final int id;
  final int lessonId;
  final String question;
  final String questionType;
  final List<String> options;
  final String? explanation;

  PracticeQuestionModel({
    required this.id,
    required this.lessonId,
    required this.question,
    this.questionType = 'mcq',
    required this.options,
    this.explanation,
  });

  factory PracticeQuestionModel.fromJson(Map<String, dynamic> json) {
    return PracticeQuestionModel(
      id: json['id'] as int,
      lessonId: json['lesson_id'] as int,
      question: json['question'] as String,
      questionType: (json['question_type'] as String?) ?? 'mcq',
      options: (json['options'] as List<dynamic>).map((e) => e.toString()).toList(),
      explanation: json['explanation'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'lesson_id': lessonId,
        'question': question,
        'question_type': questionType,
        'options': options,
        'explanation': explanation,
      };
}

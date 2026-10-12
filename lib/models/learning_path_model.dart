import 'lesson_model.dart';

class LearningPathModel {
  final int id;
  final int skillId;
  final String title;
  final String? description;
  final int? estimatedMinutes;
  final List<LessonModel> lessons;

  LearningPathModel({
    required this.id,
    required this.skillId,
    required this.title,
    this.description,
    this.estimatedMinutes,
    this.lessons = const [],
  });

  factory LearningPathModel.fromJson(Map<String, dynamic> json) {
    return LearningPathModel(
      id: (json['id'] is int) ? json['id'] as int : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      skillId: (json['skill_id'] is int) ? json['skill_id'] as int : int.tryParse(json['skill_id']?.toString() ?? '0') ?? 0,
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString(),
      estimatedMinutes: json['estimated_minutes'] != null
          ? ((json['estimated_minutes'] is int)
              ? json['estimated_minutes'] as int
              : int.tryParse(json['estimated_minutes'].toString()))
          : null,
      lessons: (json['lessons'] as List<dynamic>?)
              ?.map((e) => LessonModel.fromJson(Map<String, dynamic>.from(e)))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'skill_id': skillId,
        'title': title,
        'description': description,
        'estimated_minutes': estimatedMinutes,
        'lessons': lessons.map((e) => e.toJson()).toList(),
      };
}

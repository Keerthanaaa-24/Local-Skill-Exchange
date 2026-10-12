class LearningProgressModel {
  final int id;
  final int userId;
  final int learningPathId;
  final DateTime startedAt;
  final DateTime? completedAt;
  final List<int> completedLessons;

  LearningProgressModel({
    required this.id,
    required this.userId,
    required this.learningPathId,
    required this.startedAt,
    this.completedAt,
    this.completedLessons = const [],
  });

  factory LearningProgressModel.fromJson(Map<String, dynamic> json) {
    final rawCompleted = json['completed_lessons'];
    List<int> completedList = [];
    if (rawCompleted is List) {
      completedList = rawCompleted
          .map((e) => (e is int) ? e : int.tryParse(e.toString()))
          .whereType<int>()
          .toList();
    } else if (rawCompleted is String && rawCompleted.isNotEmpty) {
      completedList = rawCompleted
          .split(',')
          .map((s) => int.tryParse(s.trim()))
          .whereType<int>()
          .toList();
    }

    return LearningProgressModel(
      id: (json['id'] is int) ? json['id'] as int : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      userId: (json['user_id'] is int) ? json['user_id'] as int : int.tryParse(json['user_id']?.toString() ?? '0') ?? 0,
      learningPathId: (json['learning_path_id'] is int)
          ? json['learning_path_id'] as int
          : int.tryParse(json['learning_path_id']?.toString() ?? '0') ?? 0,
      startedAt: json['started_at'] != null ? DateTime.tryParse(json['started_at'].toString()) ?? DateTime.now() : DateTime.now(),
      completedAt: json['completed_at'] != null ? DateTime.tryParse(json['completed_at'].toString()) : null,
      completedLessons: completedList,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'learning_path_id': learningPathId,
        'started_at': startedAt.toIso8601String(),
        'completed_at': completedAt?.toIso8601String(),
        'completed_lessons': completedLessons,
      };
}

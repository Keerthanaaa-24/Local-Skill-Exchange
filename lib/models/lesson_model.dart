class LearningResourceModel {
  final int id;
  final int lessonId;
  final String resourceType;
  final String title;
  final String url;
  final String? source;
  final int? durationMinutes;
  final bool isPrimary;

  LearningResourceModel({
    required this.id,
    required this.lessonId,
    required this.resourceType,
    required this.title,
    required this.url,
    this.source,
    this.durationMinutes,
    this.isPrimary = false,
  });

  factory LearningResourceModel.fromJson(Map<String, dynamic> json) {
    return LearningResourceModel(
      id: (json['id'] is int) ? json['id'] as int : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      lessonId: (json['lesson_id'] is int) ? json['lesson_id'] as int : int.tryParse(json['lesson_id']?.toString() ?? '0') ?? 0,
      resourceType: json['resource_type']?.toString() ?? 'DOCS',
      title: json['title']?.toString() ?? '',
      url: json['url']?.toString() ?? '',
      source: json['source']?.toString(),
      durationMinutes: json['duration_minutes'] != null
          ? ((json['duration_minutes'] is int) ? json['duration_minutes'] as int : int.tryParse(json['duration_minutes'].toString()))
          : null,
      isPrimary: json['is_primary'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'lesson_id': lessonId,
        'resource_type': resourceType,
        'title': title,
        'url': url,
        'source': source,
        'duration_minutes': durationMinutes,
        'is_primary': isPrimary,
      };
}

class LessonModel {
  final int id;
  final int learningPathId;
  final String title;
  final String? content;
  final String? summary;
  final String? videoUrl;
  final String? pdfUrl;
  final String? docUrl;
  final int order;
  final int? estimatedMinutes;
  final List<LearningResourceModel> resources;

  LessonModel({
    required this.id,
    required this.learningPathId,
    required this.title,
    this.content,
    this.summary,
    this.videoUrl,
    this.pdfUrl,
    this.docUrl,
    required this.order,
    this.estimatedMinutes,
    this.resources = const [],
  });

  factory LessonModel.fromJson(Map<String, dynamic> json) {
    return LessonModel(
      id: (json['id'] is int) ? json['id'] as int : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      learningPathId: (json['learning_path_id'] is int)
          ? json['learning_path_id'] as int
          : int.tryParse(json['learning_path_id']?.toString() ?? '0') ?? 0,
      title: json['title']?.toString() ?? '',
      content: json['content']?.toString(),
      summary: json['summary']?.toString(),
      videoUrl: json['video_url']?.toString(),
      pdfUrl: json['pdf_url']?.toString(),
      docUrl: json['doc_url']?.toString(),
      order: (json['order'] is int) ? json['order'] as int : int.tryParse(json['order']?.toString() ?? '0') ?? 0,
      estimatedMinutes: json['estimated_minutes'] != null
          ? ((json['estimated_minutes'] is int)
              ? json['estimated_minutes'] as int
              : int.tryParse(json['estimated_minutes'].toString()))
          : null,
      resources: (json['resources'] as List<dynamic>?)
              ?.map((e) => LearningResourceModel.fromJson(Map<String, dynamic>.from(e)))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'learning_path_id': learningPathId,
        'title': title,
        'content': content,
        'summary': summary,
        'video_url': videoUrl,
        'pdf_url': pdfUrl,
        'doc_url': docUrl,
        'order': order,
        'estimated_minutes': estimatedMinutes,
        'resources': resources.map((e) => e.toJson()).toList(),
      };
}

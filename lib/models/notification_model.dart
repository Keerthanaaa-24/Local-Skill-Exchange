class NotificationModel {
  final int id;
  final int userId;
  final String title;
  final String body;
  final String type;
  final int? referenceId;
  final String? referenceType;
  final String? imageUrl;
  final bool isRead;
  final String createdAt;
  final String? updatedAt;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    this.referenceId,
    this.referenceType,
    this.imageUrl,
    required this.isRead,
    required this.createdAt,
    this.updatedAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    final rawTitle = (json['title'] ?? '').toString();
    final rawBody = (json['body'] ?? json['message'] ?? '').toString();
    String detectedType = (json['type'] ?? '').toString().toLowerCase();

    if (detectedType.isEmpty || detectedType == 'general' || detectedType == 'system') {
      final combined = '$rawTitle $rawBody'.toLowerCase();
      if (combined.contains('session') || combined.contains('booking') || combined.contains('exchange')) {
        detectedType = 'session';
      } else if (combined.contains('quiz') || combined.contains('learning') || combined.contains('lesson') || combined.contains('course')) {
        detectedType = 'learning';
      } else if (combined.contains('certificate') || combined.contains('passport') || combined.contains('credential')) {
        detectedType = 'certificate';
      } else if (combined.contains('credit') || combined.contains('wallet') || combined.contains('earned') || combined.contains('spent')) {
        detectedType = 'credit';
      } else if (combined.contains('message') || combined.contains('chat')) {
        detectedType = 'chat';
      } else if (combined.contains('review') || combined.contains('rated') || combined.contains('community')) {
        detectedType = 'community';
      } else {
        detectedType = 'general';
      }
    }

    return NotificationModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      userId: json['user_id'] is int ? json['user_id'] : (json['userId'] is int ? json['userId'] : 0),
      title: rawTitle,
      body: rawBody,
      type: detectedType,
      referenceId: json['reference_id'] ?? json['referenceId'],
      referenceType: json['reference_type'] ?? json['referenceType'],
      imageUrl: json['image_url'] ?? json['imageUrl'],
      isRead: json['is_read'] ?? json['isRead'] ?? false,
      createdAt: json['created_at'] ?? json['createdAt'] ?? DateTime.now().toUtc().toIso8601String(),
      updatedAt: json['updated_at'] ?? json['updatedAt'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'body': body,
      'type': type,
      if (referenceId != null) 'reference_id': referenceId,
      if (referenceType != null) 'reference_type': referenceType,
      if (imageUrl != null) 'image_url': imageUrl,
      'is_read': isRead,
      'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    };
  }

  NotificationModel copyWith({
    int? id,
    int? userId,
    String? title,
    String? body,
    String? type,
    int? referenceId,
    String? referenceType,
    String? imageUrl,
    bool? isRead,
    String? createdAt,
    String? updatedAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      referenceId: referenceId ?? this.referenceId,
      referenceType: referenceType ?? this.referenceType,
      imageUrl: imageUrl ?? this.imageUrl,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

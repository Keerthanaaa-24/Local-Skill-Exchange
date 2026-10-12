class CertificateModel {
  final int id;
  final String certificateNumber;
  final String verificationCode;
  final int userId;
  final int learningPathId;
  final int skillId;
  final String title;
  final String? description;
  final DateTime issuedAt;
  final DateTime completedAt;
  final String status;
  final String recipientName;
  final String skillName;
  final String learningPathTitle;

  CertificateModel({
    required this.id,
    required this.certificateNumber,
    required this.verificationCode,
    required this.userId,
    required this.learningPathId,
    required this.skillId,
    required this.title,
    this.description,
    required this.issuedAt,
    required this.completedAt,
    required this.status,
    required this.recipientName,
    required this.skillName,
    required this.learningPathTitle,
  });

  factory CertificateModel.fromJson(Map<String, dynamic> json) {
    return CertificateModel(
      id: json['id'] as int,
      certificateNumber: json['certificate_number'] as String,
      verificationCode: json['verification_code'] as String,
      userId: json['user_id'] as int,
      learningPathId: json['learning_path_id'] as int,
      skillId: json['skill_id'] as int,
      title: json['title'] as String,
      description: json['description'] as String?,
      issuedAt: DateTime.parse(json['issued_at'] as String),
      completedAt: DateTime.parse(json['completed_at'] as String),
      status: json['status'] as String? ?? 'valid',
      recipientName: json['recipient_name'] as String? ?? 'Learner',
      skillName: json['skill_name'] as String? ?? 'Skill',
      learningPathTitle: json['learning_path_title'] as String? ?? 'Learning Path',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'certificate_number': certificateNumber,
        'verification_code': verificationCode,
        'user_id': userId,
        'learning_path_id': learningPathId,
        'skill_id': skillId,
        'title': title,
        'description': description,
        'issued_at': issuedAt.toIso8601String(),
        'completed_at': completedAt.toIso8601String(),
        'status': status,
        'recipient_name': recipientName,
        'skill_name': skillName,
        'learning_path_title': learningPathTitle,
      };
}

class CertificateVerificationModel {
  final bool valid;
  final String? certificateNumber;
  final String? title;
  final String? skill;
  final String? recipientName;
  final DateTime? issuedAt;
  final String? status;

  CertificateVerificationModel({
    required this.valid,
    this.certificateNumber,
    this.title,
    this.skill,
    this.recipientName,
    this.issuedAt,
    this.status,
  });

  factory CertificateVerificationModel.fromJson(Map<String, dynamic> json) {
    return CertificateVerificationModel(
      valid: json['valid'] as bool? ?? false,
      certificateNumber: json['certificate_number'] as String?,
      title: json['title'] as String?,
      skill: json['skill'] as String?,
      recipientName: json['recipient_name'] as String?,
      issuedAt: json['issued_at'] != null ? DateTime.parse(json['issued_at'] as String) : null,
      status: json['status'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'valid': valid,
        'certificate_number': certificateNumber,
        'title': title,
        'skill': skill,
        'recipient_name': recipientName,
        'issued_at': issuedAt?.toIso8601String(),
        'status': status,
      };
}

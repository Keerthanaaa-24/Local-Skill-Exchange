class BookingModel {
  final int id;
  final int skillId;
  final String skillTitle;
  final int mentorId;
  final String mentorName;
  final int learnerId;
  final String learnerName;
  final String bookingDate; // YYYY-MM-DD
  final String bookingTime; // HH:MM
  final int duration; // in minutes
  final int credits;
  final String bookingStatus; // pending, accepted, rejected, completed, cancelled
  final String meetingType; // online, offline
  final String? meetingLocation;
  final String? notes;
  final String? createdAt;
  final String? updatedAt;
  final bool hasReviewed;

  BookingModel({
    required this.id,
    required this.skillId,
    required this.skillTitle,
    required this.mentorId,
    required this.mentorName,
    required this.learnerId,
    required this.learnerName,
    required this.bookingDate,
    required this.bookingTime,
    required this.duration,
    required this.credits,
    required this.bookingStatus,
    required this.meetingType,
    this.meetingLocation,
    this.notes,
    this.createdAt,
    this.updatedAt,
    this.hasReviewed = false,
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    String parsedDate = json['bookingDate'] ?? json['booking_date'] ?? '';
    String parsedTime = json['bookingTime'] ?? json['booking_time'] ?? '';
    if (parsedDate.isEmpty && json['date'] != null) {
      final dateStr = json['date'].toString();
      if (dateStr.contains('T')) {
        final parts = dateStr.split('T');
        parsedDate = parts[0];
        parsedTime = parts[1].length >= 5 ? parts[1].substring(0, 5) : parts[1];
      } else if (dateStr.contains(' ')) {
        final parts = dateStr.split(' ');
        parsedDate = parts[0];
        parsedTime = parts[1].length >= 5 ? parts[1].substring(0, 5) : parts[1];
      } else {
        parsedDate = dateStr;
      }
    }

    return BookingModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      skillId: json['skillId'] ?? json['skill_id'] ?? 0,
      skillTitle: json['skillTitle'] ?? json['skill_title'] ?? 'Skill Session',
      mentorId: json['mentorId'] ?? json['mentor_id'] ?? 0,
      mentorName: json['mentorName'] ?? json['mentor_name'] ?? 'Mentor',
      learnerId: json['learnerId'] ?? json['learner_id'] ?? json['mentee_id'] ?? 0,
      learnerName: json['learnerName'] ?? json['learner_name'] ?? 'Learner',
      bookingDate: parsedDate,
      bookingTime: parsedTime,
      duration: json['duration'] ?? 60,
      credits: json['credits'] ?? json['credits_cost'] ?? 10,
      bookingStatus: json['bookingStatus'] ?? json['booking_status'] ?? json['status'] ?? 'pending',
      meetingType: json['meetingType'] ?? json['meeting_type'] ?? json['location'] ?? 'online',
      meetingLocation: json['meetingLocation'] ?? json['meeting_location'] ?? json['location'],
      notes: json['notes'],
      createdAt: json['createdAt'] ?? json['created_at']?.toString(),
      updatedAt: json['updatedAt'] ?? json['updated_at']?.toString(),
      hasReviewed: json['hasReviewed'] ?? json['has_reviewed'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'skill_id': skillId,
      'skill_title': skillTitle,
      'mentor_id': mentorId,
      'mentor_name': mentorName,
      'learner_id': learnerId,
      'learner_name': learnerName,
      'booking_date': bookingDate,
      'booking_time': bookingTime,
      'duration': duration,
      'credits': credits,
      'booking_status': bookingStatus,
      'meeting_type': meetingType,
      'meeting_location': meetingLocation,
      'notes': notes,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'has_reviewed': hasReviewed,
    };
  }

  BookingModel copyWith({
    int? id,
    int? skillId,
    String? skillTitle,
    int? mentorId,
    String? mentorName,
    int? learnerId,
    String? learnerName,
    String? bookingDate,
    String? bookingTime,
    int? duration,
    int? credits,
    String? bookingStatus,
    String? meetingType,
    String? meetingLocation,
    String? notes,
    String? createdAt,
    String? updatedAt,
    bool? hasReviewed,
  }) {
    return BookingModel(
      id: id ?? this.id,
      skillId: skillId ?? this.skillId,
      skillTitle: skillTitle ?? this.skillTitle,
      mentorId: mentorId ?? this.mentorId,
      mentorName: mentorName ?? this.mentorName,
      learnerId: learnerId ?? this.learnerId,
      learnerName: learnerName ?? this.learnerName,
      bookingDate: bookingDate ?? this.bookingDate,
      bookingTime: bookingTime ?? this.bookingTime,
      duration: duration ?? this.duration,
      credits: credits ?? this.credits,
      bookingStatus: bookingStatus ?? this.bookingStatus,
      meetingType: meetingType ?? this.meetingType,
      meetingLocation: meetingLocation ?? this.meetingLocation,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      hasReviewed: hasReviewed ?? this.hasReviewed,
    );
  }
}

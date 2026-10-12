class ChatModel {
  final int chatId;
  final int? bookingId;
  final int mentorId;
  final int learnerId;
  final String partnerName;
  final String partnerAvatar;
  final String lastMessage;
  final String lastMessageTime;
  final int unreadCount;
  final String createdAt;
  final String updatedAt;
  final bool isOnline;

  ChatModel({
    required this.chatId,
    this.bookingId,
    required this.mentorId,
    required this.learnerId,
    required this.partnerName,
    required this.partnerAvatar,
    required this.lastMessage,
    required this.lastMessageTime,
    required this.unreadCount,
    required this.createdAt,
    required this.updatedAt,
    this.isOnline = false,
  });

  factory ChatModel.fromJson(Map<String, dynamic> json) {
    return ChatModel(
      chatId: json['chat_id'] ?? 0,
      bookingId: json['booking_id'],
      mentorId: json['mentor_id'] ?? 0,
      learnerId: json['learner_id'] ?? 0,
      partnerName: json['partner_name'] ?? 'User',
      partnerAvatar: json['partner_avatar'] ?? '',
      lastMessage: json['last_message'] ?? '',
      lastMessageTime: json['last_message_time'] ?? DateTime.now().toIso8601String(),
      unreadCount: json['unread_count'] ?? 0,
      createdAt: json['created_at'] ?? DateTime.now().toIso8601String(),
      updatedAt: json['updated_at'] ?? DateTime.now().toIso8601String(),
      isOnline: json['is_online'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'chat_id': chatId,
      'booking_id': bookingId,
      'mentor_id': mentorId,
      'learner_id': learnerId,
      'partner_name': partnerName,
      'partner_avatar': partnerAvatar,
      'last_message': lastMessage,
      'last_message_time': lastMessageTime,
      'unread_count': unreadCount,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'is_online': isOnline,
    };
  }

  ChatModel copyWith({
    int? chatId,
    int? bookingId,
    int? mentorId,
    int? learnerId,
    String? partnerName,
    String? partnerAvatar,
    String? lastMessage,
    String? lastMessageTime,
    int? unreadCount,
    String? createdAt,
    String? updatedAt,
    bool? isOnline,
  }) {
    return ChatModel(
      chatId: chatId ?? this.chatId,
      bookingId: bookingId ?? this.bookingId,
      mentorId: mentorId ?? this.mentorId,
      learnerId: learnerId ?? this.learnerId,
      partnerName: partnerName ?? this.partnerName,
      partnerAvatar: partnerAvatar ?? this.partnerAvatar,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      unreadCount: unreadCount ?? this.unreadCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isOnline: isOnline ?? this.isOnline,
    );
  }
}

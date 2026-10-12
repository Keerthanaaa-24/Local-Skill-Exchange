class MessageModel {
  final int id;
  final int chatId;
  final int senderId;
  final int receiverId;
  final String message;
  final String messageType; // text, image, file, voice
  final String timestamp;
  final bool isRead;
  final String? attachmentUrl;

  MessageModel({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.receiverId,
    required this.message,
    required this.messageType,
    required this.timestamp,
    required this.isRead,
    this.attachmentUrl,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'] ?? 0,
      chatId: json['chat_id'] ?? 0,
      senderId: json['sender_id'] ?? 0,
      receiverId: json['receiver_id'] ?? 0,
      message: json['message'] ?? json['content'] ?? '',
      messageType: json['message_type'] ?? 'text',
      timestamp: json['timestamp'] ?? DateTime.now().toIso8601String(),
      isRead: json['is_read'] ?? false,
      attachmentUrl: json['attachment_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'chat_id': chatId,
      'sender_id': senderId,
      'receiver_id': receiverId,
      'message': message,
      'message_type': messageType,
      'timestamp': timestamp,
      'is_read': isRead,
      'attachment_url': attachmentUrl,
    };
  }

  MessageModel copyWith({
    int? id,
    int? chatId,
    int? senderId,
    int? receiverId,
    String? message,
    String? messageType,
    String? timestamp,
    bool? isRead,
    String? attachmentUrl,
  }) {
    return MessageModel(
      id: id ?? this.id,
      chatId: chatId ?? this.chatId,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      message: message ?? this.message,
      messageType: messageType ?? this.messageType,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      attachmentUrl: attachmentUrl ?? this.attachmentUrl,
    );
  }
}

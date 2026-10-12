import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/chat_model.dart';
import '../models/message_model.dart';
import '../services/api_client.dart';
import '../services/websocket_manager.dart';

class ChatRepository {
  final ApiClient _apiClient;
  final WebSocketManager _wsManager;

  ChatRepository(this._apiClient, this._wsManager);

  Stream<Map<String, dynamic>> get wsStream => _wsManager.messageStream;

  Future<void> connectSocket() async {
    await _wsManager.connect();
  }

  void disconnectSocket() {
    _wsManager.disconnect();
  }

  Future<List<ChatModel>> getChats() async {
    try {
      final response = await _apiClient.dio.get('/chats');
      final data = response.data as List;
      return data.map((e) => ChatModel.fromJson(e)).toList();
    } catch (e) {
      throw Exception('Failed to fetch chats: $e');
    }
  }

  Future<ChatModel> getChatById(int chatId) async {
    try {
      final response = await _apiClient.dio.get('/chats/$chatId');
      return ChatModel.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to fetch chat by id: $e');
    }
  }

  Future<List<MessageModel>> getMessages(int chatId) async {
    try {
      final response = await _apiClient.dio.get('/chats/$chatId/messages');
      final data = response.data as List;
      return data.map((e) => MessageModel.fromJson(e)).toList();
    } catch (e) {
      throw Exception('Failed to fetch messages: $e');
    }
  }

  Future<void> deleteMessage(int messageId) async {
    try {
      await _apiClient.dio.delete('/messages/$messageId');
    } catch (e) {
      throw Exception('Failed to delete message: $e');
    }
  }

  void sendMessage({
    required int chatId,
    required int senderId,
    required int receiverId,
    required String message,
    String messageType = 'text',
  }) {
    _wsManager.send({
      'type': 'message',
      'chat_id': chatId,
      'sender_id': senderId,
      'receiver_id': receiverId,
      'message': message,
      'message_type': messageType,
      'timestamp': DateTime.now().toUtc().toIso8601String(),
    });
  }

  void sendTypingState({
    required int chatId,
    required int senderId,
    required bool isTyping,
  }) {
    _wsManager.send({
      'type': 'typing',
      'chat_id': chatId,
      'sender_id': senderId,
      'is_typing': isTyping,
    });
  }

  void markAsRead({
    required int chatId,
    required int messageId,
    required int readerId,
  }) {
    _wsManager.send({
      'type': 'read',
      'chat_id': chatId,
      'message_id': messageId,
      'reader_id': readerId,
    });
  }
}

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepository(apiClient, webSocketManager);
});

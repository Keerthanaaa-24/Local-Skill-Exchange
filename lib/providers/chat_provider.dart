import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/chat_model.dart';
import '../models/message_model.dart';
import '../repositories/chat_repository.dart';

// Provides global unread count
final globalUnreadCountProvider = Provider<int>((ref) {
  final chats = ref.watch(chatListNotifierProvider);
  return chats.maybeWhen(
    data: (list) => list.fold(0, (sum, chat) => sum + chat.unreadCount),
    orElse: () => 0,
  );
});

// Provides typing state for specific chat
final typingStateProvider = StateProvider.family<bool, int>((ref, chatId) => false);

final chatDetailProvider = FutureProvider.autoDispose.family<ChatModel, int>((ref, chatId) async {
  return await ref.read(chatRepositoryProvider).getChatById(chatId);
});

class ChatListNotifier extends AsyncNotifier<List<ChatModel>> {
  StreamSubscription? _wsSubscription;

  @override
  Future<List<ChatModel>> build() async {
    final repo = ref.read(chatRepositoryProvider);
    
    // Connect WS
    await repo.connectSocket();
    
    // Listen to WS stream for chat list updates (new message -> bump chat to top & update last message)
    _wsSubscription = repo.wsStream.listen((data) {
      if (data['type'] == 'message') {
        _handleNewMessage(data);
      } else if (data['type'] == 'read') {
        _handleReadReceipt(data);
      }
    });

    ref.onDispose(() {
      _wsSubscription?.cancel();
    });

    return _fetchChats();
  }

  Future<List<ChatModel>> _fetchChats() async {
    return await ref.read(chatRepositoryProvider).getChats();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchChats());
  }

  void _handleNewMessage(Map<String, dynamic> data) {
    if (!state.hasValue) return;
    
    final chatId = data['chat_id'] as int;
    final message = data['message'] as String;
    final timestamp = data['timestamp'] as String;
    
    final currentChats = state.value!;
    final index = currentChats.indexWhere((c) => c.chatId == chatId);
    
    if (index != -1) {
      final chat = currentChats[index];
      final updatedChat = chat.copyWith(
        lastMessage: message,
        lastMessageTime: timestamp,
        unreadCount: chat.unreadCount + 1, // Will be zeroed if actively reading, but we handle that in chat UI
      );
      
      final newList = List<ChatModel>.from(currentChats)..removeAt(index)..insert(0, updatedChat);
      state = AsyncValue.data(newList);
    } else {
      // If chat is entirely new, trigger a full refresh to get partner details
      refresh();
    }
  }

  void _handleReadReceipt(Map<String, dynamic> data) {
    if (!state.hasValue) return;
    final chatId = data['chat_id'] as int;
    
    final currentChats = state.value!;
    final index = currentChats.indexWhere((c) => c.chatId == chatId);
    
    if (index != -1) {
      final updatedChat = currentChats[index].copyWith(unreadCount: 0);
      final newList = List<ChatModel>.from(currentChats)..[index] = updatedChat;
      state = AsyncValue.data(newList);
    }
  }
}

final chatListNotifierProvider = AsyncNotifierProvider<ChatListNotifier, List<ChatModel>>(() {
  return ChatListNotifier();
});


class ChatMessagesNotifier extends AutoDisposeFamilyAsyncNotifier<List<MessageModel>, int> {
  StreamSubscription? _wsSubscription;

  @override
  Future<List<MessageModel>> build(int arg) async {
    final repo = ref.read(chatRepositoryProvider);
    
    _wsSubscription = repo.wsStream.listen((data) {
      if (data['chat_id'] != arg) return;
      
      if (data['type'] == 'message') {
        _handleIncomingMessage(data);
      } else if (data['type'] == 'typing') {
        ref.read(typingStateProvider(arg).notifier).state = data['is_typing'] as bool;
      } else if (data['type'] == 'read') {
        _handleReadReceipt(data);
      }
    });

    ref.onDispose(() {
      _wsSubscription?.cancel();
      // Reset typing state
      ref.read(typingStateProvider(arg).notifier).state = false;
    });

    return await repo.getMessages(arg);
  }

  void _handleIncomingMessage(Map<String, dynamic> data) {
    if (!state.hasValue) return;
    
    final newMessage = MessageModel.fromJson(data);
    state = AsyncValue.data([...state.value!, newMessage]);
  }

  void _handleReadReceipt(Map<String, dynamic> data) {
    if (!state.hasValue) return;
    
    final readerId = data['reader_id'];
    // Update all messages to isRead = true if they were sent to the reader
    final updatedList = state.value!.map((msg) {
      if (msg.receiverId == readerId && !msg.isRead) {
        return msg.copyWith(isRead: true);
      }
      return msg;
    }).toList();
    
    state = AsyncValue.data(updatedList);
  }

  void sendMessage(int senderId, int receiverId, String content) {
    if (content.trim().isEmpty) return;
    
    ref.read(chatRepositoryProvider).sendMessage(
      chatId: arg,
      senderId: senderId,
      receiverId: receiverId,
      message: content,
    );
  }

  void sendTypingState(int senderId, bool isTyping) {
    ref.read(chatRepositoryProvider).sendTypingState(
      chatId: arg,
      senderId: senderId,
      isTyping: isTyping,
    );
  }

  void markAsRead(int readerId, int messageId) {
    ref.read(chatRepositoryProvider).markAsRead(
      chatId: arg,
      messageId: messageId,
      readerId: readerId,
    );
    
    // Also update chatList immediately
    final chatListNotifier = ref.read(chatListNotifierProvider.notifier);
    // Force a read receipt event locally
    chatListNotifier._handleReadReceipt({'chat_id': arg});
  }
}

final chatMessagesNotifierProvider = AsyncNotifierProvider.autoDispose.family<ChatMessagesNotifier, List<MessageModel>, int>(() {
  return ChatMessagesNotifier();
});

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/chat_model.dart';
import '../providers/chat_provider.dart';
import '../providers/user_provider.dart';
import '../core/widgets/custom_avatar.dart';

class ConversationScreen extends ConsumerStatefulWidget {
  final int chatId;
  final ChatModel? chat;

  const ConversationScreen({super.key, required this.chatId, this.chat});

  @override
  ConsumerState<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends ConsumerState<ConversationScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    // Mark as read immediately
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentUser = ref.read(userProvider);
      if (currentUser != null) {
        // Technically we should pass the last unread message ID, but sending 0 implies read all for this UI demo,
        // or we can fetch the messages and grab the ID. The Provider will handle it.
        ref.read(chatMessagesNotifierProvider(widget.chatId).notifier).markAsRead(int.parse(currentUser.id), 0);
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    
    final currentUser = ref.read(userProvider);
    if (currentUser == null) return;
    
    final chatData = widget.chat ?? ref.read(chatDetailProvider(widget.chatId)).value;
    if (chatData == null) return;
    
    // Determine the partner ID (who we are sending to). 
    final currentUserId = int.parse(currentUser.id);
    final receiverId = chatData.mentorId == currentUserId ? chatData.learnerId : chatData.mentorId;
    
    ref.read(chatMessagesNotifierProvider(widget.chatId).notifier)
       .sendMessage(currentUserId, receiverId, text);
    
    _messageController.clear();
    
    if (_isTyping) {
      _isTyping = false;
      ref.read(chatMessagesNotifierProvider(widget.chatId).notifier).sendTypingState(currentUserId, false);
    }
    
    _scrollToBottom();
  }

  void _onTextChanged(String text) {
    final currentUser = ref.read(userProvider);
    if (currentUser == null) return;

    final isTypingNow = text.isNotEmpty;
    if (_isTyping != isTypingNow) {
      _isTyping = isTypingNow;
      ref.read(chatMessagesNotifierProvider(widget.chatId).notifier).sendTypingState(int.parse(currentUser.id), _isTyping);
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 100,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(chatMessagesNotifierProvider(widget.chatId));
    final currentUser = ref.watch(userProvider);
    final partnerTyping = ref.watch(typingStateProvider(widget.chatId));

    // Auto-scroll on new messages
    ref.listen(chatMessagesNotifierProvider(widget.chatId), (prev, next) {
      if (next.hasValue && prev?.value?.length != next.value?.length) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToBottom();
          // Also mark as read since we are in the screen
          if (currentUser != null && next.value!.isNotEmpty) {
            final lastMsg = next.value!.last;
            if (lastMsg.receiverId == int.parse(currentUser.id) && !lastMsg.isRead) {
              ref.read(chatMessagesNotifierProvider(widget.chatId).notifier).markAsRead(int.parse(currentUser.id), lastMsg.id);
            }
          }
        });
      }
    });

    AsyncValue<ChatModel>? chatDetailAsync;
    ChatModel? currentChat = widget.chat;
    if (currentChat == null) {
      chatDetailAsync = ref.watch(chatDetailProvider(widget.chatId));
      currentChat = chatDetailAsync?.value;
    }

    return Scaffold(
      appBar: AppBar(
        title: currentChat == null
            ? const Text('Loading...')
            : Row(
          children: [
            Stack(
              children: [
                CustomAvatar(
                  radius: 18,
                  imageUrl: currentChat.partnerAvatar,
                  name: currentChat.partnerName,
                ),
                if (currentChat.isOnline)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        border: Border.all(color: Theme.of(context).cardColor, width: 1.5),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(currentChat.partnerName, style: const TextStyle(fontSize: 16)),
                if (partnerTyping)
                  Text('Typing...', style: TextStyle(fontSize: 12, color: Theme.of(context).primaryColor))
                else if (currentChat.isOnline)
                  const Text('Online', style: TextStyle(fontSize: 12, color: Colors.green))
                else
                  const Text('Offline', style: TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: messagesAsync.when(
                data: (messages) {
                  if (messages.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.waving_hand_rounded, size: 64, color: Colors.amber.withValues(alpha: 0.5)),
                          const SizedBox(height: 16),
                          const Text('Say hi to start the conversation!'),
                        ],
                      ),
                    );
                  }
                  
                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      final isMe = message.senderId == (currentUser != null ? int.parse(currentUser.id) : -1);
                      
                      DateTime time;
                      try {
                        time = DateTime.parse(message.timestamp);
                      } catch (_) {
                        time = DateTime.now();
                      }
                      final timeStr = DateFormat('h:mm a').format(time);
                      
                      return Align(
                        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: isMe ? Theme.of(context).primaryColor : Theme.of(context).cardTheme.color,
                            borderRadius: BorderRadius.circular(16).copyWith(
                              bottomRight: isMe ? const Radius.circular(0) : const Radius.circular(16),
                              bottomLeft: !isMe ? const Radius.circular(0) : const Radius.circular(16),
                            ),
                            boxShadow: [
                              if (!isMe)
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.02),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                )
                            ]
                          ),
                          child: Column(
                            crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                            children: [
                              Text(
                                message.message,
                                style: TextStyle(
                                  color: isMe ? Colors.white : Theme.of(context).textTheme.bodyLarge?.color,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    timeStr,
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: isMe ? Colors.white.withValues(alpha: 0.7) : Colors.grey,
                                    ),
                                  ),
                                  if (isMe) ...[
                                    const SizedBox(width: 4),
                                    Icon(
                                      message.isRead ? Icons.done_all_rounded : Icons.check_rounded,
                                      size: 12,
                                      color: message.isRead ? Colors.blue[200] : Colors.white.withValues(alpha: 0.7),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, st) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Colors.red),
                      const SizedBox(height: 16),
                      const Text('Failed to load messages'),
                      TextButton(
                        onPressed: () => ref.refresh(chatMessagesNotifierProvider(widget.chatId)),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  )
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      onChanged: _onTextChanged,
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Theme.of(context).cardTheme.color,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  InkWell(
                    onTap: _sendMessage,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

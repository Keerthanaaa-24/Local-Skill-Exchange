import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../core/constants/app_constants.dart';
import '../core/widgets/custom_avatar.dart';
import '../models/chat_model.dart';
import '../widgets/section_header.dart';
import '../providers/chat_provider.dart';
import '../routes/app_routes.dart';
import 'conversation_screen.dart';

class ChatScreen extends ConsumerWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatsAsync = ref.watch(chatListNotifierProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            SectionHeader(
              title: 'Messages',
              actionTitle: 'New Chat',
              onActionPressed: () => Navigator.pushNamed(context, AppRoutes.explore),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  await ref.read(chatListNotifierProvider.notifier).refresh();
                },
                child: chatsAsync.when(
                  data: (chats) {
                    if (chats.isEmpty) {
                      return Center(
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingXL, vertical: AppConstants.paddingL),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.forum_outlined,
                                  size: 56,
                                  color: Theme.of(context).primaryColor,
                                ),
                              ),
                              const SizedBox(height: 20),
                              Text(
                                'No conversations yet',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Connect with local mentors or peer learners across the community to start exchanging skills.',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.grey.shade600,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 24),
                              Wrap(
                                spacing: 12,
                                runSpacing: 12,
                                alignment: WrapAlignment.center,
                                children: [
                                  FilledButton.icon(
                                    onPressed: () => Navigator.pushNamed(context, AppRoutes.explore),
                                    icon: const Icon(Icons.person_search_rounded, size: 18),
                                    label: const Text('Find a Mentor'),
                                    style: FilledButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                    ),
                                  ),
                                  OutlinedButton.icon(
                                    onPressed: () => Navigator.pushNamed(context, AppRoutes.searchFilter),
                                    icon: const Icon(Icons.search_rounded, size: 18),
                                    label: const Text('Explore Skills'),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.only(bottom: 100), // bottom nav padding
                      itemCount: chats.length,
                      itemBuilder: (context, index) {
                        final chat = chats[index];
                        return _buildChatTile(context, chat, index, ref);
                      },
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, st) => Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.wifi_off_rounded, size: 48, color: Colors.red),
                        const SizedBox(height: 16),
                        const Text('Failed to load chats'),
                        TextButton(
                          onPressed: () => ref.read(chatListNotifierProvider.notifier).refresh(),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatTile(BuildContext context, ChatModel chat, int index, WidgetRef ref) {
    DateTime parsedDate;
    try {
      parsedDate = DateTime.parse(chat.lastMessageTime);
    } catch (_) {
      parsedDate = DateTime.now();
    }
    
    // Format date properly depending on how old it is
    String timeString;
    final now = DateTime.now();
    if (parsedDate.year == now.year && parsedDate.month == now.month && parsedDate.day == now.day) {
      timeString = DateFormat('h:mm a').format(parsedDate);
    } else if (now.difference(parsedDate).inDays < 7) {
      timeString = DateFormat('EEEE').format(parsedDate);
    } else {
      timeString = DateFormat('MMM dd').format(parsedDate);
    }
    
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ConversationScreen(chatId: chat.chatId, chat: chat)),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingM, vertical: AppConstants.paddingM),
        child: Row(
          children: [
            Stack(
              children: [
                CustomAvatar(
                  radius: 28,
                  imageUrl: chat.partnerAvatar,
                  name: chat.partnerName,
                ),
                if (chat.isOnline)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        border: Border.all(color: Theme.of(context).scaffoldBackgroundColor, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: AppConstants.paddingM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(chat.partnerName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text(
                        timeString,
                        style: TextStyle(
                          color: chat.unreadCount > 0 ? Theme.of(context).primaryColor : Colors.grey,
                          fontWeight: chat.unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          chat.lastMessage.isEmpty ? 'Say Hi!' : chat.lastMessage,
                          style: TextStyle(
                            color: chat.unreadCount > 0 ? Theme.of(context).textTheme.bodyLarge?.color : Colors.grey,
                            fontWeight: chat.unreadCount > 0 ? FontWeight.w600 : FontWeight.normal,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (chat.unreadCount > 0)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            chat.unreadCount.toString(),
                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ).animate().fade(delay: (index * 100).ms).slideX(),
    );
  }
}

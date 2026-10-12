import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_constants.dart';
import '../../models/notification_model.dart';
import '../../providers/notification_provider.dart';
import '../../routes/app_routes.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  String _selectedTab = 'All';
  final List<String> _tabs = ['All', 'Unread', 'Sessions', 'Learning', 'Credits', 'Community'];

  String _formatRelativeTime(String isoString) {
    try {
      final dateTime = DateTime.parse(isoString).toLocal();
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inSeconds < 60) {
        return 'Just now';
      } else if (difference.inMinutes < 60) {
        final mins = difference.inMinutes;
        return '$mins min${mins > 1 ? 's' : ''} ago';
      } else if (difference.inHours < 24) {
        final hours = difference.inHours;
        return '$hours hour${hours > 1 ? 's' : ''} ago';
      } else if (difference.inDays == 1 || (now.day - dateTime.day == 1 && now.month == dateTime.month && now.year == dateTime.year)) {
        return 'Yesterday';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} days ago';
      } else {
        return DateFormat('MMM d').format(dateTime);
      }
    } catch (_) {
      return '';
    }
  }

  IconData _getIconForType(String type) {
    final t = type.toLowerCase();
    if (t.contains('booking') || t.contains('session')) {
      return Icons.calendar_today_rounded;
    } else if (t.contains('chat') || t.contains('message')) {
      return Icons.chat_bubble_outline_rounded;
    } else if (t.contains('quiz') || t.contains('course') || t.contains('learning')) {
      return Icons.school_rounded;
    } else if (t.contains('cert')) {
      return Icons.verified_outlined;
    } else if (t.contains('credit') || t.contains('wallet')) {
      return Icons.stars_rounded;
    } else if (t.contains('review') || t.contains('community') || t.contains('achievement')) {
      return Icons.emoji_events_outlined;
    }
    return Icons.notifications_none_rounded;
  }

  Color _getColorForType(BuildContext context, String type) {
    final theme = Theme.of(context);
    final t = type.toLowerCase();
    if (t.contains('booking') || t.contains('session')) {
      return Colors.blue;
    } else if (t.contains('chat') || t.contains('message')) {
      return Colors.teal;
    } else if (t.contains('quiz') || t.contains('course') || t.contains('learning')) {
      return Colors.deepPurple;
    } else if (t.contains('cert')) {
      return Colors.amber.shade800;
    } else if (t.contains('credit') || t.contains('wallet')) {
      return Colors.green;
    } else if (t.contains('review') || t.contains('community') || t.contains('achievement')) {
      return Colors.orange;
    }
    return theme.colorScheme.primary;
  }

  void _handleNotificationTap(NotificationModel notification) async {
    // 1. Mark as read immediately
    if (!notification.isRead) {
      ref.read(notificationNotifierProvider.notifier).markAsRead(notification.id);
    }

    // 2. Navigate appropriately based on event type
    final type = notification.type.toLowerCase();
    if (type.contains('session') || type.contains('booking')) {
      Navigator.of(context).pushNamed(AppRoutes.home);
    } else if (type.contains('chat') || type.contains('message')) {
      Navigator.of(context).pushNamed(AppRoutes.home);
    } else if (type.contains('quiz') || type.contains('learning') || type.contains('course')) {
      Navigator.of(context).pushNamed(AppRoutes.learningHub);
    } else if (type.contains('cert')) {
      Navigator.of(context).pushNamed(AppRoutes.certificates);
    } else if (type.contains('credit') || type.contains('wallet')) {
      Navigator.of(context).pushNamed(AppRoutes.wallet);
    } else if (type.contains('achievement') || type.contains('passport')) {
      Navigator.of(context).pushNamed(AppRoutes.passport);
    } else {
      Navigator.of(context).pushNamed(AppRoutes.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final notificationsAsync = ref.watch(notificationNotifierProvider);
    final unreadCount = ref.watch(unreadNotificationCountProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Notifications', style: TextStyle(fontWeight: FontWeight.bold)),
            if (unreadCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$unreadCount New',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        elevation: 0,
        actions: [
          if (unreadCount > 0)
            TextButton.icon(
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                await ref.read(notificationNotifierProvider.notifier).markAllAsRead();
                if (mounted) {
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('All notifications marked as read'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.done_all_rounded, size: 18),
              label: const Text('Mark all read'),
            ),
        ],
      ),
      body: Column(
        children: [
          // Filter Tabs
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingM, vertical: AppConstants.paddingS),
            child: Row(
              children: _tabs.map((tab) {
                final isSelected = _selectedTab == tab;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(tab),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedTab = tab;
                      });
                    },
                    selectedColor: theme.colorScheme.primary.withValues(alpha: 0.15),
                    checkmarkColor: theme.colorScheme.primary,
                    labelStyle: TextStyle(
                      color: isSelected ? theme.colorScheme.primary : (isDark ? Colors.white70 : Colors.black87),
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 13,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: isSelected ? theme.colorScheme.primary : Colors.grey.withValues(alpha: 0.2),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const Divider(height: 1),

          // Notification List
          Expanded(
            child: notificationsAsync.when(
              data: (notifications) {
                final filtered = notifications.where((n) {
                  final t = n.type.toLowerCase();
                  if (_selectedTab == 'All') return true;
                  if (_selectedTab == 'Unread') return !n.isRead;
                  if (_selectedTab == 'Sessions') return t.contains('session') || t.contains('booking');
                  if (_selectedTab == 'Learning') return t.contains('learning') || t.contains('quiz') || t.contains('course') || t.contains('cert');
                  if (_selectedTab == 'Credits') return t.contains('credit') || t.contains('wallet');
                  if (_selectedTab == 'Community') return t.contains('community') || t.contains('chat') || t.contains('review') || t.contains('achievement');
                  return true;
                }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppConstants.paddingXL),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.notifications_none_rounded, size: 56, color: Colors.grey.shade400),
                          const SizedBox(height: 16),
                          Text(
                            _selectedTab == 'All' ? 'No notifications yet' : 'No ${_selectedTab.toLowerCase()} notifications',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _selectedTab == 'All'
                                ? 'Your learning, sessions, messages and achievements will appear here.'
                                : 'Check back later for updates.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => ref.read(notificationNotifierProvider.notifier).refresh(),
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingM, vertical: AppConstants.paddingS),
                    itemCount: filtered.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final item = filtered[index];
                      return _buildNotificationCard(context, item);
                    },
                  ),
                );
              },
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(AppConstants.paddingXL),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (error, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppConstants.paddingXL),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline_rounded, size: 48, color: Colors.red.shade400),
                      const SizedBox(height: 16),
                      Text(
                        "Couldn't load notifications",
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Please check your connection and try again.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () => ref.read(notificationNotifierProvider.notifier).refresh(),
                        icon: const Icon(Icons.refresh_rounded, size: 18),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(BuildContext context, NotificationModel item) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final color = _getColorForType(context, item.type);
    final icon = _getIconForType(item.type);

    return Dismissible(
      key: ValueKey('notification_${item.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusM),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: const [
            Text('Delete', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            SizedBox(width: 8),
            Icon(Icons.delete_outline_rounded, color: Colors.white),
          ],
        ),
      ),
      onDismissed: (_) {
        ref.read(notificationNotifierProvider.notifier).deleteNotification(item.id);
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Notification deleted'),
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Undo',
              onPressed: () {
                ref.read(notificationNotifierProvider.notifier).refresh();
              },
            ),
          ),
        );
      },
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _handleNotificationTap(item),
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusM),
          child: Container(
            padding: const EdgeInsets.all(AppConstants.paddingM),
            decoration: BoxDecoration(
              color: !item.isRead
                  ? (isDark ? theme.colorScheme.primary.withValues(alpha: 0.12) : theme.colorScheme.primary.withValues(alpha: 0.04))
                  : (isDark ? theme.cardTheme.color ?? theme.cardColor : Colors.white),
              borderRadius: BorderRadius.circular(AppConstants.borderRadiusM),
              border: Border.all(
                color: !item.isRead
                    ? theme.colorScheme.primary.withValues(alpha: 0.3)
                    : Colors.grey.withValues(alpha: 0.15),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon Avatar
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(width: 12),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              item.title,
                              style: TextStyle(
                                fontWeight: !item.isRead ? FontWeight.bold : FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _formatRelativeTime(item.createdAt),
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade500,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.body,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),

                // Unread dot indicator
                if (!item.isRead) ...[
                  const SizedBox(width: 8),
                  Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.only(top: 6),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

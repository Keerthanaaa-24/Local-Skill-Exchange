import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../constants/app_constants.dart';

enum EmptyStateType {
  noNotifications,
  noBookings,
  noMessages,
  noSkills,
  noSearchResults,
  generic,
}

class EmptyStateWidget extends StatelessWidget {
  final EmptyStateType type;
  final String? title;
  final String? subtitle;
  final IconData? icon;
  final String? actionText;
  final VoidCallback? onActionPressed;

  const EmptyStateWidget({
    super.key,
    required this.type,
    this.title,
    this.subtitle,
    this.icon,
    this.actionText,
    this.onActionPressed,
  });

  @override
  Widget build(BuildContext context) {
    String defaultTitle;
    String defaultSubtitle;
    IconData defaultIcon;

    switch (type) {
      case EmptyStateType.noNotifications:
        defaultTitle = 'No Notifications';
        defaultSubtitle = 'You\'re all caught up! Check back later for updates.';
        defaultIcon = Icons.notifications_off_outlined;
        break;
      case EmptyStateType.noBookings:
        defaultTitle = 'No Bookings Found';
        defaultSubtitle = 'You don\'t have any sessions scheduled right now.';
        defaultIcon = Icons.calendar_today_outlined;
        break;
      case EmptyStateType.noMessages:
        defaultTitle = 'No Messages Yet';
        defaultSubtitle = 'Start a conversation with a mentor to see it here.';
        defaultIcon = Icons.chat_bubble_outline_rounded;
        break;
      case EmptyStateType.noSkills:
        defaultTitle = 'No Skills Added';
        defaultSubtitle = 'Add some skills to your profile to get started.';
        defaultIcon = Icons.psychology_outlined;
        break;
      case EmptyStateType.noSearchResults:
        defaultTitle = 'No Results Found';
        defaultSubtitle = 'Try adjusting your filters or searching for something else.';
        defaultIcon = Icons.search_off_rounded;
        break;
      case EmptyStateType.generic:
        defaultTitle = 'Nothing to See Here';
        defaultSubtitle = 'There is no data available to display right now.';
        defaultIcon = Icons.inbox_outlined;
        break;
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppConstants.paddingL),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon ?? defaultIcon,
                size: 64,
                color: Theme.of(context).primaryColor,
              ),
            ).animate().fade().scale(),
            const SizedBox(height: AppConstants.paddingL),
            Text(
              title ?? defaultTitle,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ).animate().fade().slideY(begin: 0.2, delay: 100.ms),
            const SizedBox(height: AppConstants.paddingS),
            Text(
              subtitle ?? defaultSubtitle,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey,
                  ),
              textAlign: TextAlign.center,
            ).animate().fade().slideY(begin: 0.2, delay: 200.ms),
            if (actionText != null && onActionPressed != null) ...[
              const SizedBox(height: AppConstants.paddingXL),
              ElevatedButton(
                onPressed: onActionPressed,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppConstants.radiusL),
                  ),
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                ),
                child: Text(
                  actionText!,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ).animate().fade().slideY(begin: 0.2, delay: 300.ms),
            ],
          ],
        ),
      ),
    );
  }
}

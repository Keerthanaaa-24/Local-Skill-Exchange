import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_constants.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/custom_avatar.dart';
import '../../models/booking_model.dart';
import '../../models/chat_model.dart';
import '../../providers/booking_provider.dart';
import 'review_screen.dart';
import '../conversation_screen.dart';

class SessionDetailsScreen extends ConsumerWidget {
  final BookingModel booking;

  const SessionDetailsScreen({
    super.key,
    required this.booking,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isUpcoming = booking.bookingStatus == 'pending' || booking.bookingStatus == 'accepted';
    final isPast = booking.bookingStatus == 'completed';
    final isCanceled = booking.bookingStatus == 'cancelled' || booking.bookingStatus == 'rejected';

    return Scaffold(
      appBar: AppBar(title: const Text('Session Details')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.paddingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildStatusBadge(context, isUpcoming, isPast, isCanceled),
            const SizedBox(height: AppConstants.paddingXL),
            _buildMentorInfo(context),
            const SizedBox(height: AppConstants.paddingXL),
            _buildSkillInfo(context),
            const SizedBox(height: AppConstants.paddingXL),
            _buildTimeInfo(context),
            const SizedBox(height: AppConstants.paddingXL),
            
            if (booking.bookingStatus == 'pending') ...[
              CustomButton(
                text: 'Accept Booking',
                icon: Icons.check_circle_rounded,
                onPressed: () {
                  ref.read(bookingNotifierProvider.notifier).updateBookingStatus(booking.id, 'accepted');
                  Navigator.pop(context);
                },
              ).animate().fade().slideY(begin: 0.1),
              const SizedBox(height: AppConstants.paddingM),
              CustomButton(
                text: 'Reject Booking',
                type: ButtonType.outlined,
                onPressed: () {
                  ref.read(bookingNotifierProvider.notifier).updateBookingStatus(booking.id, 'rejected');
                  Navigator.pop(context);
                },
              ).animate().fade().slideY(begin: 0.1, delay: 100.ms),
            ] else if (booking.bookingStatus == 'accepted') ...[
              CustomButton(
                text: 'Join Video Session',
                icon: Icons.videocam_rounded,
                onPressed: () {},
              ).animate().fade().slideY(begin: 0.1),
              const SizedBox(height: AppConstants.paddingM),
              CustomButton(
                text: 'Mark as Completed',
                icon: Icons.done_all_rounded,
                type: ButtonType.secondary,
                onPressed: () {
                  ref.read(bookingNotifierProvider.notifier).updateBookingStatus(booking.id, 'completed');
                  Navigator.pop(context);
                },
              ).animate().fade().slideY(begin: 0.1, delay: 100.ms),
              const SizedBox(height: AppConstants.paddingM),
              CustomButton(
                text: 'Cancel Session',
                type: ButtonType.outlined,
                onPressed: () {
                  ref.read(bookingNotifierProvider.notifier).updateBookingStatus(booking.id, 'cancelled');
                  Navigator.pop(context);
                },
              ).animate().fade().slideY(begin: 0.1, delay: 200.ms),
            ] else if (isPast) ...[
              if (booking.hasReviewed)
                Container(
                  padding: const EdgeInsets.all(AppConstants.paddingM),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle_rounded, color: Colors.green),
                      SizedBox(width: 8),
                      Text('You have already reviewed this session.', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ).animate().fade().slideY(begin: 0.1)
              else
                CustomButton(
                  text: 'Leave a Review',
                  icon: Icons.star_rate_rounded,
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ReviewScreen(
                          bookingId: booking.id,
                          reviewedUserId: booking.mentorId,
                          mentorName: booking.mentorName,
                          skillName: booking.skillTitle,
                        ),
                      ),
                    );

                    // If review was successful, the local list might need to refresh
                    // However, we rely on Riverpod state. The user might want to pop
                    // or re-fetch booking.
                    if (result == true) {
                      // refresh bookings locally if needed, handled by provider typically
                      ref.read(bookingNotifierProvider.notifier).refresh();
                    }
                  },
                ).animate().fade().slideY(begin: 0.1),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context, bool isUpcoming, bool isPast, bool isCanceled) {
    Color statusColor;
    IconData statusIcon;
    String statusText = booking.bookingStatus.toUpperCase();

    if (isUpcoming) {
      statusColor = Theme.of(context).primaryColor;
      statusIcon = Icons.schedule_rounded;
    } else if (isPast) {
      statusColor = Colors.green;
      statusIcon = Icons.check_circle_rounded;
    } else {
      statusColor = Colors.red;
      statusIcon = Icons.cancel_rounded;
    }

    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: statusColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: statusColor.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(statusIcon, size: 16, color: statusColor),
            const SizedBox(width: 8),
            Text(
              statusText,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: statusColor,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      ).animate().fade().scale(),
    );
  }

  Widget _buildMentorInfo(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingL),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        children: [
          CustomAvatar(
            radius: 32,
            imageUrl: null, // the booking model doesn't seem to have a mentorProfileImage readily available, or we just pass null to use the initials
            name: booking.mentorName,
          ),
          const SizedBox(width: AppConstants.paddingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Mentor', style: TextStyle(color: Colors.grey, fontSize: 12)),
                Text(booking.mentorName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.chat_bubble_rounded, color: Theme.of(context).primaryColor),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ConversationScreen(
                    chatId: booking.id,
                    chat: ChatModel(
                      chatId: booking.id, 
                      mentorId: booking.mentorId,
                      learnerId: booking.learnerId,
                      partnerName: booking.mentorName,
                      partnerAvatar: 'https://i.pravatar.cc/150?u=${booking.mentorName}',
                      lastMessage: '',
                      lastMessageTime: DateTime.now().toIso8601String(),
                      unreadCount: 0,
                      createdAt: DateTime.now().toIso8601String(),
                      updatedAt: DateTime.now().toIso8601String(),
                    ),
                  ),
                ),
              );
            },
            style: IconButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
            ),
          )
        ],
      ),
    ).animate().fade().slideY(begin: 0.1);
  }

  Widget _buildSkillInfo(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Skill Information', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: AppConstants.paddingM),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppConstants.paddingM),
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(booking.skillTitle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              if (booking.notes != null && booking.notes!.isNotEmpty) ...[
                Text('Notes: ${booking.notes}', style: const TextStyle(color: Colors.grey, height: 1.5)),
                const SizedBox(height: AppConstants.paddingM),
              ],
              Row(
                children: [
                  const Icon(Icons.stars_rounded, color: Colors.amber, size: 20),
                  const SizedBox(width: 8),
                  Text('${booking.credits} Credits / hour', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color)),
                ],
              ),
            ],
          ),
        ),
      ],
    ).animate().fade().slideY(begin: 0.1, delay: 100.ms);
  }

  Widget _buildTimeInfo(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    DateTime parsedDate;
    try {
      parsedDate = DateTime.parse(booking.bookingDate);
    } catch (_) {
      parsedDate = DateTime.now();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Date & Time', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: AppConstants.paddingM),
        Container(
          padding: const EdgeInsets.all(AppConstants.paddingM),
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.calendar_month_rounded, color: Theme.of(context).primaryColor),
              ),
              const SizedBox(width: AppConstants.paddingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(dateFormat.format(parsedDate), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text('${booking.bookingTime} (${booking.duration} mins)', style: const TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    ).animate().fade().slideY(begin: 0.1, delay: 200.ms);
  }
}

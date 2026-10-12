import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../core/constants.dart';
import '../models/booking_model.dart';
import '../widgets/section_header.dart';
import '../providers/booking_provider.dart';
import '../routes/app_routes.dart';
import 'features/session_details_screen.dart';

class BookingsScreen extends ConsumerStatefulWidget {
  const BookingsScreen({super.key});

  @override
  ConsumerState<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends ConsumerState<BookingsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bookingsAsync = ref.watch(bookingNotifierProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const SectionHeader(title: 'My Sessions'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingM),
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).cardTheme.color,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: Theme.of(context).textTheme.bodyMedium?.color,
                  dividerColor: Colors.transparent,
                  tabs: const [
                    Tab(text: 'Upcoming'),
                    Tab(text: 'Past'),
                    Tab(text: 'Canceled'),
                  ],
                ),
              ),
            ).animate().fade().slideY(begin: -0.2),
            const SizedBox(height: AppConstants.paddingM),
            Expanded(
              child: bookingsAsync.when(
                data: (bookings) => TabBarView(
                  controller: _tabController,
                  children: [
                    _buildSessionList(bookings, ['upcoming', 'pending', 'accepted']),
                    _buildSessionList(bookings, ['completed']),
                    _buildSessionList(bookings, ['canceled', 'cancelled', 'rejected']),
                  ],
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, st) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 48),
                      const SizedBox(height: 16),
                      Text('Error loading bookings', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () => ref.read(bookingNotifierProvider.notifier).refresh(),
                        child: const Text('Retry'),
                      )
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionList(List<BookingModel> allBookings, List<String> statuses) {
    final sessions = allBookings.where((b) => statuses.contains(b.bookingStatus)).toList();
    
    if (sessions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.paddingL),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.event_busy_rounded, size: 54, color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5)),
              const SizedBox(height: 14),
              Text(
                'No sessions in this category',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              const Text(
                'Explore the skill catalog and connect with a mentor to book your next exchange session.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                icon: const Icon(Icons.explore_rounded, size: 16),
                label: const Text('Discover Skills'),
                onPressed: () => Navigator.pushNamed(context, AppRoutes.explore),
              ),
            ],
          ),
        ),
      );
    }

    final dateFormat = DateFormat('MMM dd, yyyy • h:mm a');

    return RefreshIndicator(
      onRefresh: () => ref.read(bookingNotifierProvider.notifier).refresh(),
      child: ListView.builder(
        padding: const EdgeInsets.only(
          left: AppConstants.paddingM,
          right: AppConstants.paddingM,
          bottom: 100, // Bottom nav padding
        ),
        itemCount: sessions.length,
        itemBuilder: (context, index) {
          final session = sessions[index];
          DateTime parsedDate;
          try {
            parsedDate = DateTime.parse('${session.bookingDate} ${session.bookingTime}');
          } catch (_) {
            parsedDate = DateTime.now();
          }

          final isUpcoming = session.bookingStatus == 'upcoming' || session.bookingStatus == 'pending' || session.bookingStatus == 'accepted';
          final isPast = session.bookingStatus == 'completed';
          final isCanceled = session.bookingStatus == 'canceled' || session.bookingStatus == 'cancelled' || session.bookingStatus == 'rejected';

          return InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => SessionDetailsScreen(booking: session)),
              );
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: AppConstants.paddingM),
              padding: const EdgeInsets.all(AppConstants.paddingM),
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color,
                borderRadius: BorderRadius.circular(AppConstants.borderRadiusM),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
                border: Border.all(
                  color: isCanceled ? Colors.red.withValues(alpha: 0.3) : Colors.transparent,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      session.skillTitle,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Icon(
                      isUpcoming
                          ? Icons.schedule_rounded
                          : isPast
                              ? Icons.check_circle_rounded
                              : Icons.cancel_rounded,
                      color: isUpcoming
                          ? Theme.of(context).primaryColor
                          : isPast
                              ? Colors.green
                              : Colors.red,
                      size: 20,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.2),
                      child: const Icon(Icons.person, size: 16),
                    ),
                    const SizedBox(width: 8),
                    Text('Mentor: ${session.mentorName}', style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.calendar_today_rounded, size: 14, color: Colors.grey),
                        const SizedBox(width: 6),
                        Text(dateFormat.format(parsedDate), style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                    if (isUpcoming)
                      InkWell(
                        onTap: () async {
                          await ref.read(bookingNotifierProvider.notifier).updateBookingStatus(session.id, 'cancelled');
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ).animate().fade(delay: (index * 100).ms).slideY(begin: 0.1);
        },
      ),
    );
  }
}

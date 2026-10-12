import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/admin/admin_stats_provider.dart';
import '../../providers/admin/admin_users_provider.dart';
import '../../providers/admin/admin_skills_provider.dart';
import '../../providers/admin/admin_bookings_provider.dart';
import '../../providers/admin/admin_reviews_provider.dart';
import '../../providers/community_provider.dart';
import '../../repositories/community_repository.dart';
import '../../core/widgets/loading_state.dart';
import '../../core/widgets/error_state.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/custom_avatar.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 6,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Admin Dashboard'),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Stats'),
              Tab(text: 'Users'),
              Tab(text: 'Skills'),
              Tab(text: 'Bookings'),
              Tab(text: 'Reviews'),
              Tab(text: 'Reports'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _StatsTab(),
            _UsersTab(),
            _SkillsTab(),
            _BookingsTab(),
            _ReviewsTab(),
            _ReportsTab(),
          ],
        ),
      ),
    );
  }
}

// Stats Tab
class _StatsTab extends ConsumerWidget {
  const _StatsTab();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncStats = ref.watch(adminStatsProvider);
    return asyncStats.when(
      data: (stats) {
        final entries = stats.entries.toList();
        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 3,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: entries.length,
          itemBuilder: (context, i) {
            final e = entries[i];
            return Card(
              child: Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text(e.key, style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(e.value.toString()),
                ]),
              ),
            );
          },
        );
      },
      loading: () => const LoadingFullScreen(message: 'Loading stats...'),
      error: (e, _) => ErrorStateWidget(error: e, onRetry: () => ref.refresh(adminStatsProvider)),
    );
  }
}

// Users Tab
class _UsersTab extends ConsumerStatefulWidget {
  const _UsersTab();
  @override
  ConsumerState<_UsersTab> createState() => _UsersTabState();
}

class _UsersTabState extends ConsumerState<_UsersTab> {
  final TextEditingController _searchCtrl = TextEditingController();
  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    final asyncState = ref.watch(adminUsersProvider);
    final state = asyncState.asData?.value;
    final isLoading = asyncState.isLoading;
    final hasError = asyncState.hasError && (state?.errorMessage != null) && (state?.users.isEmpty ?? true);
    return Column(children: [
      Padding(
        padding: const EdgeInsets.all(8),
        child: TextField(
          controller: _searchCtrl,
          decoration: const InputDecoration(hintText: 'Search users', prefixIcon: Icon(Icons.search)),
          onSubmitted: (v) => ref.read(adminUsersProvider.notifier).search(v),
        ),
      ),
      Expanded(
        child: isLoading && (state?.users.isEmpty ?? true)
          ? const LoadingFullScreen(message: 'Loading users...')
          : hasError
            ? ErrorStateWidget(error: state!.errorMessage!,            onRetry: () => ref.read(adminUsersProvider.notifier).refresh(),)
            : (state == null || state.users.isEmpty)
              ? const EmptyStateWidget(type: EmptyStateType.generic)
              : RefreshIndicator(
                  onRefresh: () async => ref.read(adminUsersProvider.notifier).refresh(),
                  child: ListView.builder(
                    itemCount: state.users.length + (state.hasMore ? 1 : 0),
                    itemBuilder: (c, i) {
                      if (i < state.users.length) {
                        final u = state.users[i];
                        return ListTile(
                          leading: CustomAvatar(imageUrl: u.avatarUrl, name: u.name, radius: 20),
                          title: Text(u.name),
                          subtitle: Text(u.title),
                        );
                      }
                      return Center(child: ElevatedButton(onPressed: () => ref.read(adminUsersProvider.notifier).loadMore(), child: const Text('Load More')));
                    },
                  ),
                ),
      ),
    ]);
  }
}

// Skills Tab
class _SkillsTab extends ConsumerStatefulWidget { const _SkillsTab(); @override ConsumerState<_SkillsTab> createState() => _SkillsTabState(); }
class _SkillsTabState extends ConsumerState<_SkillsTab> {
  @override
  Widget build(BuildContext context) {
    final asyncState = ref.watch(adminSkillsProvider);
    final state = asyncState.asData?.value;
    final isLoading = asyncState.isLoading;
    final hasError = asyncState.hasError && (state?.errorMessage != null) && (state?.skills.isEmpty ?? true);
    return isLoading && (state?.skills.isEmpty ?? true)
      ? const LoadingFullScreen(message: 'Loading skills...')
      : hasError
          ? ErrorStateWidget(error: state!.errorMessage!, onRetry: () => ref.read(adminSkillsProvider.notifier).refresh())
        : (state == null || state.skills.isEmpty)
          ? const EmptyStateWidget(type: EmptyStateType.generic)
          : RefreshIndicator(
              onRefresh: () async => ref.read(adminSkillsProvider.notifier).refresh(),
              child: ListView.builder(
                itemCount: state.skills.length + (state.hasMore ? 1 : 0),
                itemBuilder: (c,i){
                  if(i < state.skills.length){
                    final s = state.skills[i];
                    return ListTile(title: Text(s.title), subtitle: Text(s.ownerName));
                  }
                  return Center(child: ElevatedButton(onPressed: () => ref.read(adminSkillsProvider.notifier).loadMore(), child: const Text('Load More')));
                },
              ),
            );
  }
}

// Bookings Tab
class _BookingsTab extends ConsumerStatefulWidget { const _BookingsTab(); @override ConsumerState<_BookingsTab> createState() => _BookingsTabState(); }
class _BookingsTabState extends ConsumerState<_BookingsTab> {
  @override
  Widget build(BuildContext context) {
    final asyncState = ref.watch(adminBookingsProvider);
    final state = asyncState.asData?.value;
    final isLoading = asyncState.isLoading;
    final hasError = asyncState.hasError && (state?.errorMessage != null) && (state?.bookings.isEmpty ?? true);
    if (isLoading && (state?.bookings.isEmpty ?? true)) {
      return const LoadingFullScreen(message: 'Loading bookings...');
    }
    if (hasError) {
      return ErrorStateWidget(
        error: state!.errorMessage!,
        onRetry: () => ref.read(adminBookingsProvider.notifier).refresh(),
      );
    }
    if (state == null || state.bookings.isEmpty) {
      return const EmptyStateWidget(type: EmptyStateType.generic);
    }
    return RefreshIndicator(
      onRefresh: () async => ref.read(adminBookingsProvider.notifier).refresh(),
      child: ListView.builder(
        itemCount: state.bookings.length + (state.hasMore ? 1 : 0),
        itemBuilder: (c, i) {
          if (i < state.bookings.length) {
            final b = state.bookings[i];
            return ListTile(title: Text('Booking #${b.id}'), subtitle: Text('Status: ${b.bookingStatus}'));
          }
          return Center(child: ElevatedButton(onPressed: () => ref.read(adminBookingsProvider.notifier).loadMore(), child: const Text('Load More')));
        },
      ),
    );
  }
}

// Reviews Tab
class _ReviewsTab extends ConsumerStatefulWidget { const _ReviewsTab(); @override ConsumerState<_ReviewsTab> createState() => _ReviewsTabState(); }
class _ReviewsTabState extends ConsumerState<_ReviewsTab> {
  @override
  Widget build(BuildContext context) {
    final asyncState = ref.watch(adminReviewsProvider);
    final state = asyncState.asData?.value;
    final isLoading = asyncState.isLoading;
    final hasError = asyncState.hasError && (state?.errorMessage != null) && (state?.reviews.isEmpty ?? true);
    if (isLoading && (state?.reviews.isEmpty ?? true)) {
      return const LoadingFullScreen(message: 'Loading reviews...');
    }
    if (hasError) {
      return ErrorStateWidget(
        error: state!.errorMessage!,
        onRetry: () => ref.read(adminReviewsProvider.notifier).refresh(),
      );
    }
    if (state == null || state.reviews.isEmpty) {
      return const EmptyStateWidget(type: EmptyStateType.generic);
    }
    return RefreshIndicator(
      onRefresh: () async => ref.read(adminReviewsProvider.notifier).refresh(),
      child: ListView.builder(
        itemCount: state.reviews.length + (state.hasMore ? 1 : 0),
        itemBuilder: (c, i) {
          if (i < state.reviews.length) {
            final r = state.reviews[i];
            return ListTile(
              leading: CustomAvatar(imageUrl: r.reviewerImageUrl, name: r.reviewerName, radius: 20),
              title: Text(r.reviewerName),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: List.generate(5, (idx) => Icon(idx < r.rating ? Icons.star_rounded : Icons.star_border_rounded, color: Colors.amber, size: 14))),
                  const SizedBox(height: 4),
                  Text(r.comment.isNotEmpty ? r.comment : 'No comment'),
                ],
              ),
            );
          }
          return Center(child: ElevatedButton(onPressed: () => ref.read(adminReviewsProvider.notifier).loadMore(), child: const Text('Load More')));
        },
      ),
    );
  }
}

// Reports Moderation Tab
class _ReportsTab extends ConsumerStatefulWidget {
  const _ReportsTab();
  @override
  ConsumerState<_ReportsTab> createState() => _ReportsTabState();
}

class _ReportsTabState extends ConsumerState<_ReportsTab> {
  String? _filterStatus;

  @override
  Widget build(BuildContext context) {
    final asyncReports = ref.watch(adminReportsProvider(_filterStatus));

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              const Text('Filter status:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(width: 12),
              DropdownButton<String?>(
                value: _filterStatus,
                hint: const Text('All'),
                items: const [
                  DropdownMenuItem(value: null, child: Text('All')),
                  DropdownMenuItem(value: 'pending', child: Text('Pending')),
                  DropdownMenuItem(value: 'reviewed', child: Text('Reviewed')),
                  DropdownMenuItem(value: 'resolved', child: Text('Resolved')),
                  DropdownMenuItem(value: 'dismissed', child: Text('Dismissed')),
                ],
                onChanged: (val) {
                  setState(() => _filterStatus = val);
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: asyncReports.when(
            data: (reports) {
              if (reports.isEmpty) {
                return const Center(
                  child: Text('No reports found.', style: TextStyle(color: Colors.grey)),
                );
              }
              return RefreshIndicator(
                onRefresh: () async => ref.refresh(adminReportsProvider(_filterStatus)),
                child: ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: reports.length,
                  itemBuilder: (context, i) {
                    final report = reports[i];
                    Color statusColor;
                    switch (report.status) {
                      case 'pending':
                        statusColor = Colors.orange;
                        break;
                      case 'reviewed':
                        statusColor = Colors.blue;
                        break;
                      case 'resolved':
                        statusColor = Colors.green;
                        break;
                      case 'dismissed':
                        statusColor = Colors.grey;
                        break;
                      default:
                        statusColor = Colors.grey;
                    }

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.flag_rounded, color: Colors.red, size: 18),
                                    const SizedBox(width: 6),
                                    Text('Report #${report.id}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: statusColor.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    report.status.toUpperCase(),
                                    style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 11),
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 16),
                            Text('Reported User: ID #${report.reportedUserId}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                            Text('Reporter: ID #${report.reporterId}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                            const SizedBox(height: 6),
                            Text('Reason: ${report.reason}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            if (report.details != null && report.details!.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text('Details: ${report.details}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                            ],
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                if (report.status != 'dismissed')
                                  TextButton(
                                    onPressed: () async {
                                      final repo = ref.read(communityRepositoryProvider);
                                      await repo.updateReportStatus(report.id, 'dismissed');
                                      ref.invalidate(adminReportsProvider(_filterStatus));
                                    },
                                    child: const Text('Dismiss', style: TextStyle(color: Colors.grey)),
                                  ),
                                if (report.status != 'resolved')
                                  ElevatedButton(
                                    onPressed: () async {
                                      final repo = ref.read(communityRepositoryProvider);
                                      await repo.updateReportStatus(report.id, 'resolved');
                                      ref.invalidate(adminReportsProvider(_filterStatus));
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      minimumSize: Size.zero,
                                    ),
                                    child: const Text('Resolve', style: TextStyle(fontSize: 12)),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
            },
            loading: () => const LoadingFullScreen(message: 'Loading reports...'),
            error: (e, _) => ErrorStateWidget(
              error: e,
              onRetry: () => ref.refresh(adminReportsProvider(_filterStatus)),
            ),
          ),
        ),
      ],
    );
  }
}

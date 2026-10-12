import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../core/widgets/custom_avatar.dart';
import '../../core/widgets/loading_state.dart';
import '../../core/widgets/error_state.dart';
import '../../providers/gamification_provider.dart';

class LeaderboardScreen extends ConsumerWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leaderboardAsync = ref.watch(leaderboardProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Community Leaderboard'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(leaderboardProvider);
        },
        child: leaderboardAsync.when(
          data: (entries) {
            if (entries.isEmpty) {
              return const Center(
                child: Text('No leaderboard entries yet.', style: TextStyle(color: Colors.grey)),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(AppConstants.paddingM),
              itemCount: entries.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: AppConstants.paddingM),
                    padding: const EdgeInsets.all(AppConstants.paddingM),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardTheme.color,
                      borderRadius: BorderRadius.circular(AppConstants.radiusM),
                      border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.shield_outlined, color: Colors.blue, size: 28),
                        const SizedBox(width: AppConstants.paddingM),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Transparent Community Rankings',
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                'Rankings reflect verified lesson completions, practice scores, and exchange sessions. Personal data remains private.',
                                style: TextStyle(color: Colors.grey, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final entry = entries[index - 1];
                Color? rankColor;
                if (entry.rank == 1) {
                  rankColor = const Color(0xFFD4AF37); // Gold
                } else if (entry.rank == 2) {
                  rankColor = const Color(0xFFC0C0C0); // Silver
                } else if (entry.rank == 3) {
                  rankColor = const Color(0xFFCD7F32); // Bronze
                }

                return Card(
                  margin: const EdgeInsets.only(bottom: AppConstants.paddingS),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppConstants.radiusM),
                    side: BorderSide(
                      color: rankColor != null ? rankColor.withValues(alpha: 0.5) : Colors.grey.withValues(alpha: 0.15),
                      width: rankColor != null ? 1.5 : 1.0,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          alignment: Alignment.center,
                          child: rankColor != null
                              ? Icon(Icons.military_tech_rounded, color: rankColor, size: 28)
                              : Text(
                                  '#${entry.rank}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.grey),
                                ),
                        ),
                        const SizedBox(width: 8),
                        CustomAvatar(
                          radius: 20,
                          imageUrl: entry.avatarUrl,
                          name: entry.name,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      entry.name,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).primaryColor.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      'Lvl ${entry.level}',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context).primaryColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Text(
                                    '${entry.completedPaths} paths',
                                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                                  ),
                                  const Text(' • ', style: TextStyle(color: Colors.grey, fontSize: 11)),
                                  Text(
                                    '${entry.certificatesCount} certs',
                                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                                  ),
                                  const Text(' • ', style: TextStyle(color: Colors.grey, fontSize: 11)),
                                  Text(
                                    '${entry.completedExchanges} exchanges',
                                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${entry.xp}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                            const Text('XP', style: TextStyle(fontSize: 10, color: Colors.grey)),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
          loading: () => const LoadingFullScreen(message: 'Loading leaderboard...'),
          error: (err, _) => ErrorStateWidget(
            error: err,
            onRetry: () => ref.refresh(leaderboardProvider),
          ),
        ),
      ),
    );
  }
}

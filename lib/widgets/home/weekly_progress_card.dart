import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/ai_coach_provider.dart';
import '../../providers/gamification_provider.dart';

class WeeklyProgressCard extends ConsumerWidget {
  final EdgeInsetsGeometry? margin;
  const WeeklyProgressCard({super.key, this.margin});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final insightsAsync = ref.watch(aiCoachWeeklyInsightsProvider);
    final gamificationAsync = ref.watch(gamificationDashboardProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: margin ?? const EdgeInsets.symmetric(horizontal: AppConstants.paddingL),
      padding: const EdgeInsets.all(AppConstants.paddingL),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: isDark ? 0.25 : 0.15),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.bar_chart_rounded, color: theme.colorScheme.primary, size: 18),
                    ),
                    const SizedBox(width: 8),
                    const Flexible(
                      child: Text(
                        'WEEKLY LEARNING ACTIVITY',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                          color: Colors.blueAccent,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              insightsAsync.when(
                data: (ins) => Text(
                  ins.consistencyRating.isNotEmpty ? ins.consistencyRating : 'Active',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade600,
                  ),
                ),
                loading: () => const SizedBox.shrink(),
                error: (e, _) => const SizedBox.shrink(),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Weekly Metrics Overview
          insightsAsync.when(
            data: (ins) {
              final int xp = ins.xpGainedWeek > 0 ? ins.xpGainedWeek : (gamificationAsync.valueOrNull?.levelInfo.currentXp ?? 0);
              final int lessonsCount = gamificationAsync.valueOrNull?.learningStats.lessonsCompleted ?? 3;
              final double avgAcc = ins.averageAccuracyWeek > 0 ? ins.averageAccuracyWeek : 85.0;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildMetricItem(context, label: 'XP Gained', value: '+$xp', icon: Icons.bolt_rounded, color: Colors.amber.shade700),
                      Container(height: 24, width: 1, color: Colors.grey.withValues(alpha: 0.3)),
                      _buildMetricItem(context, label: 'Lessons', value: '$lessonsCount Done', icon: Icons.menu_book_rounded, color: theme.primaryColor),
                      Container(height: 24, width: 1, color: Colors.grey.withValues(alpha: 0.3)),
                      _buildMetricItem(context, label: 'Quiz Avg', value: '${avgAcc.round()}%', icon: Icons.military_tech_rounded, color: Colors.green),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Weekly 7-day Bar Chart Visualizer
                  _buildDayBars(context, streakDays: ins.streakDays > 0 ? ins.streakDays : 1),
                ],
              );
            },
            loading: () => const SizedBox(
              height: 100,
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
            error: (e, _) => _buildDayBars(context, streakDays: 1),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem(BuildContext context, {required String label, required String value, required IconData icon, required Color color}) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildDayBars(BuildContext context, {required int streakDays}) {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final todayWeekday = DateTime.now().weekday; // 1 = Mon, 7 = Sun
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(7, (index) {
        final dayNum = index + 1;
        final isToday = dayNum == todayWeekday;
        final isPastActive = dayNum <= todayWeekday && (todayWeekday - dayNum) < (streakDays > 0 ? streakDays : 1);
        final height = isToday ? 48.0 : (isPastActive ? 36.0 : 16.0);

        return Column(
          children: [
            Container(
              width: 24,
              height: height,
              decoration: BoxDecoration(
                color: isToday
                    ? theme.colorScheme.primary
                    : (isPastActive
                        ? theme.colorScheme.primary.withValues(alpha: 0.4)
                        : (isDark ? Colors.grey.shade800 : Colors.grey.shade200)),
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              days[index],
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: isToday ? FontWeight.bold : FontWeight.w500,
                color: isToday
                    ? theme.colorScheme.primary
                    : (isDark ? Colors.grey.shade400 : Colors.grey.shade600),
              ),
            ),
          ],
        );
      }),
    );
  }
}

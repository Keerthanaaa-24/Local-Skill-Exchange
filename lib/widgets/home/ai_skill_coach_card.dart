import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/ai_coach_provider.dart';
import '../../routes/app_routes.dart';

class AiSkillCoachCard extends ConsumerWidget {
  const AiSkillCoachCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coachAsync = ref.watch(aiCoachSummaryProvider);
    final theme = Theme.of(context);

    return coachAsync.when(
      data: (coach) {
        final hero = coach.heroRecommendation;
        final dailyGoal = coach.dailyGoal;
        if (hero == null && dailyGoal == null) return const SizedBox.shrink();

        // Determine context-aware header & badges
        final String titleText;
        final String subtitleText;
        final String badgeText;
        final Color badgeColor;
        final IconData stateIcon;

        if (dailyGoal != null && dailyGoal.priority == 'urgent') {
          titleText = dailyGoal.goalTitle;
          subtitleText = dailyGoal.description;
          badgeText = 'Needs Revision';
          badgeColor = Colors.orange.shade800;
          stateIcon = Icons.warning_amber_rounded;
        } else if (dailyGoal != null) {
          titleText = dailyGoal.goalTitle;
          subtitleText = dailyGoal.description;
          badgeText = 'Daily Goal';
          badgeColor = theme.primaryColor;
          stateIcon = Icons.track_changes_rounded;
        } else {
          titleText = 'Next Focus: ${hero?.skillName ?? 'Skill Development'}';
          subtitleText = hero?.reason ?? 'AI tailored learning recommendation.';
          badgeText = '${hero?.confidenceScore ?? 90}% Match';
          badgeColor = Colors.amber.shade900;
          stateIcon = Icons.auto_awesome;
        }

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: AppConstants.paddingL),
          padding: const EdgeInsets.all(AppConstants.paddingM),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.primaryColor.withValues(alpha: 0.12),
                Colors.purple.withValues(alpha: 0.08),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.primaryColor.withValues(alpha: 0.25)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: theme.primaryColor.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(stateIcon, color: theme.primaryColor, size: 16),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Your AI Skill Coach',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      if (coach.streakDays > 0) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade100,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.local_fire_department_rounded, size: 12, color: Colors.deepOrange),
                              Text(
                                '${coach.streakDays}d',
                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.deepOrange),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  InkWell(
                    onTap: () => Navigator.pushNamed(context, AppRoutes.aiCoach),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      child: Row(
                        children: [
                          Text(
                            'Growth Hub',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: theme.primaryColor,
                            ),
                          ),
                          Icon(Icons.chevron_right, size: 16, color: theme.primaryColor),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          titleText,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          subtitleText,
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade700, height: 1.3),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: badgeColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      badgeText,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: badgeColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.pushNamed(context, AppRoutes.aiCoach),
                      icon: const Icon(Icons.insights_rounded, size: 14),
                      label: Text(dailyGoal != null ? dailyGoal.actionLabel : 'Open Coach Hub'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () => Navigator.pushNamed(context, AppRoutes.aiCoach),
                    icon: const Icon(Icons.alt_route_rounded, size: 14),
                    label: const Text('Roadmap'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      textStyle: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (err, stack) => const SizedBox.shrink(),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/learning/learning_providers.dart';
import '../../providers/gamification_provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../routes/app_routes.dart';
import '../../core/widgets/loading_state.dart';
import '../../core/widgets/error_state.dart';
import '../../models/skill_model.dart';
import '../../models/learning_path_model.dart';
import '../../repositories/learning_repository.dart';

class LearningProgressCard extends ConsumerWidget {
  const LearningProgressCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progressListAsync = ref.watch(userProgressProvider);
    final gamificationAsync = ref.watch(gamificationDashboardProvider);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppConstants.paddingL),
      padding: const EdgeInsets.all(AppConstants.paddingL),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppConstants.radiusL),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Gamification Header: Level + Streak
          gamificationAsync.when(
            data: (dash) {
              final lvl = dash.levelInfo;
              final streak = dash.streakInfo;

              return Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.primary),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.military_tech_rounded, size: 16, color: AppColors.primary),
                                const SizedBox(width: 4),
                                Text(
                                  'Level ${lvl.level}: ${lvl.title}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.primary),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      InkWell(
                        onTap: () => Navigator.pushNamed(context, AppRoutes.leaderboard),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.orange.shade200),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.local_fire_department_rounded, size: 16, color: Colors.deepOrange),
                              const SizedBox(width: 4),
                              Text(
                                '${streak.currentStreak}d Streak',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.deepOrange),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${lvl.currentXp} XP',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey),
                      ),
                      Text(
                        'Next: ${lvl.nextLevelXp} XP (${lvl.xpToNextLevel} to go)',
                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (lvl.levelProgressPercent / 100).clamp(0.0, 1.0),
                      minHeight: 6,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
                    ),
                  ),
                  const Divider(height: 20),
                ],
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (err, stack) => const SizedBox.shrink(),
          ),

          // Active Learning Path or CTA
          progressListAsync.when(
            loading: () => const LoadingSkeletonCard(),
            error: (err, stack) => ErrorStateWidget(error: err, onRetry: () => ref.refresh(userProgressProvider)),
            data: (progressList) {
              final inProgress = progressList.where((p) => p.completedAt == null).toList();
              if (inProgress.isEmpty) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Start Learning', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Text('Explore structured skills to earn XP, level up, and gain certificates.', style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.school_outlined, size: 18),
                      onPressed: () => Navigator.pushNamed(context, AppRoutes.learningHub),
                      label: const Text('Browse Skills'),
                    ),
                  ],
                );
              }

              final prog = inProgress.first;
              return FutureBuilder<LearningPathModel>(
                future: ref.read(learningRepositoryProvider).getLearningPathById(prog.learningPathId),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const LoadingSkeletonCard();
                  final path = snapshot.data!;
                  final total = path.lessons.length;
                  final completed = prog.completedLessons.length;
                  final percent = total == 0 ? 0 : (completed / total * 100).round();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Continue Learning', style: Theme.of(context).textTheme.titleSmall?.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold)),
                          Text('$percent%', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(path.title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: total == 0 ? 0 : completed / total,
                          minHeight: 6,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          ElevatedButton.icon(
                            icon: const Icon(Icons.play_arrow_rounded, size: 18),
                            onPressed: () => Navigator.pushNamed(
                              context,
                              AppRoutes.skillLearning,
                              arguments: SkillModel(
                                id: path.skillId,
                                title: path.title,
                                description: path.description ?? '',
                                ownerId: 0,
                                ownerName: '',
                                credits: 0,
                                rating: 0,
                                reviewCount: 0,
                                isAvailable: true,
                              ),
                            ),
                            label: const Text('Continue Lesson'),
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: () => Navigator.pushNamed(context, AppRoutes.learningHub),
                            child: const Text('All Courses'),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

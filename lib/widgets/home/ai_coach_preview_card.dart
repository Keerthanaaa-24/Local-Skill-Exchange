import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../models/skill_model.dart';
import '../../providers/ai_coach_provider.dart';
import '../../routes/app_routes.dart';
import '../../screens/learning/skill_learning_screen.dart';

class AiCoachPreviewCard extends ConsumerWidget {
  final EdgeInsetsGeometry? margin;
  const AiCoachPreviewCard({super.key, this.margin});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coachAsync = ref.watch(aiCoachSummaryProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: margin ?? const EdgeInsets.symmetric(horizontal: AppConstants.paddingL),
      padding: const EdgeInsets.all(AppConstants.paddingL),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [
                  const Color(0xFF1E1E2E),
                  const Color(0xFF2A2040),
                ]
              : [
                  Colors.deepPurple.shade50.withValues(alpha: 0.7),
                  Colors.indigo.shade50.withValues(alpha: 0.5),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.deepPurple.withValues(alpha: isDark ? 0.35 : 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: coachAsync.when(
        data: (coach) {
          final hero = coach.heroRecommendation;
          final targetTitle = hero != null
              ? 'Complete: ${hero.skillName}'
              : 'Complete: Core Skill Fundamentals';
          final reasonText = hero?.reason ??
              'Strengthen your profile by completing interactive lessons and timed certification assessments.';
          final int confidence = hero?.confidenceScore ?? 92;

          return Column(
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
                            color: Colors.deepPurple.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.auto_awesome_rounded, color: Colors.deepPurple, size: 18),
                        ),
                        const SizedBox(width: 8),
                        const Flexible(
                          child: Text(
                            'YOUR NEXT BEST STEP',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                              color: Colors.deepPurple,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.deepPurple.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$confidence% Match',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                        color: Colors.deepPurple,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                targetTitle,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Reason: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  Expanded(
                    child: Text(
                      reasonText,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      if (hero != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SkillLearningScreen(
                              skill: SkillModel(
                                id: hero.skillId,
                                title: hero.skillName,
                                description: hero.reason,
                                categoryName: hero.category,
                                ownerId: 0,
                                ownerName: 'AI Recommended',
                                credits: 10,
                                rating: 5.0,
                                reviewCount: 10,
                                isAvailable: true,
                              ),
                            ),
                          ),
                        );
                      } else {
                        Navigator.pushNamed(context, AppRoutes.learningHub);
                      }
                    },
                    icon: const Icon(Icons.play_arrow_rounded, size: 16),
                    label: const Text('Start'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => Navigator.pushNamed(context, AppRoutes.aiMatch),
                    icon: const Icon(Icons.chat_bubble_outline_rounded, size: 14),
                    label: const Text('Ask AI Coach'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.deepPurple,
                      side: const BorderSide(color: Colors.deepPurple),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
        loading: () => const SizedBox(
          height: 100,
          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
        error: (e, _) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'YOUR NEXT BEST STEP',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.deepPurple),
            ),
            const SizedBox(height: 6),
            const Text('Explore personalized skill suggestions tailored to your profile.'),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, AppRoutes.aiMatch),
              child: const Text('Ask AI Coach'),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../core/widgets/loading_state.dart';
import '../../core/widgets/error_state.dart';
import '../../models/recommendation_model.dart';
import '../../models/skill_model.dart';
import '../../repositories/skill_repository.dart';
import '../../screens/features/mentor_profile_screen.dart';
import '../../screens/learning/skill_learning_screen.dart';
import '../../routes/app_routes.dart';

/// Fetch AI recommendations using the existing repository.
final aiRecommendationsProvider = FutureProvider.autoDispose<List<RecommendationModel>>((ref) async {
  return await ref.read(skillRepositoryProvider).getRecommendations();
});

class RecommendedSkillsSection extends ConsumerWidget {
  const RecommendedSkillsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncRecs = ref.watch(aiRecommendationsProvider);
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingL),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recommended For You',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                ),
              ),
              InkWell(
                onTap: () => Navigator.pushNamed(context, AppRoutes.explore),
                child: Text(
                  'Explore All →',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: theme.primaryColor,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppConstants.paddingM),
        asyncRecs.when(
          data: (recs) {
            // Filter valid recommendations (no test users)
            final validRecs = recs.where((r) {
              final mName = r.mentorName.toLowerCase();
              final sTitle = r.skillTitle.toLowerCase();
              return !mName.contains('e2e') &&
                  !mName.contains('test user') &&
                  !sTitle.startsWith('skill_updated_') &&
                  !sTitle.startsWith('skilldirecttest');
            }).toList();

            if (validRecs.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingL),
                child: Container(
                  padding: const EdgeInsets.all(AppConstants.paddingM),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                  ),
                  child: const Center(
                    child: Text('Start learning skills to get AI-tailored recommendations!'),
                  ),
                ),
              );
            }

            return SizedBox(
              height: 245,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingL),
                scrollDirection: Axis.horizontal,
                itemCount: validRecs.length,
                itemBuilder: (context, index) {
                  final rec = validRecs[index];
                  return Padding(
                    padding: const EdgeInsets.only(right: AppConstants.paddingM),
                    child: _RecommendationCard(rec: rec),
                  );
                },
              ),
            );
          },
          loading: () => SizedBox(
            height: 245,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingL),
              scrollDirection: Axis.horizontal,
              itemCount: 3,
              itemBuilder: (context, index) => const Padding(
                padding: EdgeInsets.only(right: AppConstants.paddingM),
                child: LoadingSkeletonCard(width: 240, height: 245),
              ),
            ),
          ),
          error: (e, _) => ErrorStateWidget(
            error: e,
            onRetry: () => ref.refresh(aiRecommendationsProvider),
          ),
        ),
      ],
    );
  }
}

class _RecommendationCard extends ConsumerWidget {
  final RecommendationModel rec;
  const _RecommendationCard({required this.rec});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final skillModel = SkillModel(
      id: rec.skillId,
      title: rec.skillTitle,
      description: rec.reason ?? rec.explanation,
      categoryName: rec.skillCategory ?? 'General',
      ownerId: rec.mentorId,
      ownerName: rec.mentorName,
      ownerProfileImage: rec.mentorProfileImage,
      credits: 10,
      rating: rec.rating ?? 5.0,
      reviewCount: rec.mentorReviewCount ?? 12,
      isAvailable: true,
    );

    return Container(
      width: 250,
      padding: const EdgeInsets.all(AppConstants.paddingM),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.primary.withValues(alpha: isDark ? 0.25 : 0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      rec.skillTitle,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    if (rec.skillCategory != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        rec.skillCategory!,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.primary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                ),
                child: Text(
                  '${rec.matchScore.round()}% Match',
                  style: TextStyle(
                    color: Colors.green.shade700,
                    fontWeight: FontWeight.bold,
                    fontSize: 10.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Reason box
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey.shade900.withValues(alpha: 0.5) : Colors.indigo.shade50.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.auto_awesome, size: 13, color: theme.colorScheme.primary),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      rec.reason ?? rec.explanation,
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.grey.shade300 : Colors.grey.shade800,
                        height: 1.25,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Action Buttons: Learn, Offer, Request
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SkillLearningScreen(skill: skillModel),
                      ),
                    );
                  },
                  icon: const Icon(Icons.play_circle_outline_rounded, size: 13),
                  label: const Text('Learn'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              OutlinedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => MentorProfileScreen(recommendation: rec),
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  textStyle: const TextStyle(fontSize: 11),
                ),
                child: const Text('Mentor'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

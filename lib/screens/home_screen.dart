import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/app_constants.dart';
import '../core/theme/app_colors.dart';
import '../core/utils/responsive_utils.dart';
import '../core/widgets/home_cards.dart';
import '../core/widgets/custom_text_field.dart';
import '../core/widgets/loading_state.dart';
import '../core/widgets/error_state.dart';
import '../routes/app_routes.dart';
import '../providers/skill_provider.dart';
import '../providers/wallet_provider.dart';
import '../providers/user_provider.dart';
import '../providers/community_provider.dart';
import '../providers/gamification_provider.dart';
import '../providers/ai_coach_provider.dart';
import '../providers/booking_provider.dart';
import '../providers/learning/learning_providers.dart';
import '../widgets/home/personalized_hero.dart';
import '../widgets/home/continue_learning_card.dart';
import '../widgets/home/today_goal_card.dart';
import '../widgets/home/upcoming_session_card.dart';
import '../widgets/home/credit_summary_card.dart';
import '../widgets/home/ai_coach_preview_card.dart';
import '../widgets/home/recommended_skills_section.dart';
import '../widgets/home/weekly_progress_card.dart';
import '../widgets/home/achievements_streak_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  static const List<SkillCategoryItem> _categoryItems = [
    SkillCategoryItem(id: 'all', name: 'All Skills', icon: '⚡', iconData: Icons.bolt_rounded),
    SkillCategoryItem(id: 'prog', name: 'Programming', icon: '💻', iconData: Icons.code_rounded),
    SkillCategoryItem(id: 'mobile', name: 'Mobile Dev', icon: '📱', iconData: Icons.phone_android_rounded),
    SkillCategoryItem(id: 'design', name: 'UI / Design', icon: '🎨', iconData: Icons.palette_rounded),
    SkillCategoryItem(id: 'ai', name: 'AI & Data', icon: '🤖', iconData: Icons.psychology_rounded),
    SkillCategoryItem(id: 'languages', name: 'Languages', icon: '🗣️', iconData: Icons.translate_rounded),
    SkillCategoryItem(id: 'music', name: 'Music & Arts', icon: '🎸', iconData: Icons.music_note_rounded),
    SkillCategoryItem(id: 'marketing', name: 'Marketing', icon: '📈', iconData: Icons.trending_up_rounded),
  ];

  Future<void> _handleRefresh(WidgetRef ref) async {
    await Future.wait([
      ref.read(skillsNotifierProvider.notifier).refresh(),
      ref.read(walletNotifierProvider.notifier).refreshWallet(),
      ref.refresh(communityActivityProvider.future),
      ref.refresh(userProgressProvider.future),
      ref.refresh(aiCoachSummaryProvider.future),
      ref.refresh(aiCoachDailyGoalProvider.future),
      ref.refresh(aiCoachWeeklyInsightsProvider.future),
      ref.refresh(gamificationDashboardProvider.future),
      ref.refresh(upcomingBookingsProvider.future),
      ref.refresh(aiRecommendationsProvider.future),
    ]);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final skillsAsync = ref.watch(skillsNotifierProvider);
    final nearbyUsersAsync = ref.watch(nearbyUsersProvider);
    final communityActivityAsync = ref.watch(communityActivityProvider);
    final theme = Theme.of(context);
    final isDesktopOrTablet = !ResponsiveUtils.isMobile(context);

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => _handleRefresh(ref),
          child: CustomScrollView(
            slivers: [
              const SliverToBoxAdapter(child: SizedBox(height: AppConstants.paddingM)),

              // 1. Personalized Hero Section
              const SliverToBoxAdapter(
                child: PersonalizedHero(),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: AppConstants.paddingM)),

              // Search Bar
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingL),
                  child: GestureDetector(
                    onTap: () => Navigator.pushNamed(context, AppRoutes.searchFilter),
                    child: AbsorbPointer(
                      child: CustomTextField(
                        label: '',
                        hint: 'Search skills, topics, or mentors...',
                        prefixIcon: Icons.search_rounded,
                        suffixIcon: const Icon(Icons.tune_rounded),
                      ),
                    ),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: AppConstants.paddingM)),

              // Quick Actions Bar
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingL),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildQuickAction(context, Icons.auto_awesome_rounded, 'AI Match', onTap: () => Navigator.pushNamed(context, AppRoutes.aiMatch)),
                      _buildQuickAction(context, Icons.badge_outlined, 'Skill Passport', onTap: () => Navigator.pushNamed(context, AppRoutes.passport)),
                      _buildQuickAction(context, Icons.calendar_month_outlined, 'Sessions', onTap: () => Navigator.pushNamed(context, AppRoutes.bookings)),
                      _buildQuickAction(context, Icons.leaderboard_outlined, 'Rankings', onTap: () => Navigator.pushNamed(context, AppRoutes.leaderboard)),
                    ],
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: AppConstants.paddingL)),

              // 2-8. Personalized Dashboard Cards (Responsive Layout)
              if (!isDesktopOrTablet) ...[
                // Mobile: Linear Priority Flow
                const SliverToBoxAdapter(child: ContinueLearningCard()),
                const SliverToBoxAdapter(child: SizedBox(height: AppConstants.paddingL)),

                const SliverToBoxAdapter(child: TodayGoalCard()),
                const SliverToBoxAdapter(child: SizedBox(height: AppConstants.paddingL)),

                const SliverToBoxAdapter(child: AiCoachPreviewCard()),
                const SliverToBoxAdapter(child: SizedBox(height: AppConstants.paddingL)),

                const SliverToBoxAdapter(child: UpcomingSessionCard()),
                const SliverToBoxAdapter(child: SizedBox(height: AppConstants.paddingL)),

                const SliverToBoxAdapter(child: CreditSummaryCard()),
                const SliverToBoxAdapter(child: SizedBox(height: AppConstants.paddingL)),

                const SliverToBoxAdapter(child: RecommendedSkillsSection()),
                const SliverToBoxAdapter(child: SizedBox(height: AppConstants.paddingL)),

                const SliverToBoxAdapter(child: WeeklyProgressCard()),
                const SliverToBoxAdapter(child: SizedBox(height: AppConstants.paddingL)),

                const SliverToBoxAdapter(child: AchievementsStreakCard()),
                const SliverToBoxAdapter(child: SizedBox(height: AppConstants.paddingL)),
              ] else ...[
                // Tablet / Desktop: 2-Column Responsive Grid Layout
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingL),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left Column
                        Expanded(
                          flex: 6,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: const [
                              ContinueLearningCard(margin: EdgeInsets.zero),
                              SizedBox(height: AppConstants.paddingL),
                              AiCoachPreviewCard(margin: EdgeInsets.zero),
                              SizedBox(height: AppConstants.paddingL),
                              WeeklyProgressCard(margin: EdgeInsets.zero),
                            ],
                          ),
                        ),
                        const SizedBox(width: AppConstants.paddingL),
                        // Right Column
                        Expanded(
                          flex: 5,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: const [
                              TodayGoalCard(margin: EdgeInsets.zero),
                              SizedBox(height: AppConstants.paddingL),
                              UpcomingSessionCard(margin: EdgeInsets.zero),
                              SizedBox(height: AppConstants.paddingL),
                              CreditSummaryCard(margin: EdgeInsets.zero),
                              SizedBox(height: AppConstants.paddingL),
                              AchievementsStreakCard(margin: EdgeInsets.zero),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: AppConstants.paddingL)),
                const SliverToBoxAdapter(child: RecommendedSkillsSection()),
                const SliverToBoxAdapter(child: SizedBox(height: AppConstants.paddingL)),
              ],

              // Categories Carousel
              SliverToBoxAdapter(
                child: _buildSectionHeader(
                  context,
                  'Skill Domains',
                  onSeeAll: () => Navigator.pushNamed(context, AppRoutes.explore),
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 90,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingL),
                    scrollDirection: Axis.horizontal,
                    itemCount: _categoryItems.length,
                    itemBuilder: (context, index) {
                      return CategoryCard(
                        category: _categoryItems[index],
                        onTap: () => Navigator.pushNamed(context, AppRoutes.explore),
                      );
                    },
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: AppConstants.paddingL)),

              // Skills Market Section
              SliverToBoxAdapter(
                child: _buildSectionHeader(
                  context,
                  'Active Skills Market',
                  onSeeAll: () => Navigator.pushNamed(context, AppRoutes.explore),
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 240,
                  child: skillsAsync.when(
                    data: (skills) {
                      if (skills.isEmpty) {
                        return const Center(child: Text('No skills available at the moment.'));
                      }
                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingL),
                        scrollDirection: Axis.horizontal,
                        itemCount: skills.length,
                        itemBuilder: (context, index) {
                          return HomeSkillCard(skill: skills[index]);
                        },
                      );
                    },
                    loading: () => ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingL),
                      scrollDirection: Axis.horizontal,
                      itemCount: 3,
                      itemBuilder: (context, index) {
                        return const Padding(
                          padding: EdgeInsets.only(right: AppConstants.paddingM),
                          child: LoadingSkeletonCard(width: 200, height: 240),
                        );
                      },
                    ),
                    error: (err, stack) => ErrorStateWidget(
                      error: err,
                      onRetry: () => ref.read(skillsNotifierProvider.notifier).refresh(),
                    ),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: AppConstants.paddingL)),

              // Popular Local Mentors Section
              SliverToBoxAdapter(
                child: _buildSectionHeader(
                  context,
                  'Nearby Mentors',
                  onSeeAll: () => Navigator.pushNamed(context, AppRoutes.explore),
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 165,
                  child: nearbyUsersAsync.when(
                    data: (mentors) {
                      if (mentors.isEmpty) {
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: AppConstants.paddingL),
                          padding: const EdgeInsets.all(AppConstants.paddingM),
                          decoration: BoxDecoration(
                            color: theme.cardColor,
                            borderRadius: BorderRadius.circular(AppConstants.radiusM),
                            border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
                          ),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.people_outline_rounded, size: 28, color: theme.colorScheme.primary.withValues(alpha: 0.7)),
                                const SizedBox(height: 8),
                                const Text(
                                  'No other mentors located nearby yet.',
                                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Share your skills in your profile to become a local mentor!',
                                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingL),
                        scrollDirection: Axis.horizontal,
                        itemCount: mentors.length,
                        itemBuilder: (context, index) {
                          return MentorCard(user: mentors[index]);
                        },
                      );
                    },
                    loading: () => ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingL),
                      scrollDirection: Axis.horizontal,
                      itemCount: 3,
                      itemBuilder: (context, index) => const Padding(
                        padding: EdgeInsets.only(right: AppConstants.paddingM),
                        child: LoadingSkeletonCard(width: 140, height: 165),
                      ),
                    ),
                    error: (err, _) => Center(
                      child: Text('Could not load mentors: $err', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    ),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: AppConstants.paddingL)),

              // Live Community Activity Feed
              SliverToBoxAdapter(
                child: _buildSectionHeader(context, 'Live Community Activity', showSeeAll: false),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingL),
                sliver: SliverToBoxAdapter(
                  child: communityActivityAsync.when(
                    data: (activities) {
                      if (activities.isEmpty) {
                        return Container(
                          padding: const EdgeInsets.all(AppConstants.paddingL),
                          decoration: BoxDecoration(
                            color: theme.cardColor,
                            borderRadius: BorderRadius.circular(AppConstants.radiusM),
                            border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
                          ),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(Icons.local_activity_outlined, size: 26, color: theme.colorScheme.primary.withValues(alpha: 0.7)),
                                const SizedBox(height: 6),
                                const Text(
                                  'No recent community activity yet',
                                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Complete a learning curriculum or book a skill exchange to see your milestones here!',
                                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                      return Column(
                        children: activities.take(3).map((act) {
                          final isCert = act.type == 'certificate';
                          final timeStr = '${act.timestamp.day}/${act.timestamp.month}';
                          return _buildActivityItem(
                            context,
                            act.title,
                            timeStr,
                            isCert ? Icons.workspace_premium_rounded : Icons.check_circle_outline_rounded,
                            isCert ? Colors.amber.shade700 : AppColors.success,
                          );
                        }).toList(),
                      );
                    },
                    loading: () => const Center(
                      child: Padding(
                        padding: EdgeInsets.all(AppConstants.paddingM),
                        child: CircularProgressIndicator(),
                      ),
                    ),
                    error: (err, _) => Center(
                      child: Text('Could not load activity: $err', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    ),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: AppConstants.paddingXL)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, {bool showSeeAll = true, VoidCallback? onSeeAll}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingL, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, fontSize: 17),
          ),
          if (showSeeAll)
            TextButton(
              onPressed: onSeeAll,
              child: Text(
                'Explore →',
                style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildQuickAction(BuildContext context, IconData icon, String label, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(6.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Theme.of(context).primaryColor, size: 24),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem(BuildContext context, String title, String time, IconData icon, Color iconColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600, fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  time,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.textSecondaryLight, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

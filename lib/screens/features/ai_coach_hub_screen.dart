import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../core/widgets/custom_avatar.dart';
import '../../models/ai_coach_models.dart';
import '../../providers/ai_coach_provider.dart';
import '../../routes/app_routes.dart';

class AiCoachHubScreen extends ConsumerStatefulWidget {
  const AiCoachHubScreen({super.key});

  @override
  ConsumerState<AiCoachHubScreen> createState() => _AiCoachHubScreenState();
}

class _AiCoachHubScreenState extends ConsumerState<AiCoachHubScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 7, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _refreshAll() async {
    ref.invalidate(aiCoachSummaryProvider);
    ref.invalidate(aiCoachRoadmapProvider);
    ref.invalidate(aiCoachDailyGoalProvider);
    ref.invalidate(aiCoachGrowthProvider);
    ref.invalidate(aiCoachWeeklyInsightsProvider);
    ref.invalidate(aiCoachAdaptiveProvider);
    await Future.wait([
      ref.refresh(aiCoachSummaryProvider.future),
      ref.refresh(aiCoachDailyGoalProvider.future),
      ref.refresh(aiCoachWeeklyInsightsProvider.future),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final coachAsync = ref.watch(aiCoachSummaryProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_awesome_rounded, color: theme.primaryColor),
            const SizedBox(width: 8),
            const Text('Personal AI Skill Coach'),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          indicatorColor: theme.primaryColor,
          labelColor: theme.primaryColor,
          unselectedLabelColor: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [
            Tab(text: 'Overview', icon: Icon(Icons.dashboard_outlined, size: 18)),
            Tab(text: "Today's Plan", icon: Icon(Icons.checklist_rounded, size: 18)),
            Tab(text: 'Skill Gaps', icon: Icon(Icons.insights_rounded, size: 18)),
            Tab(text: 'Diagnostics', icon: Icon(Icons.quiz_outlined, size: 18)),
            Tab(text: 'Roadmap', icon: Icon(Icons.alt_route_rounded, size: 18)),
            Tab(text: 'Skill Exchange', icon: Icon(Icons.swap_horiz_rounded, size: 18)),
            Tab(text: 'Weekly Insights', icon: Icon(Icons.analytics_outlined, size: 18)),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshAll,
        child: coachAsync.when(
          data: (coach) => TabBarView(
            controller: _tabController,
            children: [
              _buildOverviewTab(context, coach),
              _buildTodayPlanTab(context, coach),
              _buildSkillGapsTab(context, coach),
              _buildDiagnosticsTab(context, coach),
              _buildRoadmapTab(context, coach),
              _buildExchangeTab(context, coach),
              _buildWeeklyInsightsTab(context, coach),
            ],
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.paddingL),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.psychology_alt_outlined, color: isDark ? Colors.grey.shade600 : Colors.grey.shade400, size: 56),
                  const SizedBox(height: 14),
                  const Text(
                    'AI Coach temporarily unavailable.',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Please check your network connection and try again.',
                    style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade600, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _refreshAll,
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 1. Overview Tab
  Widget _buildOverviewTab(BuildContext context, AiCoachSummaryModel coach) {
    final hero = coach.heroRecommendation;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppConstants.paddingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hero != null) ...[
            _buildHeroCard(context, hero),
            const SizedBox(height: AppConstants.paddingL),
          ],

          if (coach.dailyGoal != null) ...[
            _buildSectionHeader(context, "Today's Focus & Learning Plan", Icons.track_changes_rounded),
            const SizedBox(height: AppConstants.paddingS),
            _buildDailyGoalCard(context, coach.dailyGoal!),
            const SizedBox(height: AppConstants.paddingL),
          ],

          if (coach.adaptiveRecommendations.isNotEmpty) ...[
            _buildSectionHeader(context, 'Adaptive Recommendations', Icons.bolt_rounded),
            const SizedBox(height: AppConstants.paddingS),
            ...coach.adaptiveRecommendations.take(3).map((rec) => _buildAdaptiveCard(context, rec)),
            const SizedBox(height: AppConstants.paddingL),
          ],

          if (coach.growthSummary != null) ...[
            _buildSectionHeader(context, 'Skill Growth Velocity', Icons.trending_up_rounded),
            const SizedBox(height: AppConstants.paddingS),
            _buildSkillGrowthCard(context, coach.growthSummary!),
          ],
        ],
      ),
    );
  }

  // 2. Today's Plan Tab
  Widget _buildTodayPlanTab(BuildContext context, AiCoachSummaryModel coach) {
    final planItems = coach.dailyPlan.isNotEmpty ? coach.dailyPlan : (coach.dailyGoal?.dailyPlan ?? []);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppConstants.paddingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(AppConstants.paddingM),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                    : [Colors.teal.shade50, Colors.teal.shade100.withValues(alpha: 0.5)],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.teal.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(color: Colors.teal, shape: BoxShape.circle),
                  child: const Icon(Icons.playlist_add_check_rounded, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Today's AI Learning Plan",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Prioritized based on your unfinished modules, practice scores, and daily targets.',
                        style: TextStyle(fontSize: 12, color: isDark ? Colors.grey.shade300 : Colors.grey.shade700),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppConstants.paddingL),

          if (planItems.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.paddingL),
                child: Text('No daily plan items generated yet.', style: TextStyle(color: Colors.grey.shade600)),
              ),
            )
          else
            ...planItems.asMap().entries.map((entry) {
              final idx = entry.key + 1;
              final item = entry.value;
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(AppConstants.paddingM),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6, offset: const Offset(0, 2)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 26,
                          height: 26,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.teal.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Text('$idx', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.teal, fontSize: 13)),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Icon(Icons.schedule_rounded, size: 13, color: Colors.grey.shade600),
                                  const SizedBox(width: 4),
                                  Text('${item.durationMinutes} min', style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
                                  const SizedBox(width: 10),
                                  Icon(Icons.star_rounded, size: 13, color: Colors.amber.shade700),
                                  const SizedBox(width: 2),
                                  Text('+${item.rewardXp} XP', style: TextStyle(fontSize: 11.5, color: Colors.amber.shade800, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            if (item.actionType == 'learning' || item.actionType == 'practice') {
                              Navigator.pushNamed(context, AppRoutes.learningHub);
                            } else if (item.actionType == 'passport') {
                              Navigator.pushNamed(context, AppRoutes.passport);
                            } else {
                              Navigator.pushNamed(context, AppRoutes.explore);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            textStyle: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                          ),
                          child: const Text('Start'),
                        ),
                      ],
                    ),
                    if (item.reason.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey.shade900 : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Why? ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                            Expanded(
                              child: Text(
                                item.reason,
                                style: TextStyle(fontSize: 11, color: isDark ? Colors.grey.shade400 : Colors.grey.shade700),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  // 3. Skill Gaps Tab
  Widget _buildSkillGapsTab(BuildContext context, AiCoachSummaryModel coach) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final portfolio = coach.skillPortfolio;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppConstants.paddingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(context, 'Skill Portfolio & Gap Status', Icons.insights_rounded),
          const SizedBox(height: 6),
          Text(
            'Live classification of your skill proficiency based on quiz evaluations, learning progress, and certificates.',
            style: TextStyle(fontSize: 12, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
          ),
          const SizedBox(height: AppConstants.paddingL),

          if (portfolio.isEmpty)
            Container(
              padding: const EdgeInsets.all(AppConstants.paddingL),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
              ),
              child: const Center(
                child: Text('Start learning or add wanted skills to see your skill gap analysis.'),
              ),
            )
          else
            ...portfolio.map((item) {
              Color badgeColor = Colors.blue;
              if (item.status == 'Strong') {
                badgeColor = Colors.green;
              } else if (item.status == 'Needs Practice') {
                badgeColor = Colors.deepOrange;
              } else if (item.status == 'Goal Gap') {
                badgeColor = Colors.indigo;
              }

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(AppConstants.paddingM),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: badgeColor.withValues(alpha: 0.25)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            item.skillName,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: badgeColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            item.status,
                            style: TextStyle(color: badgeColor, fontWeight: FontWeight.bold, fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Category: ${item.category} • Level: ${item.level}',
                      style: TextStyle(fontSize: 11.5, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                    ),
                    if (item.reason.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        item.reason,
                        style: TextStyle(fontSize: 12, color: isDark ? Colors.grey.shade300 : Colors.grey.shade700),
                      ),
                    ],
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  // 4. Diagnostics Tab
  Widget _buildDiagnosticsTab(BuildContext context, AiCoachSummaryModel coach) {
    final diagnostics = coach.practiceDiagnostics;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppConstants.paddingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(context, 'Smart Practice Diagnostics & Adaptive Quizzes', Icons.quiz_outlined),
          const SizedBox(height: 6),
          Text(
            'Adaptive evaluation of your strengths, weak areas, and targeted practice sets.',
            style: TextStyle(fontSize: 12, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
          ),
          const SizedBox(height: AppConstants.paddingL),

          if (diagnostics.isEmpty)
            Container(
              padding: const EdgeInsets.all(AppConstants.paddingL),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
              ),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.quiz_outlined, size: 36, color: theme.primaryColor.withValues(alpha: 0.7)),
                    const SizedBox(height: 8),
                    const Text('No recent practice diagnostics yet.', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    const Text('Take a quiz on any lesson to unlock real-time adaptive feedback.'),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () => Navigator.pushNamed(context, AppRoutes.learningHub),
                      child: const Text('Browse Learning Hub'),
                    ),
                  ],
                ),
              ),
            )
          else
            ...diagnostics.map((diag) => _buildDiagnosticCard(context, diag)),
        ],
      ),
    );
  }

  // 5. Roadmap Tab
  Widget _buildRoadmapTab(BuildContext context, AiCoachSummaryModel coach) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppConstants.paddingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(context, 'Personalized Learning Roadmap', Icons.alt_route_rounded),
          const SizedBox(height: 6),
          Text(
            'Step-by-step milestones curated specifically for your learning goals and skill strengths.',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          const SizedBox(height: AppConstants.paddingL),
          _buildRoadmapTimeline(context, coach.roadmapPreview),
        ],
      ),
    );
  }

  // 6. Skill Exchange Tab
  Widget _buildExchangeTab(BuildContext context, AiCoachSummaryModel coach) {
    final exchanges = coach.exchangeSuggestions;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppConstants.paddingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(context, 'Two-Way Reciprocal Skill Exchanges', Icons.swap_horizontal_circle_outlined),
          const SizedBox(height: 6),
          Text(
            'Matches you with peers who teach what you want to learn, and want to learn what you can teach.',
            style: TextStyle(fontSize: 12, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
          ),
          const SizedBox(height: AppConstants.paddingL),

          if (exchanges.isEmpty)
            Container(
              padding: const EdgeInsets.all(AppConstants.paddingL),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
              ),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.handshake_outlined, size: 36, color: theme.primaryColor.withValues(alpha: 0.7)),
                    const SizedBox(height: 8),
                    const Text('No direct 2-way exchange matches yet.', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    const Text('Add offered skills in your profile and wanted skills in your wishlist to enable intelligent reciprocal matching!'),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () => Navigator.pushNamed(context, AppRoutes.passport),
                      child: const Text('Manage Skill Passport'),
                    ),
                  ],
                ),
              ),
            )
          else
            ...exchanges.map((ex) => _buildExchangeCard(context, ex)),
        ],
      ),
    );
  }

  // 7. Weekly Insights Tab
  Widget _buildWeeklyInsightsTab(BuildContext context, AiCoachSummaryModel coach) {
    final insights = coach.weeklyInsights;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppConstants.paddingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(context, 'Weekly AI Learning Velocity', Icons.calendar_view_week_rounded),
          const SizedBox(height: 6),
          Text(
            'Actual metrics tracked across lessons, practice attempts, quiz accuracy, and peer sessions over the past 7 days.',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          const SizedBox(height: AppConstants.paddingL),

          if (insights != null)
            _buildWeeklyInsightsSection(context, insights)
          else
            const Center(child: Text('No weekly insights available yet.')),

          const SizedBox(height: AppConstants.paddingL),
          if (coach.growthSummary != null)
            _buildSkillGrowthCard(context, coach.growthSummary!),
        ],
      ),
    );
  }

  // Common Widget Helpers
  Widget _buildSectionHeader(BuildContext context, String title, IconData icon) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 20, color: theme.primaryColor),
        const SizedBox(width: 8),
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildHeroCard(BuildContext context, HeroRecommendationModel hero) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppConstants.paddingL),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 15, offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.amber,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.auto_awesome, size: 14, color: Colors.black),
                    SizedBox(width: 4),
                    Text('YOUR NEXT BEST STEP', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 10)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('${hero.confidenceScore}% Confidence', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(hero.skillName, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Why? ', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 12)),
                Expanded(
                  child: Text(hero.reason, style: const TextStyle(color: Colors.white, fontSize: 12.5, height: 1.35)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              if (hero.hasLearningPath) {
                Navigator.pushNamed(context, AppRoutes.learningHub);
              } else {
                Navigator.pushNamed(context, AppRoutes.explore);
              }
            },
            icon: const Icon(Icons.play_arrow_rounded, size: 18),
            label: const Text('Take Action Now'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyGoalCard(BuildContext context, DailyGoalModel goal) {
    final theme = Theme.of(context);
    final isUrgent = goal.priority == 'urgent';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppConstants.paddingM),
      decoration: BoxDecoration(
        color: isUrgent ? Colors.orange.shade50 : theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isUrgent ? Colors.orange.shade400 : theme.primaryColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(isUrgent ? Icons.warning_amber_rounded : Icons.track_changes_rounded, size: 18, color: isUrgent ? Colors.deepOrange : theme.primaryColor),
                  const SizedBox(width: 8),
                  Text(
                    'DAILY FOCUS',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isUrgent ? Colors.deepOrange : theme.primaryColor),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: Colors.amber.shade100, borderRadius: BorderRadius.circular(12)),
                child: Text('+${goal.rewardXp} XP', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.amber.shade900)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(goal.goalTitle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 4),
          Text(goal.description, style: TextStyle(fontSize: 12.5, color: Colors.grey.shade700)),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text('Why? ${goal.reason}', style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.grey.shade600), overflow: TextOverflow.ellipsis),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () => Navigator.pushNamed(context, AppRoutes.learningHub),
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6)),
                child: Text(goal.actionLabel),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAdaptiveCard(BuildContext context, AdaptiveRecommendationModel rec) {
    final theme = Theme.of(context);
    final isUrgent = rec.priority == 'urgent';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(AppConstants.paddingM),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isUrgent ? Colors.red.withValues(alpha: 0.4) : Colors.grey.withValues(alpha: 0.15)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isUrgent ? Colors.red.withValues(alpha: 0.1) : theme.primaryColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              rec.categoryType == 'REVIEW_TOPIC'
                  ? Icons.replay_rounded
                  : (rec.categoryType == 'PREPARE_CERTIFICATION' ? Icons.workspace_premium : Icons.play_arrow_rounded),
              size: 20,
              color: isUrgent ? Colors.red : theme.primaryColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(rec.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 3),
                Text(rec.subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Signal: ${rec.sourceSignal}', style: TextStyle(fontSize: 10.5, color: Colors.grey.shade500)),
                    ElevatedButton(
                      onPressed: () {
                        if (rec.actionType == 'practice' || rec.actionType == 'learning') {
                          Navigator.pushNamed(context, AppRoutes.learningHub);
                        } else if (rec.actionType == 'certificate') {
                          Navigator.pushNamed(context, AppRoutes.certificates);
                        } else {
                          Navigator.pushNamed(context, AppRoutes.explore);
                        }
                      },
                      style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      child: Text(rec.actionLabel),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiagnosticCard(BuildContext context, PracticeDiagnosticModel diag) {
    final isHigh = diag.severity == 'high';
    final cardColor = isHigh ? Colors.red.shade50 : Colors.amber.shade50;
    final borderColor = isHigh ? Colors.red.shade300 : Colors.amber.shade300;
    final iconColor = isHigh ? Colors.red.shade700 : Colors.amber.shade800;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(AppConstants.paddingM),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_rounded, color: iconColor, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(diag.message, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey.shade900)),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Last Score: ${diag.lastScore}%', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: iconColor)),
                    InkWell(
                      onTap: () => Navigator.pushNamed(context, AppRoutes.learningHub),
                      child: Text('${diag.recommendation} →', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyInsightsSection(BuildContext context, WeeklyGrowthInsightsModel insights) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingM),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.calendar_view_week_rounded, size: 18, color: theme.primaryColor),
                  const SizedBox(width: 8),
                  const Text('Weekly Learning Velocity', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
                child: Text(insights.consistencyRating, style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 11)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildMetricTile(context, 'Study Time', '${(insights.timeSpentMinutesWeek / 60.0).toStringAsFixed(1)} hrs', Icons.schedule_rounded, Colors.blue),
              _buildMetricTile(context, 'XP Earned', '+${insights.xpGainedWeek}', Icons.auto_awesome_rounded, Colors.purple),
              _buildMetricTile(context, 'Accuracy', '${insights.averageAccuracyWeek.toStringAsFixed(0)}%', Icons.check_circle_outline, Colors.teal),
              _buildMetricTile(context, 'Quizzes', '${insights.practiceAttemptsWeek}', Icons.quiz_outlined, Colors.indigo),
            ],
          ),
          if (insights.highlights.isNotEmpty) ...[
            const Divider(height: 18),
            ...insights.highlights.map((h) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  const Icon(Icons.arrow_right_rounded, size: 16, color: Colors.grey),
                  Expanded(
                    child: Text(h, style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                  ),
                ],
              ),
            )),
          ],
        ],
      ),
    );
  }

  Widget _buildMetricTile(BuildContext context, String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: color)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 9.5, color: Colors.grey), overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }

  Widget _buildSkillGrowthCard(BuildContext context, SkillGrowthModel growth) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingM),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Mastery Index', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  Text('${growth.masteryIndex} / 100', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: theme.primaryColor)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                child: Text('${growth.totalPracticeAttempts} Quizzes Taken', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blue)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: (growth.masteryIndex / 100.0).clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: Colors.grey.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation<Color>(theme.primaryColor),
            ),
          ),
          const SizedBox(height: 10),
          Text(growth.growthNarrative, style: TextStyle(fontSize: 12, color: Colors.grey.shade700, fontStyle: FontStyle.italic)),
        ],
      ),
    );
  }

  Widget _buildExchangeCard(BuildContext context, ExchangeSuggestionModel ex) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(AppConstants.paddingM),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ex.isTwoWaySwap ? Colors.teal.withValues(alpha: 0.4) : Colors.grey.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CustomAvatar(radius: 18, imageUrl: ex.peerAvatar, name: ex.peerName),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(ex.peerName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded, color: Colors.amber, size: 14),
                        Text(' ${ex.peerRating.toStringAsFixed(1)}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        const SizedBox(width: 6),
                        Text('(${ex.peerReviews} reviews)', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.teal.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.teal.shade300),
                ),
                child: Text(
                  ex.isTwoWaySwap ? '2-Way Swap' : 'Exchange Match',
                  style: TextStyle(color: Colors.teal.shade800, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(ex.explanation, style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ElevatedButton.icon(
                onPressed: () => Navigator.pushNamed(context, AppRoutes.explore),
                icon: const Icon(Icons.handshake_outlined, size: 14),
                label: const Text('Connect & Swap'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRoadmapTimeline(BuildContext context, List<RoadmapStepModel> steps) {
    if (steps.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('No roadmap steps available yet.'),
        ),
      );
    }

    return Column(
      children: steps.map((step) {
        final isCompleted = step.status == 'completed';
        final isInProgress = step.status == 'in_progress';
        final isRecommended = step.status == 'recommended_next';

        Color statusColor = Colors.grey;
        IconData statusIcon = Icons.lock_outline_rounded;
        if (isCompleted) {
          statusColor = Colors.green;
          statusIcon = Icons.check_circle_rounded;
        } else if (isInProgress) {
          statusColor = Theme.of(context).primaryColor;
          statusIcon = Icons.play_circle_rounded;
        } else if (isRecommended) {
          statusColor = Colors.amber.shade700;
          statusIcon = Icons.star_rounded;
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isInProgress || isRecommended ? statusColor.withValues(alpha: 0.4) : Colors.grey.withValues(alpha: 0.15),
              width: isInProgress ? 1.5 : 1.0,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(statusIcon, color: statusColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('Step ${step.stepNumber}: ', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
                        Expanded(
                          child: Text(step.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(step.subtitle, style: TextStyle(fontSize: 11, color: Colors.grey.shade600), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(step.badge, style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_skill_exchange/screens/home_screen.dart';
import 'package:local_skill_exchange/models/auth_models.dart';
import 'package:local_skill_exchange/models/wallet_model.dart';
import 'package:local_skill_exchange/models/gamification_models.dart';
import 'package:local_skill_exchange/models/ai_coach_models.dart';
import 'package:local_skill_exchange/models/skill_model.dart';
import 'package:local_skill_exchange/providers/auth_provider.dart';
import 'package:local_skill_exchange/providers/wallet_provider.dart';
import 'package:local_skill_exchange/providers/gamification_provider.dart';
import 'package:local_skill_exchange/providers/ai_coach_provider.dart';
import 'package:local_skill_exchange/providers/booking_provider.dart';
import 'package:local_skill_exchange/providers/skill_provider.dart';
import 'package:local_skill_exchange/providers/community_provider.dart';
import 'package:local_skill_exchange/providers/learning/learning_providers.dart';
import 'package:local_skill_exchange/providers/user_provider.dart';
import 'package:local_skill_exchange/widgets/home/recommended_skills_section.dart';

void main() {
  testWidgets('HomeScreen renders personalized dashboard components', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final testUser = User(
      id: '1',
      email: 'student@example.com',
      name: 'Alice Learner',
    );

    final mockGamification = GamificationDashboardModel.fromJson({
      'level_info': {
        'level': 2,
        'current_xp': 350,
        'next_level_xp': 500,
        'current_level_min_xp': 200,
        'level_progress_percent': 50.0,
      },
      'streak_info': {
        'current_streak': 5,
        'longest_streak': 10,
      },
      'learning_stats': {
        'total_paths_available': 10,
        'paths_started': 3,
        'paths_completed': 1,
        'lessons_completed': 8,
        'practice_attempts': 12,
        'practice_pass_rate': 90.0,
        'certificates_earned': 1,
        'completed_exchanges': 2,
      },
      'unlocked_achievements_count': 3,
      'total_achievements_count': 15,
      'recent_achievements': [],
      'recent_milestones': [],
    });

    final mockCoachSummary = AiCoachSummaryModel.fromJson({
      'user_id': 1,
      'user_name': 'Alice Learner',
      'user_xp': 350,
      'streak_days': 5,
      'hero_recommendation': {
        'skill_id': 1,
        'skill_name': 'Python Data Structures',
        'category': 'Programming & Technology',
        'gap_level': 'High',
        'reason': 'Essential for completing your software engineering track.',
        'confidence_score': 95,
        'has_learning_path': true,
        'available_mentors_count': 3,
      },
      'daily_goal': {
        'goal_title': 'Daily Practice Routine',
        'description': 'Complete 1 interactive lesson and score 80% on practice quiz.',
        'reason': 'Maintain daily consistency',
        'priority': 'high',
        'action_label': 'Start',
        'action_type': 'learn',
        'target_id': 1,
        'is_completed': true,
        'streak_days': 5,
        'reward_xp': 25,
      },
    });

    final mockDailyGoal = DailyGoalModel.fromJson({
      'goal_title': 'Daily Practice Routine',
      'description': 'Complete 1 interactive lesson and score 80% on practice quiz.',
      'reason': 'Maintain daily consistency',
      'priority': 'high',
      'action_label': 'Start',
      'action_type': 'learn',
      'target_id': 1,
      'is_completed': true,
      'streak_days': 5,
      'reward_xp': 25,
    });

    final mockWeeklyInsights = WeeklyGrowthInsightsModel.fromJson({
      'user_id': 1,
      'week_start': '2026-09-22',
      'week_end': '2026-09-29',
      'xp_gained_week': 120,
      'practice_attempts_week': 4,
      'average_accuracy_week': 88.0,
      'certificates_earned_week': 1,
      'exchanges_completed_week': 2,
      'streak_days': 5,
      'consistency_rating': 'Consistent Learner',
      'highlights': ['Completed 4 practice attempts'],
      'has_sufficient_history': true,
    });

    final mockWallet = WalletState(
      wallet: WalletModel.fromJson({
        'wallet_id': 1,
        'user_id': 1,
        'balance': 150,
        'total_credits_earned': 200,
        'total_credits_spent': 50,
        'pending_credits': 0,
        'teaching_sessions_count': 2,
        'learning_sessions_count': 1,
        'created_at': '2026-01-01',
        'updated_at': '2026-09-29',
      }),
      transactions: [],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith((ref) => _SimpleAuthNotifier(testUser)),
          gamificationDashboardProvider.overrideWith((ref) async => mockGamification),
          aiCoachSummaryProvider.overrideWith((ref) async => mockCoachSummary),
          aiCoachDailyGoalProvider.overrideWith((ref) async => mockDailyGoal),
          aiCoachWeeklyInsightsProvider.overrideWith((ref) async => mockWeeklyInsights),
          walletNotifierProvider.overrideWith(() => _MockWalletNotifier(mockWallet)),
          upcomingBookingsProvider.overrideWith((ref) async => []),
          aiRecommendationsProvider.overrideWith((ref) async => []),
          skillsNotifierProvider.overrideWith(() => _MockSkillsNotifier()),
          communityActivityProvider.overrideWith((ref) async => []),
          userProgressProvider.overrideWith((ref) async => []),
          nearbyUsersProvider.overrideWith((ref) async => []),
        ],
        child: const MaterialApp(
          home: HomeScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify Greeting & Hero Section
    expect(find.textContaining('Alice'), findsWidgets);
    expect(find.text('5d Streak'), findsWidgets);
    expect(find.text('150 Credits'), findsWidgets);
    expect(find.text('Lvl 2 • 350 XP'), findsWidgets);

    // Verify Cards
    expect(find.text("TODAY'S AI LEARNING PLAN"), findsWidgets);
    expect(find.text('YOUR NEXT BEST STEP'), findsWidgets);
    expect(find.text('UPCOMING SESSION'), findsWidgets);
    expect(find.text('CREDIT BALANCE & ACTIVITY'), findsWidgets);
    expect(find.text('WEEKLY LEARNING ACTIVITY'), findsWidgets);
    expect(find.text('GAMIFICATION & MILESTONES'), findsWidgets);
  });
}

class _SimpleAuthNotifier extends StateNotifier<User?> implements AuthNotifier {
  _SimpleAuthNotifier(super.state);

  @override
  Future<void> login(String email, String password) async {}

  @override
  Future<void> register(String name, String email, String password) async {}

  @override
  Future<void> refreshUser() async {}

  @override
  Future<void> loginAsGuest() async {}

  @override
  Future<void> loginWithGoogle({
    required String idToken,
    String? accessToken,
    String? email,
    String? name,
    String? avatarUrl,
  }) async {}

  @override
  Future<void> logout() async {
    state = null;
  }
}

class _MockWalletNotifier extends WalletNotifier {
  final WalletState _mockState;
  _MockWalletNotifier(this._mockState);

  @override
  Future<WalletState> build() async => _mockState;

  @override
  Future<void> refreshWallet() async {}
}

class _MockSkillsNotifier extends SkillsNotifier {
  @override
  Future<List<SkillModel>> build() async => [];

  @override
  Future<void> refresh() async {}
}

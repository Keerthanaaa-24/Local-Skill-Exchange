import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/custom_avatar.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/wallet_provider.dart';
import '../../providers/gamification_provider.dart';
import '../../providers/ai_coach_provider.dart';
import '../../routes/app_routes.dart';

class PersonalizedHero extends ConsumerWidget {
  const PersonalizedHero({super.key});

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider);
    final unreadCount = ref.watch(unreadNotificationCountProvider);
    final walletAsync = ref.watch(walletNotifierProvider);
    final gamificationAsync = ref.watch(gamificationDashboardProvider);
    final coachAsync = ref.watch(aiCoachSummaryProvider);

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final greeting = _greeting();
    final greetingName = (user != null && user.name.trim().isNotEmpty)
        ? user.name.trim().split(' ').first
        : 'Learner';

    final credits = walletAsync.valueOrNull?.wallet.balance ?? 0;
    final level = gamificationAsync.valueOrNull?.levelInfo.level ?? 1;
    final xp = gamificationAsync.valueOrNull?.levelInfo.currentXp ?? 0;
    final streak = gamificationAsync.valueOrNull?.streakInfo.currentStreak ?? 0;
    final goalPercent = coachAsync.valueOrNull?.dailyGoal?.isCompleted == true ? 100 : 45;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppConstants.paddingL),
      padding: const EdgeInsets.all(AppConstants.paddingL),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [
                  theme.colorScheme.surface,
                  theme.colorScheme.surfaceContainerHighest,
                ]
              : [
                  theme.primaryColor.withValues(alpha: 0.08),
                  Colors.indigo.shade50.withValues(alpha: 0.6),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.primaryColor.withValues(alpha: isDark ? 0.25 : 0.15),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (user?.isGuest == true)
            Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.amber.shade700.withValues(alpha: 0.35)),
              ),
              child: Row(
                children: [
                  Icon(Icons.visibility_rounded, color: Colors.amber.shade800, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Guest Mode — Browse Only',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.amber.shade300 : Colors.amber.shade900,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, AppRoutes.login);
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text('Sign In', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ],
              ),
            ),
          // Top Row: User Avatar, Greeting, Notifications & Wallet
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomAvatar(
                radius: 24,
                imageUrl: user?.profileImageUrl,
                name: user?.name ?? 'User',
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$greeting, $greetingName 👋',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 19,
                        letterSpacing: -0.3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Continue your learning journey and build your skills.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: isDark ? Colors.grey.shade400 : AppColors.textSecondaryLight,
                        fontSize: 13,
                        height: 1.25,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.account_balance_wallet_rounded,
                      color: theme.primaryColor,
                      size: 22,
                    ),
                    tooltip: 'Wallet & Credits',
                    onPressed: () => Navigator.pushNamed(context, AppRoutes.wallet),
                  ),
                  Stack(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.notifications_none_rounded, size: 24),
                        tooltip: 'Notifications',
                        onPressed: () => Navigator.pushNamed(context, AppRoutes.notifications),
                      ),
                      if (unreadCount > 0)
                        Positioned(
                          right: 8,
                          top: 8,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.redAccent,
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                            child: Text(
                              unreadCount > 9 ? '9+' : unreadCount.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Dynamic Stats Row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // Streak Pill
                _buildStatPill(
                  context,
                  icon: Icons.local_fire_department_rounded,
                  iconColor: Colors.deepOrange,
                  bgColor: Colors.deepOrange.withValues(alpha: isDark ? 0.2 : 0.1),
                  label: '${streak}d Streak',
                  onTap: () => Navigator.pushNamed(context, AppRoutes.leaderboard),
                ),
                const SizedBox(width: 8),
                // Credits Pill
                _buildStatPill(
                  context,
                  icon: Icons.bolt_rounded,
                  iconColor: Colors.amber.shade700,
                  bgColor: Colors.amber.withValues(alpha: isDark ? 0.2 : 0.1),
                  label: '$credits Credits',
                  onTap: () => Navigator.pushNamed(context, AppRoutes.wallet),
                ),
                const SizedBox(width: 8),
                // Level & XP Pill
                _buildStatPill(
                  context,
                  icon: Icons.military_tech_rounded,
                  iconColor: theme.primaryColor,
                  bgColor: theme.primaryColor.withValues(alpha: isDark ? 0.2 : 0.1),
                  label: 'Lvl $level • $xp XP',
                  onTap: () => Navigator.pushNamed(context, AppRoutes.leaderboard),
                ),
                const SizedBox(width: 8),
                // Goal Progress Pill
                _buildStatPill(
                  context,
                  icon: Icons.track_changes_rounded,
                  iconColor: Colors.teal,
                  bgColor: Colors.teal.withValues(alpha: isDark ? 0.2 : 0.1),
                  label: '$goalPercent% Daily Goal',
                  onTap: () => Navigator.pushNamed(context, AppRoutes.learningHub),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatPill(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: iconColor.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: iconColor),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: iconColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

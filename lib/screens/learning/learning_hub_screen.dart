import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../repositories/learning_repository.dart';
import '../../core/widgets/loading_state.dart';
import '../../core/widgets/error_state.dart';
import '../../models/skill_model.dart';
import '../../models/learning_path_model.dart';
import '../../providers/learning/learning_providers.dart';
import '../../providers/certificate/certificate_providers.dart';
import '../../providers/gamification_provider.dart';
import '../../repositories/skill_repository.dart';
import '../../routes/app_routes.dart';

// Provider for fetching all skills (unchanged)
final allSkillsProvider = FutureProvider.autoDispose<List<SkillModel>>((ref) async {
  final repo = ref.watch(skillRepositoryProvider);
  return await repo.getSkills();
});

class LearningHubScreen extends ConsumerWidget {
  const LearningHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {

    final allSkillsAsync = ref.watch(allSkillsProvider);
    final progressListAsync = ref.watch(userProgressProvider);
    final certsAsync = ref.watch(userCertificatesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Learning'),
        backgroundColor: Theme.of(context).primaryColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.leaderboard_outlined),
            tooltip: 'Community Leaderboard',
            onPressed: () => Navigator.pushNamed(context, AppRoutes.leaderboard),
          ),
          IconButton(
            icon: const Icon(Icons.workspace_premium_outlined),
            tooltip: 'My Certificates',
            onPressed: () => Navigator.pushNamed(context, AppRoutes.certificates),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(gamificationDashboardProvider);
          ref.invalidate(userProgressProvider);
          ref.invalidate(userCertificatesProvider);
          ref.invalidate(allSkillsProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppConstants.paddingL),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Gamification Progress Dashboard
              _buildGamificationDashboard(context, ref),
              const SizedBox(height: AppConstants.paddingL),
              // CONTINUE LEARNING
              _sectionHeader('Continue Learning'),
            progressListAsync.when(
              loading: () => const LoadingSkeletonCard(),
              error: (err, stack) => ErrorStateWidget(error: err, onRetry: () => ref.refresh(userProgressProvider)),
              data: (progressList) {
                final inProgress = progressList.where((p) => p.completedAt == null).toList();
                if (inProgress.isEmpty) return _placeholderCard('Start learning by exploring skills.');
                final prog = inProgress.first;
                return FutureBuilder<LearningPathModel>(
                  future: ref.read(learningRepositoryProvider).getLearningPathById(prog.learningPathId),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const LoadingSkeletonCard();
                    final path = snapshot.data!;
                    final total = path.lessons.length;
                    final completed = prog.completedLessons.length;
                    final percent = total == 0 ? 0 : (completed / total * 100).round();
                    return Card(
                      child: ListTile(
                        title: Text('Continue ${path.title}'),
                        subtitle: Text('$percent% completed'),
                        trailing: const Icon(Icons.arrow_forward),
                        onTap: () => Navigator.pushNamed(context, AppRoutes.skillLearning, arguments: SkillModel(id: path.skillId, title: path.title, description: path.description ?? '', ownerId: 0, ownerName: '', credits: 0, rating: 0, reviewCount: 0, isAvailable: true)),
                      ),
                    );
                  },
                );
              },
            ),
            const SizedBox(height: AppConstants.paddingL),
            // MY LEARNING (in‑progress list)
            _sectionHeader('My Learning'),
            progressListAsync.when(
              loading: () => const LoadingSkeletonCard(),
              error: (err, stack) => ErrorStateWidget(error: err, onRetry: () => ref.refresh(userProgressProvider)),
              data: (progressList) {
                final inProgress = progressList.where((p) => p.completedAt == null).toList();
                if (inProgress.isEmpty) return _placeholderCard('No active learning paths.');
                return Column(
                  children: inProgress.map((prog) {
                    return FutureBuilder<LearningPathModel>(
                      future: ref.read(learningRepositoryProvider).getLearningPathById(prog.learningPathId),
                      builder: (context, snap) {
                        if (!snap.hasData) return const SizedBox();
                        final path = snap.data!;
                        final total = path.lessons.length;
                        final completed = prog.completedLessons.length;
                        final percent = total == 0 ? 0 : (completed / total * 100).round();
                        return Card(
                          child: ListTile(
                            title: Text(path.title),
                            subtitle: Text('$percent% completed'),
                            trailing: const Icon(Icons.arrow_forward),
                            onTap: () => Navigator.pushNamed(context, AppRoutes.skillLearning, arguments: SkillModel(id: path.skillId, title: path.title, description: path.description ?? '', ownerId: 0, ownerName: '', credits: 0, rating: 0, reviewCount: 0, isAvailable: true)),
                          ),
                        );
                      },
                    );
                  }).toList(),
                );
              },
            ),
            const SizedBox(height: AppConstants.paddingL),
            // COMPLETED
            _sectionHeader('Completed'),
            progressListAsync.when(
              loading: () => const LoadingSkeletonCard(),
              error: (err, stack) => ErrorStateWidget(error: err, onRetry: () => ref.refresh(userProgressProvider)),
              data: (progressList) {
                final completed = progressList.where((p) => p.completedAt != null).toList();
                if (completed.isEmpty) return _placeholderCard('No completed learning paths.');
                return Column(
                  children: completed.map((prog) {
                    return FutureBuilder<LearningPathModel>(
                      future: ref.read(learningRepositoryProvider).getLearningPathById(prog.learningPathId),
                      builder: (context, snap) {
                        if (!snap.hasData) return const SizedBox();
                        final path = snap.data!;
                        final certAsync = ref.watch(certificateForPathProvider(path.id));
                        return Card(
                          child: ListTile(
                            leading: const Icon(Icons.check_circle, color: Colors.green),
                            title: Text(path.title),
                            subtitle: const Text('100% completed'),
                            trailing: certAsync.maybeWhen(
                              data: (cert) => cert != null
                                  ? OutlinedButton.icon(
                                      icon: const Icon(Icons.workspace_premium, size: 16, color: Color(0xFFD4AF37)),
                                      label: const Text('Certificate'),
                                      onPressed: () {
                                        Navigator.pushNamed(context, AppRoutes.certificateDetail, arguments: cert);
                                      },
                                    )
                                  : ElevatedButton.icon(
                                      icon: const Icon(Icons.verified, size: 16),
                                      label: const Text('Claim'),
                                      onPressed: () async {
                                        final newCert = await ref.read(issueCertificateProvider.notifier).issue(path.id);
                                        if (context.mounted && newCert != null) {
                                          Navigator.pushNamed(context, AppRoutes.certificateDetail, arguments: newCert);
                                        }
                                      },
                                    ),
                              orElse: () => null,
                            ),
                          ),
                        );
                      },
                    );
                  }).toList(),
                );
              },
            ),
            const SizedBox(height: AppConstants.paddingL),
            // EXPLORE SKILLS (unchanged)
            _sectionHeader('Explore Skills'),
            allSkillsAsync.when(
              loading: () => const LoadingSkeletonCard(),
              error: (err, stack) => ErrorStateWidget(error: err, onRetry: () => ref.refresh(allSkillsProvider)),
              data: (skills) => _exploreGrid(context, skills),
            ),
            const SizedBox(height: AppConstants.paddingL),
            // CERTIFICATIONS
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _sectionHeader('Certifications'),
                TextButton.icon(
                  icon: const Icon(Icons.shield_outlined, size: 16),
                  label: const Text('Verify Code'),
                  onPressed: () => Navigator.pushNamed(context, AppRoutes.verifyCertificate),
                ),
              ],
            ),
            certsAsync.when(
              loading: () => const LoadingSkeletonCard(),
              error: (err, stack) => ErrorStateWidget(error: err, onRetry: () => ref.refresh(userCertificatesProvider)),
              data: (certificates) {
                if (certificates.isEmpty) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppConstants.paddingL),
                      child: Column(
                        children: [
                          const Icon(Icons.workspace_premium_outlined, size: 40, color: Colors.grey),
                          const SizedBox(height: 8),
                          const Text(
                            'No certificates earned yet.\nComplete 100% of lessons in any learning path to earn verified certificates.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey),
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton(
                            onPressed: () => Navigator.pushNamed(context, AppRoutes.verifyCertificate),
                            child: const Text('Verify Any Certificate Code'),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return Column(
                  children: [
                    ...certificates.map((cert) => Card(
                          child: ListTile(
                            leading: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFFFFF8E1),
                                border: Border.all(color: const Color(0xFFD4AF37)),
                              ),
                              child: const Icon(Icons.workspace_premium, color: Color(0xFFD4AF37), size: 24),
                            ),
                            title: Text(cert.learningPathTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('ID: ${cert.certificateNumber}'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => Navigator.pushNamed(context, AppRoutes.certificateDetail, arguments: cert),
                          ),
                        )),
                    const SizedBox(height: 8),
                    Center(
                      child: TextButton(
                        onPressed: () => Navigator.pushNamed(context, AppRoutes.certificates),
                        child: const Text('View All My Certificates'),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    ),
  );
}

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppConstants.paddingS),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _exploreGrid(BuildContext context, List<SkillModel> skills) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: skills.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: MediaQuery.of(context).size.width > 800
            ? 4
            : MediaQuery.of(context).size.width > 600
                ? 3
                : 2,
        mainAxisSpacing: AppConstants.paddingS,
        crossAxisSpacing: AppConstants.paddingS,
        childAspectRatio: 3 / 4,
      ),
      itemBuilder: (context, index) {
        final skill = skills[index];
        return GestureDetector(
          onTap: () => Navigator.pushNamed(context, AppRoutes.skillLearning, arguments: skill),
          child: Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                    child: Container(
                  color: Theme.of(context).primaryColorLight,
                  child: skill.imageUrl != null ? Image.network(skill.imageUrl!, fit: BoxFit.cover) : const Center(child: Icon(Icons.school)),
                )),
                Padding(
                  padding: const EdgeInsets.all(AppConstants.paddingS),
                  child: Text(
                    skill.title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _placeholderCard(String message) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingL),
        child: Center(child: Text(message)),
      ),
    );
  }

  // ==========================================
  // GAMIFICATION DASHBOARD (PHASE J)
  // ==========================================
  Widget _buildGamificationDashboard(BuildContext context, WidgetRef ref) {
    final dashAsync = ref.watch(gamificationDashboardProvider);

    return dashAsync.when(
      data: (dash) {
        final lvl = dash.levelInfo;
        final streak = dash.streakInfo;
        final stats = dash.learningStats;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Level & Streak Banner
            Container(
              padding: const EdgeInsets.all(AppConstants.paddingM),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E3C72), Color(0xFF2A5298)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(AppConstants.radiusM),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1E3C72).withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.amber,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.star_rounded, color: Colors.black, size: 16),
                                const SizedBox(width: 4),
                                Text(
                                  'Level ${lvl.level}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            '${lvl.currentXp} XP',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.local_fire_department_rounded, color: Colors.deepOrangeAccent, size: 18),
                            const SizedBox(width: 4),
                            Text(
                              '${streak.currentStreak} Day Streak',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: lvl.levelProgressPercent / 100.0,
                      minHeight: 6,
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Progress to Level ${lvl.level + 1}',
                        style: const TextStyle(color: Colors.white70, fontSize: 11),
                      ),
                      Text(
                        '${lvl.currentXp} / ${lvl.nextLevelXp} XP (${lvl.levelProgressPercent.toStringAsFixed(0)}%)',
                        style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppConstants.paddingM),

            // Metrics Grid
            Row(
              children: [
                Expanded(child: _buildMetricTile(context, '${stats.pathsStarted}', 'Paths Started', Icons.explore_rounded, Colors.blue)),
                const SizedBox(width: 8),
                Expanded(child: _buildMetricTile(context, '${stats.lessonsCompleted}', 'Lessons Done', Icons.menu_book_rounded, Colors.green)),
                const SizedBox(width: 8),
                Expanded(child: _buildMetricTile(context, '${stats.practicePassRate.toStringAsFixed(0)}%', 'Pass Rate', Icons.quiz_rounded, Colors.purple)),
                const SizedBox(width: 8),
                Expanded(child: _buildMetricTile(context, '${stats.certificatesEarned}', 'Certificates', Icons.workspace_premium_rounded, const Color(0xFFD4AF37))),
              ],
            ),
            const SizedBox(height: AppConstants.paddingM),

            // Achievements Bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.emoji_events_rounded, color: Colors.amber, size: 20),
                    const SizedBox(width: 6),
                    Text(
                      'Achievements (${dash.unlockedAchievementsCount}/${dash.totalAchievementsCount})',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ],
                ),
                TextButton.icon(
                  onPressed: () => Navigator.pushNamed(context, AppRoutes.leaderboard),
                  icon: const Icon(Icons.leaderboard_outlined, size: 16),
                  label: const Text('Leaderboard', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 6),
            SizedBox(
              height: 90,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: dash.recentAchievements.length,
                itemBuilder: (context, idx) {
                  final ach = dash.recentAchievements[idx];
                  return Container(
                    width: 130,
                    margin: const EdgeInsets.only(right: 10),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: ach.isUnlocked
                          ? Theme.of(context).cardTheme.color
                          : Colors.grey.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(AppConstants.radiusM),
                      border: Border.all(
                        color: ach.isUnlocked ? Colors.amber.withValues(alpha: 0.6) : Colors.grey.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _getAchievementIcon(ach.icon),
                          color: ach.isUnlocked ? Colors.amber : Colors.grey,
                          size: 24,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          ach.title,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                            color: ach.isUnlocked ? null : Colors.grey,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          ach.isUnlocked ? 'Unlocked' : 'Locked',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: ach.isUnlocked ? Colors.green : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
      loading: () => const LoadingSkeletonCard(height: 180),
      error: (e, _) => const SizedBox.shrink(),
    );
  }

  Widget _buildMetricTile(BuildContext context, String value, String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey), textAlign: TextAlign.center, maxLines: 1),
        ],
      ),
    );
  }

  IconData _getAchievementIcon(String iconName) {
    switch (iconName) {
      case 'explore':
        return Icons.explore_rounded;
      case 'menu_book':
        return Icons.menu_book_rounded;
      case 'quiz':
        return Icons.quiz_rounded;
      case 'workspace_premium':
        return Icons.workspace_premium_rounded;
      case 'hub':
        return Icons.hub_rounded;
      case 'volunteer_activism':
        return Icons.volunteer_activism_rounded;
      case 'local_fire_department':
        return Icons.local_fire_department_rounded;
      default:
        return Icons.emoji_events_rounded;
    }
  }
}


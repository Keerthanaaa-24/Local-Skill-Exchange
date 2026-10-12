import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/loading_state.dart';
import '../../core/widgets/error_state.dart';
import '../../core/widgets/custom_avatar.dart';
import '../../models/skill_passport_model.dart';
import '../../models/certificate_model.dart';
import '../../providers/passport/passport_provider.dart';
import '../../providers/gamification_provider.dart';
import '../../routes/app_routes.dart';

class SkillPassportScreen extends ConsumerWidget {
  final int? userId;

  const SkillPassportScreen({super.key, this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isMyPassport = userId == null;
    final passportAsync = isMyPassport
        ? ref.watch(myPassportProvider)
        : ref.watch(userPassportProvider(userId!));

    return Scaffold(
      appBar: AppBar(
        title: Text(isMyPassport ? 'My Skill Passport' : 'Skill Passport'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: 'Share Passport',
            onPressed: () {
              passportAsync.whenData((passport) {
                final text = 'Skill Passport for ${passport.profile.name}\n'
                    'Skills: ${passport.skills.map((s) => "${s.skillName} (${s.level})").join(", ")}\n'
                    'Certificates: ${passport.certificates.length}\n'
                    'Rating: ${passport.exchangeSummary.averageRating} ★';
                Clipboard.setData(ClipboardData(text: text));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Passport summary copied to clipboard!')),
                );
              });
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          if (isMyPassport) {
            ref.invalidate(myPassportProvider);
          } else {
            ref.invalidate(userPassportProvider(userId!));
          }
        },
        child: passportAsync.when(
          loading: () => const Center(child: LoadingCircular()),
          error: (err, stack) => ErrorStateWidget(
            error: err,
            onRetry: () {
              if (isMyPassport) {
                ref.invalidate(myPassportProvider);
              } else {
                ref.invalidate(userPassportProvider(userId!));
              }
            },
          ),
          data: (passport) => _buildPassportBody(context, ref, passport),
        ),
      ),
    );
  }

  Widget _buildPassportBody(BuildContext context, WidgetRef ref, SkillPassportModel passport) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppConstants.paddingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Passport Header Card
          _buildHeaderCard(context, passport.profile),
          const SizedBox(height: AppConstants.paddingL),

          // 2. Learning Progress Section
          _buildSectionTitle(context, 'LEARNING PROGRESS', Icons.school_outlined),
          const SizedBox(height: AppConstants.paddingS),
          _buildLearningCard(context, passport.learningSummary),
          const SizedBox(height: AppConstants.paddingL),

          // 3. Skills Section
          _buildSectionTitle(context, 'MY SKILLS', Icons.psychology_outlined),
          const SizedBox(height: AppConstants.paddingS),
          _buildSkillsList(context, passport.skills),
          const SizedBox(height: AppConstants.paddingL),

          // 4. Certificates Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSectionTitle(context, 'CERTIFICATES', Icons.workspace_premium_outlined),
              if (passport.certificates.isNotEmpty)
                TextButton(
                  onPressed: () => Navigator.pushNamed(context, AppRoutes.certificates),
                  child: const Text('View All'),
                ),
            ],
          ),
          const SizedBox(height: AppConstants.paddingS),
          _buildCertificatesList(context, passport.certificates),
          const SizedBox(height: AppConstants.paddingL),

          // 5. Practice Performance Section
          _buildSectionTitle(context, 'PRACTICE PERFORMANCE', Icons.quiz_outlined),
          const SizedBox(height: AppConstants.paddingS),
          _buildPracticeCard(context, passport.practiceSummary),
          const SizedBox(height: AppConstants.paddingL),

          // 6. Skill Exchange Activity Section
          _buildSectionTitle(context, 'SKILL EXCHANGE ACTIVITY', Icons.swap_horiz_outlined),
          const SizedBox(height: AppConstants.paddingS),
          _buildExchangeCard(context, passport.exchangeSummary, passport.isPublicView),
          const SizedBox(height: AppConstants.paddingL),

          // 7. Earned Achievements Section
          _buildSectionTitle(context, 'EARNED ACHIEVEMENTS', Icons.emoji_events_outlined),
          const SizedBox(height: AppConstants.paddingS),
          _buildAchievementsSection(context, ref),
          const SizedBox(height: AppConstants.paddingL),

          // 8. Skill Growth Timeline Section
          _buildSectionTitle(context, 'SKILL GROWTH TIMELINE', Icons.timeline_rounded),
          const SizedBox(height: AppConstants.paddingS),
          _buildGrowthTimelineSection(context, ref, passport.profile.userId),
          const SizedBox(height: AppConstants.paddingXL),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Theme.of(context).primaryColor),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.1,
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderCard(BuildContext context, PassportProfileModel profile) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingL),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF0D47A1), // Deep Navy
            const Color(0xFF1976D2), // Blue
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppConstants.radiusL),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withValues(alpha: 0.25),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              CustomAvatar(
                radius: 36,
                imageUrl: profile.avatarUrl,
                name: profile.name,
              ),
              const SizedBox(width: AppConstants.paddingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      profile.title ?? 'Community Member',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                    if (profile.location != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.location_on, size: 14, color: Colors.amber.shade200),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              profile.location!,
                              style: TextStyle(fontSize: 11, color: Colors.amber.shade100),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.paddingM),
          const Divider(color: Colors.white24),
          const SizedBox(height: AppConstants.paddingS),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _headerStat('XP', '${profile.xp}', Icons.bolt, Colors.amber),
              _headerStat('Streak', '${profile.streakDays}d', Icons.local_fire_department, Colors.deepOrangeAccent),
              if (profile.credits != null)
                _headerStat('Credits', '${profile.credits}', Icons.account_balance_wallet, Colors.lightGreenAccent),
            ],
          ),
        ],
      ),
    );
  }

  Widget _headerStat(String label, String value, IconData icon, Color iconColor) {
    return Row(
      children: [
        Icon(icon, size: 18, color: iconColor),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10)),
          ],
        ),
      ],
    );
  }

  Widget _buildLearningCard(BuildContext context, PassportLearningSummaryModel summary) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.radiusM)),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Overall Progress', style: TextStyle(fontWeight: FontWeight.w600)),
                Text('${summary.overallProgress.round()}%', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: (summary.overallProgress / 100).clamp(0.0, 1.0),
                minHeight: 10,
                backgroundColor: Colors.grey.shade200,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: AppConstants.paddingM),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _metricItem('Completed Paths', '${summary.completedPaths}', Icons.check_circle_outline, Colors.green),
                _metricItem('Active Paths', '${summary.activePaths}', Icons.timelapse, Colors.blue),
                _metricItem('Lessons', '${summary.totalLessonsCompleted}/${summary.totalLessonsAvailable}', Icons.menu_book, Colors.orange),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkillsList(BuildContext context, List<PassportSkillModel> skills) {
    if (skills.isEmpty) {
      return _emptyCard('No skills added or practiced yet.');
    }

    return Column(
      children: skills.map((skill) {
        Color levelColor;
        switch (skill.level) {
          case 'Advanced':
            levelColor = const Color(0xFF6A1B9A); // Deep Purple
            break;
          case 'Intermediate':
            levelColor = AppColors.primary;
            break;
          default:
            levelColor = Colors.teal;
        }

        return Card(
          margin: const EdgeInsets.only(bottom: AppConstants.paddingS),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.radiusM)),
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.paddingM),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        skill.skillName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: levelColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: levelColor),
                      ),
                      child: Text(
                        skill.level,
                        style: TextStyle(color: levelColor, fontWeight: FontWeight.bold, fontSize: 11),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: (skill.learningProgress / 100).clamp(0.0, 1.0),
                          minHeight: 6,
                          backgroundColor: Colors.grey.shade200,
                          color: levelColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('${skill.learningProgress.round()}%', style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (skill.isCertified) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF8E1),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFD4AF37)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.workspace_premium, size: 13, color: Color(0xFFD4AF37)),
                            SizedBox(width: 3),
                            Text('Certified', style: TextStyle(fontSize: 10, color: Color(0xFF8D6E63), fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    if (skill.practiceAverage != null) ...[
                      Text(
                        'Practice Avg: ${skill.practiceAverage}%',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCertificatesList(BuildContext context, List<PassportCertificateModel> certificates) {
    if (certificates.isEmpty) {
      return _emptyCard('No certificates earned yet. Complete 100% of lessons in any learning path to earn verified certificates.');
    }

    final dateFormat = DateFormat('MMM d, yyyy');

    return Column(
      children: certificates.map((cert) {
        return Card(
          margin: const EdgeInsets.only(bottom: AppConstants.paddingS),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.radiusM)),
          child: ListTile(
            leading: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFFF8E1),
                border: Border.all(color: const Color(0xFFD4AF37)),
              ),
              child: const Icon(Icons.workspace_premium, color: Color(0xFFD4AF37), size: 26),
            ),
            title: Text(cert.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            subtitle: Text('ID: ${cert.certificateNumber} • ${dateFormat.format(cert.issuedAt)}', style: const TextStyle(fontSize: 11)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.pushNamed(
                context,
                AppRoutes.certificateDetail,
                arguments: CertificateModel(
                  id: cert.certificateId,
                  certificateNumber: cert.certificateNumber,
                  verificationCode: cert.verificationCode,
                  userId: 0,
                  learningPathId: 0,
                  skillId: cert.skillId,
                  title: cert.title,
                  issuedAt: cert.issuedAt,
                  completedAt: cert.issuedAt,
                  status: cert.status,
                  recipientName: '',
                  skillName: cert.skill,
                  learningPathTitle: cert.title,
                ),
              );
            },
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPracticeCard(BuildContext context, PassportPracticeSummaryModel practice) {
    if (practice.totalAttempts == 0) {
      return _emptyCard('No practice attempts yet.');
    }

    final passRate = practice.totalAttempts > 0
        ? ((practice.passedAttempts / practice.totalAttempts) * 100).round()
        : 0;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.radiusM)),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingM),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _metricItem('Average Score', '${practice.averageScore ?? 0}%', Icons.analytics_outlined, Colors.indigo),
            _metricItem('Passed / Attempts', '${practice.passedAttempts}/${practice.totalAttempts}', Icons.fact_check_outlined, Colors.green),
            _metricItem('Pass Rate', '$passRate%', Icons.trending_up, Colors.deepPurple),
          ],
        ),
      ),
    );
  }

  Widget _buildExchangeCard(BuildContext context, PassportExchangeSummaryModel exchange, bool isPublic) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.radiusM)),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingM),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _metricItem('Offered', '${exchange.skillsOfferedCount}', Icons.upload_outlined, Colors.blue),
                _metricItem('Requested', '${exchange.skillsRequestedCount}', Icons.download_outlined, Colors.orange),
                _metricItem('Exchanges', '${exchange.totalCompletedExchanges}', Icons.handshake_outlined, Colors.green),
              ],
            ),
            const SizedBox(height: AppConstants.paddingM),
            const Divider(),
            const SizedBox(height: AppConstants.paddingS),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _metricItem('Rating', '${exchange.averageRating} ★', Icons.star, Colors.amber),
                _metricItem('Reviews', '${exchange.totalReviews}', Icons.rate_review_outlined, Colors.purple),
                if (!isPublic && exchange.creditsEarned != null)
                  _metricItem('Earned', '+${exchange.creditsEarned}', Icons.monetization_on_outlined, Colors.teal),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _metricItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, size: 22, color: color),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }

  Widget _emptyCard(String message) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.radiusM)),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingL),
        child: Center(
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey, fontSize: 13),
          ),
        ),
      ),
    );
  }

  Widget _buildAchievementsSection(BuildContext context, WidgetRef ref) {
    final achievementsAsync = ref.watch(achievementsListProvider);

    return achievementsAsync.when(
      loading: () => const Card(child: Padding(padding: EdgeInsets.all(AppConstants.paddingM), child: Center(child: LoadingCircular()))),
      error: (err, stack) => _emptyCard('Unable to load achievements at the moment.'),
      data: (achievements) {
        final unlocked = achievements.where((a) => a.isUnlocked).toList();
        if (unlocked.isEmpty) {
          return _emptyCard('No achievements unlocked yet. Complete lessons and pass practice quizzes to unlock badges!');
        }

        return Column(
          children: unlocked.map((ach) {
            return Card(
              margin: const EdgeInsets.only(bottom: AppConstants.paddingS),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.radiusM)),
              child: ListTile(
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.amber.shade50,
                    border: Border.all(color: Colors.amber.shade400),
                  ),
                  child: Icon(_getAchievementIcon(ach.code), color: Colors.amber.shade800, size: 24),
                ),
                title: Text(ach.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                subtitle: Text(ach.description, style: const TextStyle(fontSize: 12)),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    ach.requirement,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.amber.shade900),
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildGrowthTimelineSection(BuildContext context, WidgetRef ref, int targetUserId) {
    final timelineAsync = ref.watch(growthTimelineProvider(targetUserId));

    return timelineAsync.when(
      loading: () => const Card(child: Padding(padding: EdgeInsets.all(AppConstants.paddingM), child: Center(child: LoadingCircular()))),
      error: (err, stack) => _emptyCard('Unable to load growth timeline.'),
      data: (milestones) {
        if (milestones.isEmpty) {
          return _emptyCard('No milestones recorded yet. Progress in learning paths and exchanges to populate your growth timeline.');
        }

        final dateFormat = DateFormat('MMM d, yyyy');

        return Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.radiusM)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingM, vertical: AppConstants.paddingM),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: milestones.length,
              separatorBuilder: (context, index) => const Divider(height: 16),
              itemBuilder: (context, index) {
                final item = milestones[index];
                final iconData = _getMilestoneIcon(item.milestoneType);
                final iconColor = _getMilestoneColor(item.milestoneType);

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: iconColor.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(iconData, size: 18, color: iconColor),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  item.title,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                              ),
                              if (item.badge != null)
                                Container(
                                  margin: const EdgeInsets.only(left: 6),
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.amber.shade300),
                                  ),
                                  child: Text(
                                    item.badge!,
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Colors.amber.shade900),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(item.description, style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                          const SizedBox(height: 4),
                          Text(
                            dateFormat.format(item.timestamp),
                            style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  IconData _getAchievementIcon(String badgeKey) {
    switch (badgeKey) {
      case 'first_step':
        return Icons.flag_rounded;
      case 'lesson_starter':
        return Icons.menu_book_rounded;
      case 'practice_ready':
        return Icons.quiz_rounded;
      case 'certified_learner':
        return Icons.workspace_premium_rounded;
      case 'skill_explorer':
        return Icons.explore_rounded;
      case 'community_teacher':
        return Icons.school_rounded;
      case 'learning_consistency':
        return Icons.local_fire_department_rounded;
      default:
        return Icons.emoji_events_rounded;
    }
  }

  IconData _getMilestoneIcon(String type) {
    switch (type) {
      case 'certificate':
        return Icons.workspace_premium_rounded;
      case 'exchange':
        return Icons.handshake_rounded;
      case 'achievement':
        return Icons.emoji_events_rounded;
      case 'practice':
        return Icons.fact_check_rounded;
      case 'path_completed':
        return Icons.check_circle_rounded;
      case 'lesson_completed':
        return Icons.menu_book_rounded;
      default:
        return Icons.stars_rounded;
    }
  }

  Color _getMilestoneColor(String type) {
    switch (type) {
      case 'certificate':
        return Colors.amber.shade700;
      case 'exchange':
        return Colors.green.shade600;
      case 'achievement':
        return Colors.purple.shade600;
      case 'practice':
        return Colors.blue.shade600;
      case 'path_completed':
        return Colors.teal.shade600;
      case 'lesson_completed':
        return AppColors.primary;
      default:
        return Colors.grey.shade600;
    }
  }
}

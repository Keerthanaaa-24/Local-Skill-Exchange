import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/widgets/loading_state.dart';
import '../../core/widgets/error_state.dart';
import '../../models/skill_model.dart';
import '../../models/lesson_model.dart';
import '../../providers/learning/learning_providers.dart';
import '../../providers/certificate/certificate_providers.dart';
import '../../routes/app_routes.dart';

class SkillLearningScreen extends ConsumerWidget {
  final SkillModel skill;

  const SkillLearningScreen({required this.skill, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Dynamic path lookup/generation for any skill in the catalog
    final pathAsync = ref.watch(pathForSkillProvider(skill.id));

    return Scaffold(
      appBar: AppBar(
        title: Text(skill.title),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: pathAsync.when(
        loading: () => const Center(
          child: Padding(
            padding: EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text(
                  'Preparing Personalized Curriculum & Resources...',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
        error: (err, stack) => ErrorStateWidget(
          error: err,
          onRetry: () => ref.refresh(pathForSkillProvider(skill.id)),
        ),
        data: (path) {
          final lessonsAsync = ref.watch(lessonsProvider(path.id));
          final progressAsync = ref.watch(progressForPathProvider(path.id));

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppConstants.paddingL),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Banner Card
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppConstants.paddingL),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).primaryColor.withOpacity(0.08),
                          Theme.of(context).primaryColor.withOpacity(0.02),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Theme.of(context).primaryColor,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                (skill.categoryName != null && skill.categoryName!.isNotEmpty)
                                    ? skill.categoryName!
                                    : 'General',
                                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const Spacer(),
                            const Icon(Icons.school, size: 20, color: Colors.blueAccent),
                            const SizedBox(width: 4),
                            Text(
                              '${path.estimatedMinutes ?? 120} min',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          path.title,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        if (path.description != null)
                          Text(
                            path.description!,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade800),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppConstants.paddingL),

                // Progress card
                progressAsync.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (e, s) => const SizedBox(),
                  data: (progress) {
                    final lessons = lessonsAsync.maybeWhen(data: (l) => l, orElse: () => <LessonModel>[]);
                    int total = lessons.isNotEmpty ? lessons.length : path.lessons.length;
                    int completed = progress?.completedLessons.length ?? 0;
                    double percent = total == 0 ? 0 : (completed / total).clamp(0.0, 1.0);

                    return Card(
                      elevation: 1,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Your Learning Progress',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                ),
                                Text(
                                  '$completed of $total lessons (${(percent * 100).round()}%)',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: percent == 1.0 ? Colors.green.shade700 : Theme.of(context).primaryColor,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: LinearProgressIndicator(
                                value: percent,
                                minHeight: 8,
                                backgroundColor: Colors.grey.shade200,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  percent == 1.0 ? Colors.green : Theme.of(context).primaryColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: AppConstants.paddingL),

                // Primary Start / Continue Action
                Consumer(builder: (context, ref, _) {
                  final prog = ref.watch(progressForPathProvider(path.id)).maybeWhen(data: (p) => p, orElse: () => null);
                  final lessons = lessonsAsync.maybeWhen(data: (l) => l, orElse: () => <LessonModel>[]);
                  final completedIds = prog?.completedLessons ?? [];
                  final isAllCompleted = lessons.isNotEmpty && lessons.every((l) => completedIds.contains(l.id));

                  if (isAllCompleted) {
                    final certAsync = ref.watch(certificateForPathProvider(path.id));
                    final cert = certAsync.maybeWhen(data: (c) => c, orElse: () => null);
                    return SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.workspace_premium, color: Color(0xFFD4AF37), size: 26),
                        label: Text(cert != null ? 'View Verified Certificate' : 'Claim Verified Certificate'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1A237E),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () async {
                          if (cert != null) {
                            Navigator.pushNamed(context, AppRoutes.certificateDetail, arguments: cert);
                          } else {
                            final newCert = await ref.read(issueCertificateProvider.notifier).issue(path.id);
                            if (context.mounted && newCert != null) {
                              Navigator.pushNamed(context, AppRoutes.certificateDetail, arguments: newCert);
                            }
                          }
                        },
                      ),
                    );
                  }

                  final buttonLabel = prog == null ? 'Start Learning Roadmap' : 'Continue Next Lesson';
                  return SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: Icon(prog == null ? Icons.play_arrow : Icons.arrow_forward),
                      label: Text(
                        buttonLabel,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      onPressed: () async {
                        if (prog == null) {
                          await ref.read(startLearningProvider(path.id).future);
                          ref.invalidate(progressForPathProvider(path.id));
                        }
                        final allLessons = await ref.read(lessonsProvider(path.id).future);
                        final currentCompletedIds = prog?.completedLessons ?? [];
                        LessonModel? nextLesson;
                        for (final l in allLessons) {
                          if (!currentCompletedIds.contains(l.id)) {
                            nextLesson = l;
                            break;
                          }
                        }
                        nextLesson ??= allLessons.isNotEmpty ? allLessons.first : null;
                        if (context.mounted && nextLesson != null) {
                          Navigator.pushNamed(
                            context,
                            AppRoutes.lesson,
                            arguments: {
                              'lesson': nextLesson,
                              'path': path,
                            },
                          );
                        }
                      },
                    ),
                  );
                }),
                const SizedBox(height: AppConstants.paddingL),

                // Certification Exam Card
                Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.amber.shade400, width: 1.5),
                  ),
                  color: Colors.amber.shade50.withOpacity(0.5),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade100,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.quiz, color: Colors.amber, size: 28),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Final Certification Exam',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Timed assessment with 15-minute timer & +50 XP reward.',
                                style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber.shade700,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: () {
                            Navigator.pushNamed(
                              context,
                              AppRoutes.quiz,
                              arguments: path,
                            );
                          },
                          child: const Text('Take Exam'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppConstants.paddingL),

                // Modules & Lessons List
                const Text(
                  'Curriculum & Study Modules',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: AppConstants.paddingS),
                lessonsAsync.when(
                  loading: () => const LoadingSkeletonCard(),
                  error: (err, stack) => ErrorStateWidget(
                    error: err,
                    onRetry: () => ref.refresh(lessonsProvider(path.id)),
                  ),
                  data: (lessons) {
                    final completedIds = progressAsync.maybeWhen(data: (p) => p?.completedLessons ?? [], orElse: () => []);
                    return ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: lessons.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 10),
                      itemBuilder: (ctx, idx) {
                        final lesson = lessons[idx];
                        final isCompleted = completedIds.contains(lesson.id);
                        return Card(
                          elevation: 1,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: isCompleted ? Colors.green.shade300 : Colors.grey.shade200,
                            ),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            leading: CircleAvatar(
                              backgroundColor: isCompleted
                                  ? Colors.green.shade100
                                  : Theme.of(context).primaryColor.withOpacity(0.1),
                              child: Text(
                                '${lesson.order}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isCompleted ? Colors.green.shade900 : Theme.of(context).primaryColor,
                                ),
                              ),
                            ),
                            title: Text(
                              lesson.title,
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                            ),
                            subtitle: Row(
                              children: [
                                if (lesson.estimatedMinutes != null) ...[
                                  Icon(Icons.schedule, size: 14, color: Colors.grey.shade600),
                                  const SizedBox(width: 4),
                                  Text('${lesson.estimatedMinutes} min', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                                  const SizedBox(width: 12),
                                ],
                                if (lesson.resources.isNotEmpty) ...[
                                  Icon(Icons.video_library, size: 14, color: Colors.grey.shade600),
                                  const SizedBox(width: 4),
                                  Text('${lesson.resources.length} study items', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                                ],
                              ],
                            ),
                            trailing: isCompleted
                                ? const Icon(Icons.check_circle, color: Colors.green, size: 24)
                                : const Icon(Icons.chevron_right, color: Colors.grey),
                            onTap: () => Navigator.pushNamed(
                              context,
                              AppRoutes.lesson,
                              arguments: {'lesson': lesson, 'path': path},
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}


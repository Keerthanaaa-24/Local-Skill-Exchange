import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../models/lesson_model.dart';
import '../../models/learning_path_model.dart';
import '../../providers/learning/learning_providers.dart';
import '../../routes/app_routes.dart';

class LessonScreen extends ConsumerStatefulWidget {
  final LessonModel lesson;
  final LearningPathModel path;

  const LessonScreen({required this.lesson, required this.path, super.key});

  @override
  ConsumerState<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends ConsumerState<LessonScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isMarkingComplete = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _launchResourceUrl(LearningResourceModel res) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(
              res.resourceType == 'VIDEO' ? Icons.play_circle_filled : Icons.article,
              color: res.resourceType == 'VIDEO' ? Colors.red : Theme.of(context).primaryColor,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                res.title,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Source: ${res.source ?? "Open Web"} (${res.durationMinutes ?? 15} min)'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(
                res.url,
                style: const TextStyle(fontSize: 13, color: Colors.blueAccent),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.copy, size: 16),
            label: const Text('Copy Link'),
            style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).primaryColor),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: res.url));
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Resource link copied to clipboard!')),
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _completeLesson() async {
    setState(() => _isMarkingComplete = true);
    try {
      await ref.read(completeLessonProvider(widget.lesson.id).future);
      ref.invalidate(progressForPathProvider(widget.path.id));
      ref.invalidate(learningDashboardProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lesson marked complete! +20 XP earned'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error completing lesson: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isMarkingComplete = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final progressAsync = ref.watch(progressForPathProvider(widget.path.id));

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.lesson.title),
        backgroundColor: Theme.of(context).primaryColor,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.menu_book), text: 'Lecture Notes'),
            Tab(icon: Icon(Icons.play_circle_outline), text: 'Study Materials'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Lecture Notes & Concepts
          SingleChildScrollView(
            padding: const EdgeInsets.all(AppConstants.paddingL),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.lesson.summary != null && widget.lesson.summary!.isNotEmpty) ...[
                  Card(
                    color: Colors.blue.shade50,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.lightbulb, color: Colors.blueAccent),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Lesson Summary',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.blueAccent),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  widget.lesson.summary!,
                                  style: TextStyle(fontSize: 13, color: Colors.blue.shade900),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                Row(
                  children: [
                    if (widget.lesson.estimatedMinutes != null) ...[
                      const Icon(Icons.timer_outlined, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        'Estimated time: ${widget.lesson.estimatedMinutes} min',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey),
                      ),
                    ],
                  ],
                ),
                const Divider(height: 24),
                Text(
                  widget.lesson.content ?? 'No lecture content provided.',
                  style: const TextStyle(fontSize: 15, height: 1.6),
                ),
              ],
            ),
          ),

          // Tab 2: Verified Study Materials & Video Tutorials
          SingleChildScrollView(
            padding: const EdgeInsets.all(AppConstants.paddingL),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Verified Educational Resources',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(
                  'Curated video tutorials, Open Educational Resource (OER) documentation, and cheat sheets.',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
                const SizedBox(height: 16),

                if (widget.lesson.resources.isEmpty && widget.lesson.videoUrl == null)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        children: [
                          Icon(Icons.auto_stories_outlined, size: 48, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          Text(
                            'Study materials are being prepared for this lesson.',
                            style: TextStyle(fontSize: 15, color: Colors.grey.shade700, fontWeight: FontWeight.w500),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Please refer to the lecture notes or practice questions!',
                            style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  )
                else ...[
                  ...widget.lesson.resources.map((res) {
                    IconData iconData = Icons.article;
                    Color iconColor = Colors.blue;
                    String actionLabel = 'Read Docs';
                    if (res.resourceType == 'VIDEO') {
                      iconData = Icons.play_circle_filled;
                      iconColor = Colors.red;
                      actionLabel = 'Watch';
                    } else if (res.resourceType == 'PDF' || res.resourceType == 'PPT') {
                      iconData = Icons.picture_as_pdf;
                      iconColor = Colors.deepOrange;
                      actionLabel = 'Open PDF';
                    }

                    return Card(
                      elevation: 1,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: iconColor.withOpacity(0.12),
                          child: Icon(iconData, color: iconColor),
                        ),
                        title: Text(
                          res.title,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: iconColor.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  res.resourceType,
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: iconColor),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '${res.source ?? "Verified"} • ${res.durationMinutes ?? 15} min',
                                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        trailing: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).primaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          icon: Icon(
                            res.resourceType == 'VIDEO' ? Icons.play_arrow : Icons.open_in_new,
                            size: 14,
                          ),
                          label: Text(actionLabel, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          onPressed: () => _launchResourceUrl(res),
                        ),
                      ),
                    );
                  }),
                ],
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: progressAsync.when(
        loading: () => const LinearProgressIndicator(),
        error: (e, s) => const SizedBox(),
        data: (progress) {
          final completedIds = progress?.completedLessons ?? [];
          final alreadyCompleted = completedIds.contains(widget.lesson.id);

          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: Icon(
                      alreadyCompleted ? Icons.check_circle : Icons.check,
                      color: alreadyCompleted ? Colors.green : Theme.of(context).primaryColor,
                    ),
                    label: Text(
                      alreadyCompleted ? 'Completed' : (_isMarkingComplete ? 'Saving...' : 'Mark Complete (+20 XP)'),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: (alreadyCompleted || _isMarkingComplete) ? null : () => _completeLesson(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.quiz, color: Colors.white),
                    label: const Text(
                      'Practice (+30 XP)',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        AppRoutes.practice,
                        arguments: {'lesson': widget.lesson, 'path': widget.path},
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}


import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../models/lesson_model.dart';
import '../../models/learning_path_model.dart';
import '../../models/practice_question_model.dart';
import '../../models/practice_result_model.dart';
import '../../providers/learning/learning_providers.dart';
import '../../repositories/learning_repository.dart';

class PracticeScreen extends ConsumerStatefulWidget {
  final LessonModel lesson;
  final LearningPathModel path;

  const PracticeScreen({
    required this.lesson,
    required this.path,
    super.key,
  });

  @override
  ConsumerState<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends ConsumerState<PracticeScreen> {
  // Map of question_id -> selected_option
  final Map<int, String> _selectedAnswers = {};
  bool _isSubmitting = false;
  PracticeResultModel? _result;

  @override
  Widget build(BuildContext context) {
    final questionsAsync = ref.watch(practiceQuestionsProvider(widget.lesson.id));

    return Scaffold(
      appBar: AppBar(
        title: Text('Practice: ${widget.lesson.title}'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: questionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.paddingL),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Error loading practice: $err', textAlign: TextAlign.center),
                const SizedBox(height: AppConstants.paddingM),
                ElevatedButton(
                  onPressed: () => ref.refresh(practiceQuestionsProvider(widget.lesson.id)),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (questions) {
          if (questions.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.quiz_outlined, size: 54, color: Colors.grey.shade400),
                    const SizedBox(height: 16),
                    Text(
                      'Practice content is being prepared for this lesson.',
                      style: TextStyle(fontSize: 16, color: Colors.grey.shade700, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Please complete the lecture notes and check the verified study materials in the meantime!',
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          if (_result != null) {
            return _buildResultView(questions);
          }

          return _buildQuizView(questions);
        },
      ),
    );
  }

  Widget _buildQuizView(List<PracticeQuestionModel> questions) {
    final allAnswered = questions.every((q) => _selectedAnswers.containsKey(q.id));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.paddingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Answer all questions to complete the lesson (70% required to pass):',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: AppConstants.paddingL),
          for (int i = 0; i < questions.length; i++) ...[
            _buildQuestionCard(questions[i], i + 1),
            const SizedBox(height: AppConstants.paddingL),
          ],
          const SizedBox(height: AppConstants.paddingM),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Theme.of(context).primaryColor,
              ),
              onPressed: (!allAnswered || _isSubmitting) ? null : () => _submitAnswers(questions),
              child: _isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text(
                      allAnswered ? 'Submit Practice' : 'Answer All Questions to Submit',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
            ),
          ),
          const SizedBox(height: AppConstants.paddingXL),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(PracticeQuestionModel q, int index) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Question $index',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              q.question,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: AppConstants.paddingM),
            for (final option in q.options)
              RadioListTile<String>(
                title: Text(option),
                value: option,
                groupValue: _selectedAnswers[q.id],
                onChanged: _isSubmitting
                    ? null
                    : (val) {
                        if (val != null) {
                          setState(() {
                            _selectedAnswers[q.id] = val;
                          });
                        }
                      },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitAnswers(List<PracticeQuestionModel> questions) async {
    setState(() {
      _isSubmitting = true;
    });

    try {
      final repo = ref.read(learningRepositoryProvider);
      final answersPayload = _selectedAnswers.entries
          .map((e) => {'question_id': e.key.toString(), 'answer': e.value})
          .toList();

      final result = await repo.submitPractice(widget.lesson.id, answersPayload);

      // If passed, auto-complete the lesson
      if (result.passed) {
        await repo.completeLesson(widget.lesson.id);
        ref.invalidate(progressForPathProvider(widget.path.id));
        ref.invalidate(lessonsProvider(widget.path.id));
        ref.invalidate(practiceHistoryProvider(widget.lesson.id));
      }

      if (!mounted) return;
      setState(() {
        _result = result;
        _isSubmitting = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error submitting practice: $e')),
      );
    }
  }

  Widget _buildResultView(List<PracticeQuestionModel> questions) {
    final result = _result!;
    final passed = result.passed;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.paddingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            passed ? Icons.check_circle_rounded : Icons.cancel_rounded,
            color: passed ? Colors.green : Colors.redAccent,
            size: 80,
          ),
          const SizedBox(height: AppConstants.paddingM),
          Text(
            passed ? 'Congratulations! You Passed!' : 'Practice Failed',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: passed ? Colors.green.shade800 : Colors.red.shade800,
            ),
          ),
          const SizedBox(height: AppConstants.paddingS),
          Text(
            'Score: ${result.percentage.toStringAsFixed(1)}% (${result.correctAnswers} / ${result.totalQuestions} correct)',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          if (passed) ...[
            const SizedBox(height: 6),
            const Text(
              'Lesson has been marked as complete!',
              style: TextStyle(fontSize: 14, color: Colors.green, fontWeight: FontWeight.w500),
            ),
          ],
          const SizedBox(height: AppConstants.paddingL),
          const Divider(),
          const SizedBox(height: AppConstants.paddingM),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Question Feedback:',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: AppConstants.paddingM),
          for (final fb in result.feedback) ...[
            _buildFeedbackCard(fb, questions),
            const SizedBox(height: AppConstants.paddingM),
          ],
          const SizedBox(height: AppConstants.paddingL),
          if (!passed) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.refresh, color: Colors.white),
                label: const Text('Retry Practice', style: TextStyle(color: Colors.white, fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange.shade700,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () {
                  setState(() {
                    _result = null;
                    _selectedAnswers.clear();
                  });
                },
              ),
            ),
            const SizedBox(height: AppConstants.paddingM),
          ],
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
              onPressed: () => Navigator.pop(context),
              child: const Text('Back to Lesson'),
            ),
          ),
          const SizedBox(height: AppConstants.paddingXL),
        ],
      ),
    );
  }

  Widget _buildFeedbackCard(PracticeFeedbackItem fb, List<PracticeQuestionModel> questions) {
    PracticeQuestionModel? q;
    try {
      q = questions.firstWhere((item) => item.id == fb.questionId);
    } catch (_) {
      q = null;
    }

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      color: fb.correct ? Colors.green.shade50 : Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  fb.correct ? Icons.check_circle : Icons.cancel,
                  color: fb.correct ? Colors.green : Colors.red,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    q?.question ?? 'Question ${fb.questionId}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            if (fb.explanation != null && fb.explanation!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Explanation: ${fb.explanation}',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade800,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

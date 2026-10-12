import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/widgets/loading_state.dart';
import '../../core/widgets/error_state.dart';
import '../../models/learning_path_model.dart';
import '../../models/quiz_models.dart';
import '../../providers/learning/learning_providers.dart';
import '../../repositories/learning_repository.dart';

class QuizScreen extends ConsumerStatefulWidget {
  final LearningPathModel path;

  const QuizScreen({required this.path, super.key});

  @override
  ConsumerState<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends ConsumerState<QuizScreen> {
  int _currentQuestionIndex = 0;
  final Map<int, String> _selectedAnswers = {};
  Timer? _timer;
  int _remainingSeconds = 0;
  int _totalDurationSeconds = 0;
  bool _isSubmitting = false;
  QuizResultModel? _quizResult;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer(int minutes) {
    if (_timer != null) return;
    _totalDurationSeconds = minutes * 60;
    _remainingSeconds = _totalDurationSeconds;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
        } else {
          _timer?.cancel();
          _submitQuiz(autoSubmit: true);
        }
      });
    });
  }

  Future<void> _submitQuiz({bool autoSubmit = false}) async {
    if (_isSubmitting) return;

    if (!autoSubmit) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Submit Assessment?'),
          content: Text(
            'You have answered ${_selectedAnswers.length} question(s). Are you ready to submit your exam for grading?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Review Answers'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).primaryColor),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Submit Now', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
      if (confirm != true) return;
    }

    setState(() => _isSubmitting = true);
    _timer?.cancel();

    try {
      final quiz = await ref.read(pathQuizProvider(widget.path.id).future);
      final repo = ref.read(learningRepositoryProvider);

      final answersPayload = _selectedAnswers.entries
          .map((e) => {'question_id': e.key, 'answer': e.value})
          .toList();

      final elapsedSeconds = _totalDurationSeconds - _remainingSeconds;

      final result = await repo.submitQuiz(
        quiz.id,
        answersPayload,
        elapsedSeconds > 0 ? elapsedSeconds : 1,
      );

      if (mounted) {
        setState(() {
          _quizResult = result;
          _isSubmitting = false;
        });
        ref.invalidate(learningDashboardProvider);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to grade quiz: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final quizAsync = ref.watch(pathQuizProvider(widget.path.id));

    return Scaffold(
      appBar: AppBar(
        title: Text(_quizResult != null ? 'Assessment Results' : 'Certification Exam'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: quizAsync.when(
        loading: () => const LoadingSkeletonCard(),
        error: (err, stack) => ErrorStateWidget(
          error: err,
          onRetry: () => ref.refresh(pathQuizProvider(widget.path.id)),
        ),
        data: (quiz) {
          if (_timer == null && _quizResult == null) {
            _startTimer(quiz.timeLimitMinutes);
          }

          if (_quizResult != null) {
            return _buildResultView(quiz, _quizResult!);
          }

          if (quiz.questions.isEmpty) {
            return const Center(child: Text('No questions configured for this exam.'));
          }

          final currentQ = quiz.questions[_currentQuestionIndex];
          final mins = _remainingSeconds ~/ 60;
          final secs = _remainingSeconds % 60;
          final timerText = '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
          final isTimeLow = _remainingSeconds < 120;

          return SafeArea(
            child: Column(
              children: [
                // Timer & Progress Banner
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  color: isTimeLow ? Colors.red.shade50 : Theme.of(context).cardColor,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.timer_outlined,
                            color: isTimeLow ? Colors.red : Theme.of(context).primaryColor,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Time Left: $timerText',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: isTimeLow ? Colors.red : null,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        'Question ${_currentQuestionIndex + 1} of ${quiz.questions.length}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                LinearProgressIndicator(
                  value: (_currentQuestionIndex + 1) / quiz.questions.length,
                  backgroundColor: Colors.grey.shade200,
                  color: Theme.of(context).primaryColor,
                ),
                // Question Body
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppConstants.paddingL),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: Padding(
                            padding: const EdgeInsets.all(AppConstants.paddingL),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).primaryColor.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        '${currentQ.points} Points',
                                        style: TextStyle(
                                          color: Theme.of(context).primaryColor,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Type: ${currentQ.questionType.toUpperCase()}',
                                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  currentQ.questionText,
                                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, height: 1.4),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Select your answer:',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        const SizedBox(height: 10),
                        ...currentQ.options.map((option) {
                          final isSelected = _selectedAnswers[currentQ.id] == option;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(10),
                              onTap: () {
                                setState(() {
                                  _selectedAnswers[currentQ.id] = option;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? Theme.of(context).primaryColor.withOpacity(0.08)
                                      : Theme.of(context).cardColor,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isSelected
                                        ? Theme.of(context).primaryColor
                                        : Colors.grey.shade300,
                                    width: isSelected ? 2 : 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      isSelected
                                          ? Icons.radio_button_checked
                                          : Icons.radio_button_off,
                                      color: isSelected
                                          ? Theme.of(context).primaryColor
                                          : Colors.grey,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        option,
                                        style: TextStyle(
                                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
                // Footer Navigation
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 5,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (_currentQuestionIndex > 0)
                        OutlinedButton(
                          onPressed: () {
                            setState(() => _currentQuestionIndex--);
                          },
                          child: const Text('Previous'),
                        )
                      else
                        const SizedBox(width: 80),
                      if (_currentQuestionIndex < quiz.questions.length - 1)
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).primaryColor,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () {
                            setState(() => _currentQuestionIndex++);
                          },
                          child: const Text('Next Question'),
                        )
                      else
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade700,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          ),
                          icon: _isSubmitting
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              : const Icon(Icons.check_circle),
                          label: const Text('Submit Exam'),
                          onPressed: _isSubmitting ? null : () => _submitQuiz(),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildResultView(QuizModel quiz, QuizResultModel result) {
    final isPassed = result.passed;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.paddingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            color: isPassed ? Colors.green.shade50 : Colors.red.shade50,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: isPassed ? Colors.green.shade300 : Colors.red.shade300, width: 2),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(
                    isPassed ? Icons.verified : Icons.cancel,
                    size: 64,
                    color: isPassed ? Colors.green.shade700 : Colors.red.shade700,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    isPassed ? 'Assessment Passed!' : 'Assessment Not Passed',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: isPassed ? Colors.green.shade900 : Colors.red.shade900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Score: ${result.marksObtained} / ${result.maximumMarks} (${result.percentage.toStringAsFixed(1)}%)',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Passing requirement: ${quiz.passingPercentage}% (Attempt #${result.attemptNumber})',
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                  ),
                  if (result.xpEarned > 0) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade100,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.amber.shade600),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.bolt, color: Colors.amber, size: 20),
                          const SizedBox(width: 6),
                          Text(
                            '+${result.xpEarned} XP Earned!',
                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amber.shade900),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Question Review & Explanations',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ...result.feedback.asMap().entries.map((entry) {
            final idx = entry.key;
            final item = entry.value;
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          item.isCorrect ? Icons.check_circle : Icons.cancel,
                          color: item.isCorrect ? Colors.green : Colors.red,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Question ${idx + 1}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const Spacer(),
                        Text(
                          '${item.pointsEarned}/${item.pointsPossible} pts',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: item.isCorrect ? Colors.green : Colors.red,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(item.questionText, style: const TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Text('Your Answer: ${item.userAnswer.isEmpty ? "(No answer)" : item.userAnswer}'),
                    if (!item.isCorrect)
                      Text(
                        'Correct Answer: ${item.correctAnswer}',
                        style: TextStyle(color: Colors.green.shade800, fontWeight: FontWeight.bold),
                      ),
                    if (item.explanation != null && item.explanation!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Explanation: ${item.explanation}',
                          style: TextStyle(fontSize: 13, color: Colors.blue.shade900),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 20),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onPressed: () => Navigator.pop(context),
            child: const Text('Back to Course Roadmap'),
          ),
        ],
      ),
    );
  }
}

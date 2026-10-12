import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/learning_path_model.dart';
import '../../models/lesson_model.dart';
import '../../models/learning_progress_model.dart';
import '../../models/practice_question_model.dart';
import '../../models/practice_attempt_model.dart';
import '../../models/quiz_models.dart';
import '../../repositories/learning_repository.dart';

// Provider to fetch all learning paths
final learningPathsProvider = FutureProvider.autoDispose<List<LearningPathModel>>((ref) async {
  final repo = ref.watch(learningRepositoryProvider);
  return await repo.getLearningPaths();
});

// Provider to fetch/generate a learning path for any catalog skill
final pathForSkillProvider = FutureProvider.autoDispose.family<LearningPathModel, int>((ref, skillId) async {
  final repo = ref.watch(learningRepositoryProvider);
  return await repo.getPathBySkill(skillId);
});

// Provider to fetch user learning dashboard analytics
final learningDashboardProvider = FutureProvider.autoDispose<LearningDashboardModel>((ref) async {
  final repo = ref.watch(learningRepositoryProvider);
  return await repo.getLearningDashboard();
});

// Provider to fetch a single learning path by its ID
final learningPathProvider = FutureProvider.autoDispose.family<LearningPathModel, int>((ref, pathId) async {
  final repo = ref.watch(learningRepositoryProvider);
  return await repo.getLearningPathById(pathId);
});

// Provider to fetch lessons for a given learning path
final lessonsProvider = FutureProvider.autoDispose.family<List<LessonModel>, int>((ref, pathId) async {
  final repo = ref.watch(learningRepositoryProvider);
  return await repo.getLessons(pathId);
});

// Provider to start learning a path (creates a progress entry)
final startLearningProvider = FutureProvider.autoDispose.family<void, int>((ref, pathId) async {
  final repo = ref.watch(learningRepositoryProvider);
  await repo.startLearning(pathId);
});

// Provider to fetch the current user's learning progress list
final userProgressProvider = FutureProvider.autoDispose<List<LearningProgressModel>>((ref) async {
  final repo = ref.watch(learningRepositoryProvider);
  return await repo.getUserProgress();
});

// Provider to fetch progress for a specific learning path (may be null if not started)
final progressForPathProvider = FutureProvider.autoDispose.family<LearningProgressModel?, int>((ref, pathId) async {
  final repo = ref.watch(learningRepositoryProvider);
  final progresses = await repo.getUserProgress();
  try {
    return progresses.firstWhere((p) => p.learningPathId == pathId);
  } catch (_) {
    return null;
  }
});

// Provider to mark a lesson as completed
final completeLessonProvider = FutureProvider.autoDispose.family<void, int>((ref, lessonId) async {
  final repo = ref.watch(learningRepositoryProvider);
  await repo.completeLesson(lessonId);
});

// Provider to fetch practice questions for a lesson
final practiceQuestionsProvider = FutureProvider.autoDispose.family<List<PracticeQuestionModel>, int>((ref, lessonId) async {
  final repo = ref.watch(learningRepositoryProvider);
  return await repo.getPracticeQuestions(lessonId);
});

// Provider to fetch practice attempt history for a lesson
final practiceHistoryProvider = FutureProvider.autoDispose.family<List<PracticeAttemptModel>, int>((ref, lessonId) async {
  final repo = ref.watch(learningRepositoryProvider);
  return await repo.getPracticeHistory(lessonId);
});

// Provider to fetch quiz for a learning path
final pathQuizProvider = FutureProvider.autoDispose.family<QuizModel, int>((ref, pathId) async {
  final repo = ref.watch(learningRepositoryProvider);
  return await repo.getPathQuiz(pathId);
});

// Provider to fetch quiz attempts for a quiz
final quizAttemptsProvider = FutureProvider.autoDispose.family<List<QuizAttemptModel>, int>((ref, quizId) async {
  final repo = ref.watch(learningRepositoryProvider);
  return await repo.getQuizAttempts(quizId);
});

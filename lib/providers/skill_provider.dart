import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/skill_model.dart';
import '../repositories/skill_repository.dart';

// Provides a single skill by ID
final singleSkillProvider = FutureProvider.family<SkillModel, int>((ref, id) async {
  final repository = ref.watch(skillRepositoryProvider);
  return repository.getSkillById(id);
});

// Provides search results
final searchSkillsProvider = FutureProvider.family<List<SkillModel>, String>((ref, query) async {
  if (query.isEmpty) return [];
  final repository = ref.watch(skillRepositoryProvider);
  return repository.searchSkills(query);
});

// Provides skills by category
final categorySkillsProvider = FutureProvider.family<List<SkillModel>, String>((ref, categoryName) async {
  final repository = ref.watch(skillRepositoryProvider);
  return repository.getSkillsByCategory(categoryName);
});

// Provides dynamic category counts from the database
final skillCategoryCountsProvider = FutureProvider<Map<String, int>>((ref) async {
  final repository = ref.watch(skillRepositoryProvider);
  return repository.getCategoryCounts();
});

class SkillFilterParam {
  final String category;
  final String query;

  const SkillFilterParam({this.category = 'All', this.query = ''});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SkillFilterParam &&
          runtimeType == other.runtimeType &&
          category == other.category &&
          query == other.query;

  @override
  int get hashCode => category.hashCode ^ query.hashCode;
}

// Filtered and paginated skills notifier
class FilteredSkillsNotifier extends FamilyAsyncNotifier<List<SkillModel>, SkillFilterParam> {
  int _currentPage = 1;
  bool _hasMore = true;
  bool _isLoadingMore = false;

  bool get hasMore => _hasMore;
  bool get isLoadingMore => _isLoadingMore;

  @override
  Future<List<SkillModel>> build(SkillFilterParam arg) async {
    _currentPage = 1;
    _hasMore = true;
    _isLoadingMore = false;
    return _fetchPage(1);
  }

  Future<List<SkillModel>> _fetchPage(int page) async {
    final repository = ref.read(skillRepositoryProvider);
    final newSkills = await repository.getSkills(
      page: page,
      limit: 20,
      category: arg.category == 'All' ? null : arg.category,
      q: arg.query.trim().isEmpty ? null : arg.query.trim(),
    );
    if (newSkills.length < 20) {
      _hasMore = false;
    }
    return newSkills;
  }

  Future<void> loadMore() async {
    if (state.isLoading || _isLoadingMore || !_hasMore) return;
    _isLoadingMore = true;
    final previous = state.value ?? [];
    try {
      _currentPage++;
      final newSkills = await _fetchPage(_currentPage);
      if (newSkills.isEmpty) {
        _hasMore = false;
      }
      state = AsyncValue.data([...previous, ...newSkills]);
    } catch (e, st) {
      if (previous.isEmpty) {
        state = AsyncValue.error(e, st);
      }
    } finally {
      _isLoadingMore = false;
    }
  }

  Future<void> refresh() async {
    _currentPage = 1;
    _hasMore = true;
    _isLoadingMore = false;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchPage(1));
  }
}

final filteredSkillsNotifierProvider =
    AsyncNotifierProvider.family<FilteredSkillsNotifier, List<SkillModel>, SkillFilterParam>(() {
  return FilteredSkillsNotifier();
});

// Main skills list notifier supporting pagination and refresh (for backward compatibility)
class SkillsNotifier extends AsyncNotifier<List<SkillModel>> {
  int _currentPage = 1;
  bool _hasMore = true;

  @override
  Future<List<SkillModel>> build() async {
    _currentPage = 1;
    _hasMore = true;
    return _fetchPage(_currentPage);
  }

  Future<List<SkillModel>> _fetchPage(int page) async {
    final repository = ref.read(skillRepositoryProvider);
    final newSkills = await repository.getSkills(page: page, limit: 50);
    if (newSkills.length < 50) {
      _hasMore = false;
    }
    return newSkills;
  }

  Future<void> loadMore() async {
    if (state.isLoading || !_hasMore) return;

    final previous = state.value ?? [];
    state = AsyncValue.data(previous);
    try {
      _currentPage++;
      final newSkills = await _fetchPage(_currentPage);
      if (newSkills.isEmpty) _hasMore = false;
      state = AsyncValue.data([...previous, ...newSkills]);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> refresh() async {
    _currentPage = 1;
    _hasMore = true;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchPage(1));
  }

  Future<void> retry() async => await refresh();

  Future<void> createSkill(SkillModel skill) async {
    try {
      await ref.read(skillRepositoryProvider).createSkill(skill);
      ref.invalidateSelf();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateSkill(int id, Map<String, dynamic> updates) async {
    try {
      await ref.read(skillRepositoryProvider).updateSkill(id, updates);
      ref.invalidateSelf();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteSkill(int id) async {
    try {
      await ref.read(skillRepositoryProvider).deleteSkill(id);
      ref.invalidateSelf();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> offerSkill(int id) async {
    try {
      await ref.read(skillRepositoryProvider).offerSkill(id);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> requestSkill(int id) async {
    try {
      await ref.read(skillRepositoryProvider).requestSkill(id);
    } catch (e) {
      rethrow;
    }
  }
}

final skillsNotifierProvider = AsyncNotifierProvider<SkillsNotifier, List<SkillModel>>(() {
  return SkillsNotifier();
});

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/skill_model.dart';
import '../../services/api_client.dart';

class AdminSkillsState {
  final bool isLoading;
  final List<SkillModel> skills;
  final String? errorMessage;
  final bool hasMore;

  const AdminSkillsState({
    this.isLoading = false,
    this.skills = const [],
    this.errorMessage,
    this.hasMore = false,
  });
}

class AdminSkillsNotifier extends AsyncNotifier<AdminSkillsState> {
  static const int _pageSize = 20;
  int _skip = 0;
  String? _search;

  @override
  Future<AdminSkillsState> build() async {
    _skip = 0;
    return _load();
  }

  Future<AdminSkillsState> _load() async {
    try {
      final queryParams = {
        'skip': _skip.toString(),
        'limit': _pageSize.toString(),
        if (_search != null && _search!.isNotEmpty) 'search': _search!,
      };
      final response = await apiClient.dio.get('/admin/skills', queryParameters: queryParams);
      final List data = response.data as List;
      final skills = data.map((e) => SkillModel.fromJson(e)).toList();
      final hasMore = skills.length == _pageSize;
      return AdminSkillsState(isLoading: false, skills: skills, hasMore: hasMore);
    } catch (e) {
      return AdminSkillsState(isLoading: false, skills: [], errorMessage: e.toString(), hasMore: false);
    }
  }

  Future<void> loadMore() async {
    if (!(state.value?.hasMore ?? false)) return;
    _skip += _pageSize;
    state = const AsyncValue.loading();
    final newState = await _load();
    final combined = [...?state.value?.skills, ...newState.skills];
    state = AsyncValue.data(AdminSkillsState(isLoading: false, skills: combined, hasMore: newState.hasMore));
  }

  Future<void> load() async {
    _skip = 0;
    state = const AsyncValue.loading();
    state = AsyncValue.data(await _load());
  }

  Future<void> refresh() async => await load();

  Future<void> search(String term) async {
    _search = term;
    await refresh();
  }
}

final adminSkillsProvider = AsyncNotifierProvider<AdminSkillsNotifier, AdminSkillsState>(() => AdminSkillsNotifier());

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/user_model.dart';
import '../../services/api_client.dart';

class AdminUsersState {
  final bool isLoading;
  final List<User> users;
  final String? errorMessage;
  final bool hasMore;

  const AdminUsersState({
    this.isLoading = false,
    this.users = const [],
    this.errorMessage,
    this.hasMore = false,
  });
}

class AdminUsersNotifier extends AsyncNotifier<AdminUsersState> {
  static const int _pageSize = 20;
  int _skip = 0;
  String? _search;

  @override
  Future<AdminUsersState> build() async {
    _skip = 0;
    return _load();
  }

  Future<AdminUsersState> _load() async {
    try {
      final queryParams = {
        'skip': _skip.toString(),
        'limit': _pageSize.toString(),
        if (_search != null && _search!.isNotEmpty) 'search': _search!,
      };
      final response = await apiClient.dio.get('/admin/users', queryParameters: queryParams);
      final List data = response.data as List;
      final users = data.map((e) => User.fromJson(e)).toList();
      final hasMore = users.length == _pageSize;
      return AdminUsersState(isLoading: false, users: users, hasMore: hasMore);
    } catch (e) {
      return AdminUsersState(isLoading: false, users: [], errorMessage: e.toString(), hasMore: false);
    }
  }

  Future<void> loadMore() async {
    if (!(state.value?.hasMore ?? false)) return;
    _skip += _pageSize;
    state = const AsyncValue.loading();
    final newState = await _load();
    final combined = [...?state.value?.users, ...newState.users];
    state = AsyncValue.data(AdminUsersState(isLoading: false, users: combined, hasMore: newState.hasMore));
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

final adminUsersProvider = AsyncNotifierProvider<AdminUsersNotifier, AdminUsersState>(() => AdminUsersNotifier());

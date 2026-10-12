import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/auth_models.dart';
import '../repositories/auth_repository.dart';
import '../core/network/api_client.dart';

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient();
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AuthRepository(apiClient);
});

final authStateProvider = StateNotifierProvider<AuthNotifier, User?>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return AuthNotifier(authRepository);
});

class AuthNotifier extends StateNotifier<User?> {
  final AuthRepository _authRepository;

  AuthNotifier(this._authRepository) : super(null) {
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    try {
      final user = await _authRepository.getCurrentUser();
      state = user;
    } catch (e) {
      state = null;
    }
  }

  Future<void> login(String email, String password) async {
    final response = await _authRepository.login(email, password);
    state = response.user;
  }

  Future<void> register(String name, String email, String password) async {
    final response = await _authRepository.register(name, email, password);
    state = response.user;
  }

  Future<void> refreshUser() async {
    await _checkAuth();
  }

  Future<void> logout() async {
    await _authRepository.logout();
    state = null;
  }
}

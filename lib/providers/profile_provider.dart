import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/profile_models.dart';
import '../repositories/profile_repository.dart';
import 'auth_provider.dart'; // To access apiClientProvider

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ProfileRepository(apiClient);
});

final profileProvider = AsyncNotifierProvider<ProfileNotifier, UserProfile>(() {
  return ProfileNotifier();
});

class ProfileNotifier extends AsyncNotifier<UserProfile> {
  late ProfileRepository _repository;

  @override
  Future<UserProfile> build() async {
    _repository = ref.watch(profileRepositoryProvider);
    return _fetchProfile();
  }

  Future<UserProfile> _fetchProfile() async {
    return await _repository.getProfile();
  }

  Future<void> refreshProfile() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchProfile());
  }

  Future<void> updateProfile(UpdateProfileRequest request) async {
    final oldState = state;
    // Optimistic or just show loading state on caller UI.
    try {
      final response = await _repository.updateProfile(request);
      state = AsyncValue.data(response.profile);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      // Revert if needed or let the error bubble up so UI can handle it.
      // But we probably want the UI to handle the exception gracefully while keeping old state.
      state = oldState;
      rethrow;
    }
  }

  Future<void> changePassword(String current, String newPassword) async {
    await _repository.changePassword(current, newPassword);
  }

  Future<void> uploadProfileImageBytes(List<int> bytes, {String filename = 'profile.png'}) async {
    try {
      final newUrl = await _repository.uploadProfileImageBytes(bytes, filename: filename);
      if (state.hasValue && state.value != null) {
        final current = state.value!;
        state = AsyncValue.data(UserProfile(
          id: current.id,
          email: current.email,
          name: current.name,
          bio: current.bio,
          phone: current.phone,
          profileImageUrl: newUrl,
          credits: current.credits,
          rating: current.rating,
          reviewCount: current.reviewCount,
          skills: current.skills,
          wantedSkills: current.wantedSkills,
          lat: current.lat,
          lng: current.lng,
        ));
      } else {
        await refreshProfile();
      }
      // Also refresh auth and user providers so the whole app updates immediately
      ref.read(authStateProvider.notifier).refreshUser();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> uploadProfileImage(String filePath) async {
    try {
      final newUrl = await _repository.uploadProfileImage(filePath);
      if (state.hasValue && state.value != null) {
        final current = state.value!;
        state = AsyncValue.data(UserProfile(
          id: current.id,
          email: current.email,
          name: current.name,
          bio: current.bio,
          phone: current.phone,
          profileImageUrl: newUrl,
          credits: current.credits,
          rating: current.rating,
          reviewCount: current.reviewCount,
          skills: current.skills,
          wantedSkills: current.wantedSkills,
          lat: current.lat,
          lng: current.lng,
        ));
      } else {
        await refreshProfile();
      }
      ref.read(authStateProvider.notifier).refreshUser();
    } catch (e) {
      rethrow;
    }
  }
}

import 'package:dio/dio.dart';
import '../core/network/api_client.dart';
import '../core/network/token_storage.dart';
import '../models/auth_models.dart';
import '../core/config/env.dart';

class AuthException implements Exception {
  final String message;
  final int? statusCode;
  AuthException(this.message, [this.statusCode]);
  @override
  String toString() => message;
}

class AuthRepository {
  final ApiClient _apiClient;

  AuthRepository(this._apiClient);

  String _formatDioError(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return 'Connection timed out. Server at ${Env.apiBaseUrl} took too long to respond.';
    }
    if (e.type == DioExceptionType.connectionError) {
      return 'Cannot reach backend at ${Env.apiBaseUrl}. Ensure your computer and phone are on the same Wi-Fi network and backend is running.';
    }
    if (e.response != null) {
      final data = e.response?.data;
      if (data is Map && data.containsKey('detail')) {
        final detail = data['detail'];
        if (detail is String) return detail;
        if (detail is List && detail.isNotEmpty) {
          final first = detail.first;
          if (first is Map && first.containsKey('msg')) {
            return first['msg'].toString();
          }
        }
      }
      if (e.response?.statusCode == 401) {
        return 'Incorrect email or password.';
      }
      if (e.response?.statusCode == 400) {
        return 'Invalid request details.';
      }
      return 'Server error (${e.response?.statusCode}). Please try again.';
    }
    return e.message ?? 'An unexpected network error occurred.';
  }

  /// Login using form‑urlencoded payload expected by FastAPI.
  Future<AuthResponse> login(String email, String password) async {
    try {
      final response = await _apiClient.dio.post(
        '/auth/login',
        data: {
          'username': email.trim(),
          'password': password,
        },
        options: Options(contentType: Headers.formUrlEncodedContentType),
      );
      final accessToken = response.data['access_token'] ?? '';
      final tokenType = response.data['token_type'] ?? 'bearer';
      await TokenStorage.saveToken(accessToken);
      await TokenStorage.saveIsGuest(false);

      final user = await getCurrentUser();
      if (user == null) {
        throw AuthException('Failed to retrieve user profile after login.');
      }
      return AuthResponse(
        accessToken: accessToken,
        tokenType: tokenType,
        user: user,
        isGuest: false,
      );
    } on DioException catch (e) {
      throw AuthException(_formatDioError(e), e.response?.statusCode);
    }
  }

  /// Register a new user against MySQL backend and automatically log in.
  Future<AuthResponse> register(String name, String email, String password) async {
    try {
      await _apiClient.dio.post(
        '/auth/register',
        data: {
          'name': name.trim(),
          'email': email.trim().toLowerCase(),
          'password': password,
        },
      );

      // Log in immediately after registration to obtain bearer JWT
      final loginResp = await _apiClient.dio.post(
        '/auth/login',
        data: {
          'username': email.trim().toLowerCase(),
          'password': password,
        },
        options: Options(contentType: Headers.formUrlEncodedContentType),
      );
      final accessToken = loginResp.data['access_token'] ?? '';
      final tokenType = loginResp.data['token_type'] ?? 'bearer';
      await TokenStorage.saveToken(accessToken);
      await TokenStorage.saveIsGuest(false);

      final user = await getCurrentUser();
      if (user == null) {
        throw AuthException('Failed to retrieve user after registration.');
      }
      return AuthResponse(
        accessToken: accessToken,
        tokenType: tokenType,
        user: user,
        isGuest: false,
      );
    } on DioException catch (e) {
      throw AuthException(_formatDioError(e), e.response?.statusCode);
    }
  }

  /// Authenticate safely in Guest Mode via backend /auth/guest endpoint.
  Future<AuthResponse> loginAsGuest() async {
    try {
      final response = await _apiClient.dio.post('/auth/guest');
      final accessToken = response.data['access_token'] ?? '';
      final tokenType = response.data['token_type'] ?? 'bearer';
      await TokenStorage.saveToken(accessToken);
      await TokenStorage.saveIsGuest(true);

      final user = await getCurrentUser();
      final guestUser = user?.copyWith(isGuest: true) ??
          User(
            id: 'guest',
            email: 'guest_user@localskillexchange.internal',
            name: 'Guest Explorer',
            isGuest: true,
          );

      return AuthResponse(
        accessToken: accessToken,
        tokenType: tokenType,
        user: guestUser,
        isGuest: true,
      );
    } on DioException catch (e) {
      throw AuthException(_formatDioError(e), e.response?.statusCode);
    }
  }

  /// Authenticate via Google OAuth using id_token verified by backend.
  Future<AuthResponse> loginWithGoogle({
    required String idToken,
    String? accessToken,
    String? email,
    String? name,
    String? avatarUrl,
  }) async {
    try {
      final payload = <String, dynamic>{'id_token': idToken};
      if (accessToken != null) payload['access_token'] = accessToken;
      if (email != null) payload['email'] = email;
      if (name != null) payload['name'] = name;
      if (avatarUrl != null) payload['avatar_url'] = avatarUrl;

      final response = await _apiClient.dio.post(
        '/auth/google',
        data: payload,
      );
      final token = response.data['access_token'] ?? '';
      final tokenType = response.data['token_type'] ?? 'bearer';
      await TokenStorage.saveToken(token);
      await TokenStorage.saveIsGuest(false);

      final user = await getCurrentUser();
      if (user == null) {
        throw AuthException('Failed to retrieve user profile after Google sign-in.');
      }
      return AuthResponse(
        accessToken: token,
        tokenType: tokenType,
        user: user,
        isGuest: false,
      );
    } on DioException catch (e) {
      throw AuthException(_formatDioError(e), e.response?.statusCode);
    }
  }

  Future<void> logout() async {
    await TokenStorage.clearAll();
  }

  /// Fetch current authenticated user profile.
  Future<User?> getCurrentUser() async {
    final token = await TokenStorage.getToken();
    if (token == null || token.isEmpty) return null;
    try {
      final response = await _apiClient.dio.get('/users/me');
      final isGuest = await TokenStorage.getIsGuest();
      return User.fromJson(response.data, isGuest: isGuest);
    } catch (e) {
      return null;
    }
  }
}

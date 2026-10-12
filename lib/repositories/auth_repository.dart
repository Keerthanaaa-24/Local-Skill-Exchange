import 'package:dio/dio.dart';
import '../core/network/api_client.dart';
import '../core/network/token_storage.dart';
import '../models/auth_models.dart';

class AuthException implements Exception {
  final String message;
  AuthException(this.message);
  @override
  String toString() => message;
}

class AuthRepository {
  final ApiClient _apiClient;

  AuthRepository(this._apiClient);

  /// Login using form‑urlencoded payload expected by FastAPI.
  Future<AuthResponse> login(String email, String password) async {
    final response = await _apiClient.dio.post(
      '/auth/login',
      data: FormData.fromMap({
        'username': email,
        'password': password,
      }),
      options: Options(contentType: Headers.formUrlEncodedContentType),
    );
    final accessToken = response.data['access_token'] ?? '';
    final tokenType = response.data['token_type'] ?? 'bearer';
    await TokenStorage.saveToken(accessToken);
    // After token is stored, fetch the user profile.
    final user = await getCurrentUser();
    if (user == null) {
      throw AuthException('Failed to retrieve user after login');
    }
    return AuthResponse(
      accessToken: accessToken,
      tokenType: tokenType,
      user: user,
    );
  }

  /// Register a new user (backend returns user, no token).
  Future<AuthResponse> register(String name, String email, String password) async {
    await _apiClient.dio.post(
      '/auth/register',
      data: {
        'name': name,
        'email': email,
        'password': password,
      },
    );
    // Perform login to obtain token after successful registration.
    final loginResp = await _apiClient.dio.post(
      '/auth/login',
      data: FormData.fromMap({
        'username': email,
        'password': password,
      }),
      options: Options(contentType: Headers.formUrlEncodedContentType),
    );
    final accessToken = loginResp.data['access_token'] ?? '';
    final tokenType = loginResp.data['token_type'] ?? 'bearer';
    await TokenStorage.saveToken(accessToken);
    final user = await getCurrentUser();
    if (user == null) {
      throw AuthException('Failed to retrieve user after registration');
    }
    return AuthResponse(
      accessToken: accessToken,
      tokenType: tokenType,
      user: user,
    );
  }

  Future<void> logout() async {
    await TokenStorage.clearAll();
  }

  /// Fetch current authenticated user profile.
  Future<User?> getCurrentUser() async {
    final token = await TokenStorage.getToken();
    if (token == null || token.isEmpty) return null;
    final response = await _apiClient.dio.get('/users/me');
    return User.fromJson(response.data);
  }
}

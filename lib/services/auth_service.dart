import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'api_client.dart';
import '../core/network/token_storage.dart';
import '../models/user_model.dart';

class AuthService {
  Future<bool> login(String email, String password) async {
    try {
      final response = await apiClient.dio.post(
        '/auth/login',
        data: {
          'username': email.trim(),
          'password': password,
        },
        options: Options(contentType: Headers.formUrlEncodedContentType),
      );
      
      final token = response.data['access_token'];
      if (token != null) {
        await TokenStorage.saveToken(token.toString());
        await TokenStorage.saveIsGuest(false);
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Login error: $e');
      return false;
    }
  }

  Future<bool> register(String name, String email, String password) async {
    try {
      final response = await apiClient.dio.post(
        '/auth/register',
        data: {
          'name': name.trim(),
          'email': email.trim(),
          'password': password,
        },
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Register error: $e');
      return false;
    }
  }

  Future<void> logout() async {
    await TokenStorage.clearAll();
  }


  Future<User?> getCurrentUser() async {
    try {
      final response = await apiClient.dio.get('/users/me');
      return User.fromJson(response.data);
    } catch (e) {
      debugPrint('Get user error: $e');
      return null;
    }
  }
}

final authService = AuthService();

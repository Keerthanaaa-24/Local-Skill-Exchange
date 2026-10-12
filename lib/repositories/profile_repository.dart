import 'package:dio/dio.dart';
import '../core/network/api_client.dart';
import '../models/profile_models.dart';

class ProfileException implements Exception {
  final String message;
  ProfileException(this.message);
  @override
  String toString() => message;
}

class ProfileRepository {
  final ApiClient _apiClient;

  ProfileRepository(this._apiClient);

  Future<UserProfile> getProfile() async {
    try {
      final response = await _apiClient.dio.get('/users/me');
      return UserProfile.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw ProfileException('Unauthorized. Please log in again.');
      }
      throw ProfileException(_handleDioError(e));
    } catch (e) {
      throw ProfileException('An unexpected error occurred.');
    }
  }

  Future<UpdateProfileResponse> updateProfile(UpdateProfileRequest request) async {
    try {
      final response = await _apiClient.dio.put(
        '/users/me',
        data: request.toJson(),
      );
      return UpdateProfileResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw ProfileException(_handleDioError(e));
    } catch (e) {
      throw ProfileException('An unexpected error occurred.');
    }
  }

  Future<void> changePassword(String currentPassword, String newPassword) async {
    try {
      await _apiClient.dio.post(
        '/users/me/password',
        data: {
          'current_password': currentPassword,
          'new_password': newPassword,
        },
      );
    } on DioException catch (e) {
      throw ProfileException(_handleDioError(e));
    } catch (e) {
      throw ProfileException('An unexpected error occurred.');
    }
  }

  Future<String> uploadProfileImageBytes(List<int> bytes, {String filename = 'profile.png'}) async {
    try {
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(bytes, filename: filename),
      });

      final response = await _apiClient.dio.post(
        '/users/me/image',
        data: formData,
      );
      return response.data['profile_image_url'] ?? response.data['avatar_url'] ?? '';
    } on DioException catch (e) {
      throw ProfileException(_handleDioError(e));
    } catch (e) {
      throw ProfileException('Failed to upload image. Please try again.');
    }
  }

  Future<String> uploadProfileImage(String filePath) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath, filename: 'profile.jpg'),
      });

      final response = await _apiClient.dio.post(
        '/users/me/image',
        data: formData,
      );
      return response.data['profile_image_url'] ?? response.data['avatar_url'] ?? '';
    } on DioException catch (e) {
      throw ProfileException(_handleDioError(e));
    } catch (e) {
      throw ProfileException('An unexpected error occurred.');
    }
  }

  String _handleDioError(DioException e) {
    if (e.response != null && e.response?.data != null) {
      if (e.response?.data is Map && e.response?.data['detail'] != null) {
        return e.response?.data['detail'].toString() ?? 'Server error';
      }
    }
    return 'Network error occurred. Please check your connection.';
  }
}

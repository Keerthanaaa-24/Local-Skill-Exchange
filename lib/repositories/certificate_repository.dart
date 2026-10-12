import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_client.dart';
import '../models/certificate_model.dart';

class CertificateRepository {
  final ApiClient _apiClient;

  CertificateRepository(this._apiClient);

  // Fetch all certificates for current user
  Future<List<CertificateModel>> getCertificates() async {
    try {
      final response = await _apiClient.dio.get('/certificates/');
      final dynamic raw = response.data;
      final List<dynamic> list = (raw is Map && raw.containsKey('data')) ? raw['data'] : raw;
      return list.map((json) => CertificateModel.fromJson(json as Map<String, dynamic>)).toList();
    } catch (e) {
      throw _handleError(e);
    }
  }

  // Fetch single certificate by ID
  Future<CertificateModel> getCertificate(int id) async {
    try {
      final response = await _apiClient.dio.get('/certificates/$id');
      final dynamic raw = response.data;
      final Map<String, dynamic> data = (raw is Map && raw.containsKey('data')) ? raw['data'] : raw;
      return CertificateModel.fromJson(data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  // Issue certificate for a learning path (must be 100% complete)
  Future<CertificateModel> issueCertificate(int learningPathId) async {
    try {
      final response = await _apiClient.dio.post('/certificates/issue/$learningPathId');
      final dynamic raw = response.data;
      final Map<String, dynamic> data = (raw is Map && raw.containsKey('data')) ? raw['data'] : raw;
      return CertificateModel.fromJson(data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  // Public verification of a certificate by verification code
  Future<CertificateVerificationModel> verifyCertificate(String code) async {
    try {
      final response = await _apiClient.dio.get('/certificates/verify/$code');
      final dynamic raw = response.data;
      final Map<String, dynamic> data = (raw is Map && raw.containsKey('data')) ? raw['data'] : raw;
      return CertificateVerificationModel.fromJson(data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Exception _handleError(dynamic error) {
    if (error is DioException) {
      if (error.response?.statusCode == 401) {
        return Exception('Unauthorized: Please log in');
      } else if (error.response?.statusCode == 404) {
        return Exception(error.response?.data['detail'] ?? 'Certificate not found');
      } else if (error.response?.statusCode == 400) {
        return Exception(error.response?.data['detail'] ?? 'Cannot issue certificate');
      } else if (error.response?.statusCode == 500) {
        return Exception('Server Error: Please try again later');
      } else if (error.type == DioExceptionType.connectionError || error.type == DioExceptionType.receiveTimeout) {
        return Exception('Network Error: Please check your connection.');
      }
      return Exception(error.response?.data['detail'] ?? error.message ?? 'An error occurred');
    }
    return Exception(error.toString());
  }
}

// Riverpod provider for CertificateRepository
final certificateRepositoryProvider = Provider<CertificateRepository>((ref) {
  return CertificateRepository(apiClient);
});

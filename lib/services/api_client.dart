import 'package:dio/dio.dart';
import '../core/config/env.dart';
import '../core/network/token_storage.dart';

class ApiClient {
  static String get baseUrl => Env.apiBaseUrl;
  
  final Dio dio;

  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  ApiClient._internal()
      : dio = Dio(BaseOptions(
          baseUrl: Env.apiBaseUrl,
          connectTimeout: const Duration(milliseconds: Env.connectTimeout),
          receiveTimeout: const Duration(milliseconds: Env.receiveTimeout),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        )) {
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Dynamically keep baseUrl up to date with Env.apiBaseUrl
        if (!options.path.startsWith('http://') && !options.path.startsWith('https://')) {
          options.baseUrl = Env.apiBaseUrl;
        }
        final token = await TokenStorage.getToken();
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (DioException e, handler) {
        // Detailed logging for mobile connectivity debugging
        // (Does not expose sensitive credentials)
        return handler.next(e);
      },
    ));
  }
}

final apiClient = ApiClient();

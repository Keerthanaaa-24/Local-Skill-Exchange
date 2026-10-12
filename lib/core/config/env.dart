import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class Env {
  // Base URL for the FastAPI backend. Adjust for web, Android emulator, or other platforms.
  static String get apiBaseUrl {
    if (kIsWeb) return 'http://127.0.0.1:8000/api/v1';
    if (Platform.isAndroid) return 'http://10.0.2.2:8000/api/v1';
    return 'http://127.0.0.1:8000/api/v1';
  }

  static String get serverBaseUrl {
    final base = apiBaseUrl;
    if (base.endsWith('/api/v1')) {
      return base.substring(0, base.length - '/api/v1'.length);
    }
    return base;
  }

  // Timeout settings (in milliseconds)
  static const int connectTimeout = 10000;
  static const int receiveTimeout = 10000;
}

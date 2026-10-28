import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import '../network/token_storage.dart';

class Env {
  // Configured via: flutter run/build --dart-define=API_BASE_URL=http://192.168.1.2:8000/api/v1
  static const String _configuredBaseUrl = String.fromEnvironment('API_BASE_URL');
  
  // Google OAuth Web / Server Client ID (from Google Cloud Console)
  static const String googleServerClientId = String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID', defaultValue: '');
  
  // Default host machine LAN IP on Wi-Fi for physical device access
  static const String defaultLanHost = '192.168.1.2';
  static const int defaultPort = 8000;
  static const int fallbackPort = 8001;

  static String? _inMemoryCustomUrl;

  /// Set and persist a user-configured API URL at runtime
  static void setCustomApiBaseUrl(String? url) {
    if (url != null && url.trim().isNotEmpty) {
      _inMemoryCustomUrl = _normalizeUrl(url.trim());
      TokenStorage.saveCustomApiUrl(_inMemoryCustomUrl!);
    } else {
      _inMemoryCustomUrl = null;
      TokenStorage.delete('custom_api_base_url');
    }
  }

  /// Initialize any previously saved custom API base URL from storage
  static Future<void> loadPersistedUrl() async {
    final saved = await TokenStorage.getCustomApiUrl();
    if (saved != null && saved.trim().isNotEmpty) {
      _inMemoryCustomUrl = _normalizeUrl(saved.trim());
    }
  }

  static String _normalizeUrl(String raw) {
    var url = raw.trim();
    while (url.endsWith('/')) {
      url = url.substring(0, url.length - 1);
    }
    if (!url.endsWith('/api/v1')) {
      url = '$url/api/v1';
    }
    return url;
  }

  /// Base URL for the FastAPI backend.
  /// On physical Android devices: NEVER uses localhost or 127.0.0.1.
  static String get apiBaseUrl {
    // 1. User-customized URL has highest priority
    if (_inMemoryCustomUrl != null && _inMemoryCustomUrl!.isNotEmpty) {
      return _inMemoryCustomUrl!;
    }

    // 2. Build-time defined URL
    if (_configuredBaseUrl.isNotEmpty) {
      return _normalizeUrl(_configuredBaseUrl);
    }

    // 3. Web browsers connect to localhost
    if (kIsWeb) return 'http://127.0.0.1:$defaultPort/api/v1';

    // 4. Android physical device & production APK:
    // Reachable LAN IP of the host development computer
    if (Platform.isAndroid) {
      return 'http://$defaultLanHost:$defaultPort/api/v1';
    }

    // 5. Desktop (Windows, macOS, Linux)
    return 'http://127.0.0.1:$defaultPort/api/v1';
  }

  static String get serverBaseUrl {
    final base = apiBaseUrl;
    if (base.endsWith('/api/v1')) {
      return base.substring(0, base.length - '/api/v1'.length);
    }
    return base;
  }

  // Timeout settings (in milliseconds) - 45s accommodates Render free-tier cold-start spin-ups
  static const int connectTimeout = 45000;
  static const int receiveTimeout = 45000;
}

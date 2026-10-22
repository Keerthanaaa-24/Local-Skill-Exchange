import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  static String? _inMemoryToken;
  static String? _inMemoryRefreshToken;
  static bool? _inMemoryIsGuest;
  static String? _inMemoryCustomApiUrl;

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
      resetOnError: true,
    ),
    webOptions: WebOptions(
      dbName: 'local_skill_exchange',
      publicKey: 'local_skill_exchange',
    ),
  );
  
  static const _tokenKey = 'access_token';
  static const _refreshTokenKey = 'jwt_refresh_token';
  static const _isGuestKey = 'is_guest';
  static const _customApiUrlKey = 'custom_api_base_url';

  static Future<void> saveToken(String token) async {
    _inMemoryToken = token;
    try {
      await _storage.write(key: _tokenKey, value: token);
    } catch (e) {
      debugPrint('TokenStorage saveToken write error: $e');
    }
  }

  static Future<String?> getToken() async {
    if (_inMemoryToken != null && _inMemoryToken!.isNotEmpty) {
      return _inMemoryToken;
    }
    try {
      final token = await _storage.read(key: _tokenKey);
      if (token != null && token.isNotEmpty) {
        _inMemoryToken = token;
        return token;
      }
    } catch (e) {
      debugPrint('TokenStorage getToken read error: $e');
    }
    return _inMemoryToken;
  }

  static Future<void> deleteToken() async {
    _inMemoryToken = null;
    try {
      await _storage.delete(key: _tokenKey);
    } catch (e) {
      debugPrint('TokenStorage deleteToken error: $e');
    }
  }
  
  static Future<void> saveRefreshToken(String token) async {
    _inMemoryRefreshToken = token;
    try {
      await _storage.write(key: _refreshTokenKey, value: token);
    } catch (e) {
      debugPrint('TokenStorage saveRefreshToken error: $e');
    }
  }

  static Future<String?> getRefreshToken() async {
    if (_inMemoryRefreshToken != null && _inMemoryRefreshToken!.isNotEmpty) {
      return _inMemoryRefreshToken;
    }
    try {
      final token = await _storage.read(key: _refreshTokenKey);
      if (token != null && token.isNotEmpty) {
        _inMemoryRefreshToken = token;
        return token;
      }
    } catch (e) {
      debugPrint('TokenStorage getRefreshToken read error: $e');
    }
    return _inMemoryRefreshToken;
  }

  static Future<void> deleteRefreshToken() async {
    _inMemoryRefreshToken = null;
    try {
      await _storage.delete(key: _refreshTokenKey);
    } catch (e) {
      debugPrint('TokenStorage deleteRefreshToken error: $e');
    }
  }

  static Future<void> saveIsGuest(bool isGuest) async {
    _inMemoryIsGuest = isGuest;
    try {
      await _storage.write(key: _isGuestKey, value: isGuest ? 'true' : 'false');
    } catch (e) {
      debugPrint('TokenStorage saveIsGuest error: $e');
    }
  }

  static Future<bool> getIsGuest() async {
    if (_inMemoryIsGuest != null) {
      return _inMemoryIsGuest!;
    }
    try {
      final val = await _storage.read(key: _isGuestKey);
      _inMemoryIsGuest = val == 'true';
      return _inMemoryIsGuest!;
    } catch (e) {
      debugPrint('TokenStorage getIsGuest error: $e');
      return false;
    }
  }

  static Future<void> saveCustomApiUrl(String url) async {
    _inMemoryCustomApiUrl = url.trim();
    try {
      await _storage.write(key: _customApiUrlKey, value: _inMemoryCustomApiUrl);
    } catch (e) {
      debugPrint('TokenStorage saveCustomApiUrl error: $e');
    }
  }

  static Future<String?> getCustomApiUrl() async {
    if (_inMemoryCustomApiUrl != null && _inMemoryCustomApiUrl!.isNotEmpty) {
      return _inMemoryCustomApiUrl;
    }
    try {
      final val = await _storage.read(key: _customApiUrlKey);
      if (val != null && val.trim().isNotEmpty) {
        _inMemoryCustomApiUrl = val.trim();
        return _inMemoryCustomApiUrl;
      }
    } catch (e) {
      debugPrint('TokenStorage getCustomApiUrl error: $e');
    }
    return null;
  }

  static Future<void> write(String key, String value) async {
    try {
      await _storage.write(key: key, value: value);
    } catch (e) {
      debugPrint('TokenStorage write error: $e');
    }
  }

  static Future<String?> read(String key) async {
    try {
      return await _storage.read(key: key);
    } catch (e) {
      debugPrint('TokenStorage read error: $e');
      return null;
    }
  }

  static Future<void> delete(String key) async {
    try {
      await _storage.delete(key: key);
    } catch (e) {
      debugPrint('TokenStorage delete error: $e');
    }
  }

  static Future<void> clearAll() async {
    _inMemoryToken = null;
    _inMemoryRefreshToken = null;
    _inMemoryIsGuest = null;
    try {
      // Clear auth tokens only, preserve custom API URL preference
      await _storage.delete(key: _tokenKey);
      await _storage.delete(key: _refreshTokenKey);
      await _storage.delete(key: _isGuestKey);
    } catch (e) {
      debugPrint('TokenStorage clearAll error: $e');
    }
  }
}

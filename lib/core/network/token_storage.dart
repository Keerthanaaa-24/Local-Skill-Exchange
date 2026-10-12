import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  static String? _inMemoryToken;
  static String? _inMemoryRefreshToken;

  static const _storage = FlutterSecureStorage(
    webOptions: WebOptions(
      dbName: 'local_skill_exchange',
      publicKey: 'local_skill_exchange',
    ),
  );
  
  static const _tokenKey = 'access_token';
  static const _refreshTokenKey = 'jwt_refresh_token';

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
    try {
      await _storage.deleteAll();
    } catch (e) {
      debugPrint('TokenStorage clearAll error: $e');
    }
  }
}


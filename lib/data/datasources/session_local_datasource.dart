import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SessionLocalDatasource {
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userIdKey = 'user_id';

  final FlutterSecureStorage _storage;

  SessionLocalDatasource({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  /// Save session tokens to secure storage
  Future<void> saveSession({
    required String accessToken,
    required String refreshToken,
    required String userId,
  }) async {
    await Future.wait([
      _storage.write(key: _accessTokenKey, value: accessToken),
      _storage.write(key: _refreshTokenKey, value: refreshToken),
      _storage.write(key: _userIdKey, value: userId),
    ]);
  }

  /// Retrieve access token from secure storage
  Future<String?> getAccessToken() async {
    return await _storage.read(key: _accessTokenKey);
  }

  /// Retrieve refresh token from secure storage
  Future<String?> getRefreshToken() async {
    return await _storage.read(key: _refreshTokenKey);
  }

  /// Retrieve user ID from secure storage
  Future<String?> getUserId() async {
    return await _storage.read(key: _userIdKey);
  }

  /// Get all session data
  Future<Map<String, String?>> getSession() async {
    final results = await Future.wait([
      getAccessToken(),
      getRefreshToken(),
      getUserId(),
    ]);
    return {
      'accessToken': results[0],
      'refreshToken': results[1],
      'userId': results[2],
    };
  }

  /// Clear all session data
  Future<void> clearSession() async {
    await Future.wait([
      _storage.delete(key: _accessTokenKey),
      _storage.delete(key: _refreshTokenKey),
      _storage.delete(key: _userIdKey),
    ]);
  }

  /// Check if user has valid session
  Future<bool> hasValidSession() async {
    final session = await getSession();
    return session['accessToken'] != null && session['refreshToken'] != null;
  }
}

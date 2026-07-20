import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  static const _storage = FlutterSecureStorage();

  static const String _sanctumTokenKey = 'sanctum_token';
  static const String _customTokenKey = 'custom_token';
  static const String _userIdKey = 'user_id';
  static const String _userNameKey = 'user_name';
  static const String _userEmailKey = 'user_email';

  // Save auth data after login
  static Future<void> saveAuthData({
    required String sanctumToken,
    required String customToken,
    required int userId,
    required String userName,
    required String userEmail,
  }) async {
    await _storage.write(key: _sanctumTokenKey, value: sanctumToken);
    await _storage.write(key: _customTokenKey, value: customToken);
    await _storage.write(key: _userIdKey, value: userId.toString());
    await _storage.write(key: _userNameKey, value: userName);
    await _storage.write(key: _userEmailKey, value: userEmail);
  }

  // Get sanctum token
  static Future<String?> getToken() async {
    return await _storage.read(key: _sanctumTokenKey);
  }

  // Get custom token
  static Future<String?> getCustomToken() async {
    return await _storage.read(key: _customTokenKey);
  }

  // Get user ID
  static Future<int?> getUserId() async {
    final idString = await _storage.read(key: _userIdKey);
    if (idString != null) {
      return int.tryParse(idString);
    }
    return null;
  }

  // Get user name
  static Future<String?> getUserName() async {
    return await _storage.read(key: _userNameKey);
  }

  // Get user email
  static Future<String?> getUserEmail() async {
    return await _storage.read(key: _userEmailKey);
  }

  // Check if user has valid token
  static Future<bool> hasValidToken() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  // Clear all auth data (on logout)
  static Future<void> clearAll() async {
    await _storage.delete(key: _sanctumTokenKey);
    await _storage.delete(key: _customTokenKey);
    await _storage.delete(key: _userIdKey);
    await _storage.delete(key: _userNameKey);
    await _storage.delete(key: _userEmailKey);
  }
}

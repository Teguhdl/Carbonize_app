import 'package:shared_preferences/shared_preferences.dart';

class TokenStorage {
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
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sanctumTokenKey, sanctumToken);
    await prefs.setString(_customTokenKey, customToken);
    await prefs.setInt(_userIdKey, userId);
    await prefs.setString(_userNameKey, userName);
    await prefs.setString(_userEmailKey, userEmail);
  }

  // Get sanctum token
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_sanctumTokenKey);
  }

  // Get custom token
  static Future<String?> getCustomToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_customTokenKey);
  }

  // Get user ID
  static Future<int?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_userIdKey);
  }

  // Get user name
  static Future<String?> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userNameKey);
  }

  // Get user email
  static Future<String?> getUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userEmailKey);
  }

  // Check if user has valid token
  static Future<bool> hasValidToken() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  // Clear all auth data (on logout)
  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sanctumTokenKey);
    await prefs.remove(_customTokenKey);
    await prefs.remove(_userIdKey);
    await prefs.remove(_userNameKey);
    await prefs.remove(_userEmailKey);
  }
}

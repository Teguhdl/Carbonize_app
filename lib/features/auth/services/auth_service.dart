import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/storage/token_storage.dart';

class AuthService {
  final ApiClient _api = ApiClient();

  // Login with email and password
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await _api.post(ApiEndpoints.login, body: {
        'email': email,
        'password': password,
      });

      final data = response['data'];
      
      // Debug: print token info
      final sanctumToken = data['sanctum_token']?.toString() ?? 'NULL';
      final customToken = data['custom_token']?.toString() ?? 'NULL';
      print('[AuthService] Login response keys: ${data.keys.toList()}');
      print('[AuthService] sanctum_token: ${sanctumToken.length} chars, starts with: ${sanctumToken.substring(0, sanctumToken.length > 20 ? 20 : sanctumToken.length)}...');
      print('[AuthService] custom_token: ${customToken.length} chars, starts with: ${customToken.substring(0, customToken.length > 20 ? 20 : customToken.length)}...');

      // Save auth data locally
      await TokenStorage.saveAuthData(
        sanctumToken: data['sanctum_token'],
        customToken: data['custom_token'],
        userId: data['user']['id'],
        userName: data['user']['name'],
        userEmail: data['user']['email'],
      );
      
      // Debug: verify saved tokens
      final savedSanctum = await TokenStorage.getToken();
      final savedCustom = await TokenStorage.getCustomToken();
      print('[AuthService] Verified saved sanctum: ${savedSanctum != null ? "${savedSanctum.length} chars" : "NULL"}');
      print('[AuthService] Verified saved custom: ${savedCustom != null ? "${savedCustom.length} chars" : "NULL"}');

      return data;
    } catch (e) {
      rethrow;
    }
  }

  // Register with name, email, and password
  Future<Map<String, dynamic>> register(String name, String email, String password) async {
    try {
      final response = await _api.post(ApiEndpoints.register, body: {
        'name': name,
        'email': email,
        'password': password,
      });

      return response['data'] ?? response;
    } catch (e) {
      rethrow;
    }
  }

  // Logout
  Future<void> logout() async {
    try {
      await _api.post(ApiEndpoints.logout);
    } catch (e) {
      // Even if API call fails, clear local tokens
      print('Logout API error: $e');
    } finally {
      await TokenStorage.clearAll();
    }
  }

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    return await TokenStorage.hasValidToken();
  }

  // Change password
  Future<void> changePassword(String oldPassword, String newPassword) async {
    await _api.post(ApiEndpoints.changePassword, body: {
      'old_password': oldPassword,
      'new_password': newPassword,
    });
  }
}

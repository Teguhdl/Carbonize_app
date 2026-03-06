import 'auth_service.dart' as api;
import '../../../core/storage/token_storage.dart';
import '../../../core/models/app_user.dart';

// Re-export AppUser as User for backward compatibility
typedef User = AppUser;

class AuthServiceAdapter {
  final api.AuthService _apiAuth = api.AuthService();
  
  // Cached user info
  AppUser? _cachedUser;

  // Synchronous currentUser getter
  AppUser? get currentUser => _cachedUser;

  // Initialize cached user from local storage  
  Future<void> loadCurrentUser() async {
    final hasToken = await TokenStorage.hasValidToken();
    if (hasToken) {
      final userId = await TokenStorage.getUserId();
      final email = await TokenStorage.getUserEmail();
      final name = await TokenStorage.getUserName();
      if (userId != null) {
        _cachedUser = AppUser(
          uid: userId.toString(),
          email: email,
          displayName: name,
        );
      }
    } else {
      _cachedUser = null;
    }
  }

  // Login with email and password
  Future<Map<String, dynamic>> loginWithEmailAndPassword(
      String email, String password) async {
    final data = await _apiAuth.login(email, password);
    await loadCurrentUser();
    return data;
  }

  // Register with email and password
  Future<Map<String, dynamic>> registerWithEmailAndPassword(
      String email, String password, {String? name}) async {
    return await _apiAuth.register(name ?? email.split('@')[0], email, password);
  }

  // Sign out
  Future<void> signOut() async {
    await _apiAuth.logout();
    _cachedUser = null;
  }

  // Change password
  Future<void> changePassword(String currentPassword, String newPassword) async {
    await _apiAuth.changePassword(currentPassword, newPassword);
  }

  // Check if logged in
  Future<bool> get isLoggedIn => TokenStorage.hasValidToken();
}

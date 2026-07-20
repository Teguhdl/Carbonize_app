import 'dart:io';
import 'package:flutter/foundation.dart';
import 'user_service.dart' as api;

class UserServiceAdapter {
  final api.UserService _apiUser = api.UserService();
  // CarbonService available if needed for consumption operations

  // Get user data - returns a Map matching old format
  Future<Map<String, dynamic>> getUserData(String uid) async {
    try {
      final user = await _apiUser.getProfile();
      return {
        'uid': user.id.toString(),
        'email': user.email,
        'username': user.name,
        'name': user.name,
        'profileImage': user.profileImage,
        'profileImageUrl': user.profileImageUrl,
        'profileImageBase64': null,
        'dailyCarbonLimit': user.dailyCarbonLimit ?? 21.0,
        'dateOfBirth': user.dateOfBirth,
        'createdAt': user.createdAt,
      };
    } catch (e) {
      debugPrint('Error getting user data: $e');
      rethrow;
    }
  }

  // Create user document - no-op, handled by register API
  Future<void> createUserDocument(dynamic user, String username) async {
    debugPrint('createUserDocument: No-op in API mode, user created during registration');
  }

  // Update user data
  Future<void> updateUserData(String uid, Map<String, dynamic> data) async {
    await _apiUser.updateProfile(data);
  }

  // Update last login - no-op, handled by backend
  Future<void> updateLastLogin(String uid) async {
    debugPrint('updateLastLogin: No-op in API mode, handled by backend');
  }

  // Save consumption entry - legacy compatibility wrapper
  // New code should call CarbonService directly instead
  Future<void> saveConsumptionEntry(String uid, Map<String, dynamic> entryData, File? imageFile) async {
    // This is kept for backward compatibility but new dialogs use CarbonService directly
    debugPrint('saveConsumptionEntry: use CarbonService directly instead');
  }

  // Upload profile image
  Future<Map<String, dynamic>> uploadProfileImage(String uid, File imageFile) async {
    return await _apiUser.uploadProfileImage(imageFile);
  }

  // Update entry image
  Future<Map<String, dynamic>> updateEntryImage(String uid, String documentId, File? imageFile) async {
    debugPrint('updateEntryImage: Not yet implemented in API mode');
    return {};
  }
}

import 'dart:io';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/models/user_model.dart';

class UserService {
  final ApiClient _api = ApiClient();

  // Get user profile
  Future<UserModel> getProfile() async {
    final response = await _api.get(ApiEndpoints.profile);
    return UserModel.fromJson(response['data']);
  }

  // Update user profile
  Future<UserModel> updateProfile(Map<String, dynamic> data) async {
    final response = await _api.put(ApiEndpoints.profile, body: data);
    return UserModel.fromJson(response['data']);
  }

  // Upload profile image
  Future<Map<String, dynamic>> uploadProfileImage(File imageFile) async {
    final response = await _api.postMultipart(
      ApiEndpoints.uploadProfileImage,
      fileField: 'image',
      filePath: imageFile.path,
    );
    return response['data'] ?? {};
  }

  // Change password
  Future<void> changePassword(String oldPassword, String newPassword) async {
    await _api.post(ApiEndpoints.changePassword, body: {
      'old_password': oldPassword,
      'new_password': newPassword,
    });
  }
}

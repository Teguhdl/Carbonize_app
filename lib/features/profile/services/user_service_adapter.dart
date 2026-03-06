import 'dart:io';
import 'user_service.dart' as api;
import '../../calculator/services/consumption_service.dart';
import '../../../core/storage/token_storage.dart';

class UserServiceAdapter {
  final api.UserService _apiUser = api.UserService();
  final ConsumptionService _consumptionService = ConsumptionService();

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
      print('Error getting user data: $e');
      rethrow;
    }
  }

  // Create user document - no-op, handled by register API
  Future<void> createUserDocument(dynamic user, String username) async {
    print('createUserDocument: No-op in API mode, user created during registration');
  }

  // Update user data
  Future<void> updateUserData(String uid, Map<String, dynamic> data) async {
    await _apiUser.updateProfile(data);
  }

  // Update last login - no-op, handled by backend
  Future<void> updateLastLogin(String uid) async {
    print('updateLastLogin: No-op in API mode, handled by backend');
  }

  // Save consumption entry
  Future<void> saveConsumptionEntry(String uid, Map<String, dynamic> entryData, File? imageFile) async {
    final factorItemsId = entryData['factor_items_id'] as int? ?? 
                          int.tryParse(entryData['factor_items_id']?.toString() ?? '0') ?? 0;
    final quantity = entryData['quantity'] as double? ??
                     double.tryParse(entryData['quantity']?.toString() ?? '0') ?? 0.0;
    final entryDate = entryData['entry_date']?.toString() ?? 
                      DateTime.now().toIso8601String().split('T')[0];
    
    final metadata = <String, dynamic>{};
    if (entryData.containsKey('metadata')) {
      final metaRaw = entryData['metadata'];
      if (metaRaw is Map) {
        metadata.addAll(Map<String, dynamic>.from(metaRaw));
      }
    }
    if (entryData.containsKey('vehicleType')) metadata['vehicleType'] = entryData['vehicleType'];
    if (entryData.containsKey('fuelType')) metadata['fuelType'] = entryData['fuelType'];
    if (entryData.containsKey('transportationMode')) metadata['transportationMode'] = entryData['transportationMode'];
    
    // Sanitize useCustomEfficiency for PHP compatibility
    // PHP !empty("false") is TRUE, so send "1"/"0" instead of "true"/"false"
    final useCustom = entryData['useCustomEfficiency'] == true;
    metadata['useCustomEfficiency'] = useCustom ? '1' : '0';
    
    if (useCustom && entryData['customEfficiency'] != null && (entryData['customEfficiency'] as num) > 0) {
      metadata['customEfficiency'] = entryData['customEfficiency'];
    } else {
      metadata.remove('customEfficiency');
    }

    await _consumptionService.createEntry(
      factorItemsId: factorItemsId,
      quantity: quantity,
      entryDate: entryDate,
      metadata: metadata.isNotEmpty ? metadata : null,
      imagePath: imageFile?.path,
    );
  }

  // Upload profile image
  Future<Map<String, dynamic>> uploadProfileImage(String uid, File imageFile) async {
    return await _apiUser.uploadProfileImage(imageFile);
  }

  // Update entry image
  Future<Map<String, dynamic>> updateEntryImage(String uid, String documentId, File? imageFile) async {
    print('updateEntryImage: Not yet implemented in API mode');
    return {};
  }
}

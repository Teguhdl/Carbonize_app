import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/models/consumption_entry_model.dart';
import '../../../core/models/emission_factor_model.dart';

class ConsumptionService {
  final ApiClient _api = ApiClient();

  // ============================================
  // EMISSION FACTORS
  // ============================================

  // Get all emission factor categories
  Future<List<EmissionFactorCategory>> getCategories() async {
    final response = await _api.get(ApiEndpoints.emissionCategories);
    final List data = response['data'] ?? [];
    return data.map((json) => EmissionFactorCategory.fromJson(json)).toList();
  }

  // Get emission factor items (optionally filtered by category)
  Future<List<EmissionFactorItem>> getFactors({int? categoryId}) async {
    Map<String, String>? params;
    if (categoryId != null) {
      params = {'category_id': categoryId.toString()};
    }
    final response = await _api.get(ApiEndpoints.emissionFactors, queryParams: params);
    final List data = response['data'] ?? [];
    return data.map((json) => EmissionFactorItem.fromJson(json)).toList();
  }

  // Get factors by category name (convenience method)
  Future<List<EmissionFactorItem>> getFactorsByCategory(String categoryName) async {
    final categories = await getCategories();
    final category = categories.firstWhere(
      (c) => c.categoryName.toLowerCase().contains(categoryName.toLowerCase()),
      orElse: () => EmissionFactorCategory(id: 0, categoryName: ''),
    );
    if (category.id == 0) return [];
    return getFactors(categoryId: category.id);
  }

  // ============================================
  // CONSUMPTION ENTRIES
  // ============================================

  // Create a new consumption entry
  Future<ConsumptionEntryModel> createEntry({
    required int factorItemsId,
    required double quantity,
    required String entryDate,
    Map<String, dynamic>? metadata,
    String? imagePath,
  }) async {
    if (imagePath != null) {
      // Use multipart for image upload
      final fields = <String, String>{
        'factor_items_id': factorItemsId.toString(),
        'quantity': quantity.toString(),
        'entry_date': entryDate,
      };

      // Add metadata fields
      if (metadata != null) {
        metadata.forEach((key, value) {
          fields['metadata[$key]'] = value.toString();
        });
      }

      final response = await _api.postMultipart(
        ApiEndpoints.consumptionEntries,
        fields: fields,
        fileField: 'image',
        filePath: imagePath,
      );
      return ConsumptionEntryModel.fromJson(response['data']);
    } else {
      // Use JSON for entries without images
      final body = <String, dynamic>{
        'factor_items_id': factorItemsId,
        'quantity': quantity,
        'entry_date': entryDate,
      };
      if (metadata != null) {
        body['metadata'] = metadata;
      }

      final response = await _api.post(ApiEndpoints.consumptionEntries, body: body);
      return ConsumptionEntryModel.fromJson(response['data']);
    }
  }

  // Get all consumption entries for the current user
  Future<List<ConsumptionEntryModel>> getEntries({
    String? date,
    String? startDate,
    String? endDate,
  }) async {
    Map<String, String>? params;
    if (date != null || startDate != null || endDate != null) {
      params = {};
      if (date != null) params['date'] = date;
      if (startDate != null) params['start_date'] = startDate;
      if (endDate != null) params['end_date'] = endDate;
    }

    final response = await _api.get(ApiEndpoints.consumptionEntries, queryParams: params);
    final List data = response['data'] ?? [];
    return data.map((json) => ConsumptionEntryModel.fromJson(json)).toList();
  }

  // Get a single consumption entry
  Future<ConsumptionEntryModel> getEntry(int id) async {
    final response = await _api.get('${ApiEndpoints.consumptionEntries}/$id');
    return ConsumptionEntryModel.fromJson(response['data']);
  }

  // Update a consumption entry
  Future<ConsumptionEntryModel> updateEntry(
    int id, {
    int? factorItemsId,
    double? quantity,
    String? entryDate,
    Map<String, dynamic>? metadata,
    String? imagePath,
  }) async {
    if (imagePath != null) {
      // Use multipart for image upload
      final fields = <String, String>{};
      if (factorItemsId != null) fields['factor_items_id'] = factorItemsId.toString();
      if (quantity != null) fields['quantity'] = quantity.toString();
      if (entryDate != null) fields['entry_date'] = entryDate;
      if (metadata != null) {
        metadata.forEach((key, value) {
          fields['metadata[$key]'] = value.toString();
        });
      }

      final response = await _api.postMultipart(
        '${ApiEndpoints.consumptionEntries}/$id',
        fields: fields,
        fileField: 'image',
        filePath: imagePath,
      );
      return ConsumptionEntryModel.fromJson(response['data']);
    } else {
      final body = <String, dynamic>{};
      if (factorItemsId != null) body['factor_items_id'] = factorItemsId;
      if (quantity != null) body['quantity'] = quantity;
      if (entryDate != null) body['entry_date'] = entryDate;
      if (metadata != null) body['metadata'] = metadata;

      final response = await _api.put('${ApiEndpoints.consumptionEntries}/$id', body: body);
      return ConsumptionEntryModel.fromJson(response['data']);
    }
  }

  // Delete a consumption entry
  Future<void> deleteEntry(int id) async {
    await _api.delete('${ApiEndpoints.consumptionEntries}/$id');
  }
}

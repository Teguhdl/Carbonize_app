// consumption_service.dart
// DEPRECATED: Gunakan CarbonService di features/calculator/services/carbon_service.dart
// File ini dipertahankan untuk kompatibilitas screen/widget lain yang belum dimigasi.

import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/models/domain_models.dart';

class ConsumptionService {
  final ApiClient _api = ApiClient();

  // ── Food Items (pengganti getFactorsByCategory 'food') ──────────────
  Future<List<FoodItem>> getFoodItems() async {
    final res = await _api.get(ApiEndpoints.foodItems);
    return (res['data'] as List).map((j) => FoodItem.fromJson(j)).toList();
  }

  // ── Private Vehicles ─────────────────────────────────────────────────
  Future<List<VehicleType>> getVehicleTypes() async {
    final res = await _api.get(ApiEndpoints.privateVehicles);
    return (res['data'] as List).map((j) => VehicleType.fromJson(j)).toList();
  }

  // ── Fuel Types ───────────────────────────────────────────────────────
  Future<List<FuelType>> getFuelTypes() async {
    final res = await _api.get(ApiEndpoints.privateFuels);
    return (res['data'] as List).map((j) => FuelType.fromJson(j)).toList();
  }

  // ── Public Vehicles ──────────────────────────────────────────────────
  Future<List<TransitVehicle>> getPublicVehicles() async {
    final res = await _api.get(ApiEndpoints.publicVehicles);
    return (res['data'] as List).map((j) => TransitVehicle.fromJson(j)).toList();
  }

  // ── Consumption Entries (history) ────────────────────────────────────
  Future<List<ConsumptionEntryModel>> getEntries({
    String? date,
    String? startDate,
    String? endDate,
  }) async {
    final params = <String, String>{};
    if (date != null) params['date'] = date;
    if (startDate != null) params['start_date'] = startDate;
    if (endDate != null) params['end_date'] = endDate;

    final res = await _api.get(
      ApiEndpoints.entries,
      queryParams: params.isEmpty ? null : params,
    );
    return (res['data'] as List)
        .map((j) => ConsumptionEntryModel.fromJson(j))
        .toList();
  }

  Future<void> deleteEntry(int id) async {
    await _api.delete('${ApiEndpoints.entries}/$id');
  }
}

import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/models/domain_models.dart';

/// Service untuk semua domain master-data dan entry submission.
/// Menggantikan EmissionService + ConsumptionService lama.
class CarbonService {
  final ApiClient _api = ApiClient();

  // ─────────────────────────────────────────────────────────
  // FOOD & PACKAGING — Master Data
  // ─────────────────────────────────────────────────────────

  List<FoodItem>? _foodItemsCache;

  Future<List<FoodItem>> getFoodItems({bool forceRefresh = false}) async {
    if (_foodItemsCache != null && !forceRefresh) return _foodItemsCache!;
    final res = await _api.get(ApiEndpoints.foodItems);
    _foodItemsCache =
        (res['data'] as List).map((j) => FoodItem.fromJson(j)).toList();
    return _foodItemsCache!;
  }

  // ─────────────────────────────────────────────────────────
  // TRANSPORT — Master Data
  // ─────────────────────────────────────────────────────────

  List<VehicleType>? _vehiclesCache;
  List<FuelType>?   _fuelsCache;
  List<TransitVehicle>? _transitCache;

  Future<List<VehicleType>> getPrivateVehicles({bool forceRefresh = false}) async {
    if (_vehiclesCache != null && !forceRefresh) return _vehiclesCache!;
    final res = await _api.get(ApiEndpoints.privateVehicles);
    _vehiclesCache =
        (res['data'] as List).map((j) => VehicleType.fromJson(j)).toList();
    return _vehiclesCache!;
  }

  Future<List<FuelType>> getFuelTypes({bool forceRefresh = false}) async {
    if (_fuelsCache != null && !forceRefresh) return _fuelsCache!;
    final res = await _api.get(ApiEndpoints.privateFuels);
    _fuelsCache =
        (res['data'] as List).map((j) => FuelType.fromJson(j)).toList();
    return _fuelsCache!;
  }

  Future<List<TransitVehicle>> getPublicVehicles({bool forceRefresh = false}) async {
    if (_transitCache != null && !forceRefresh) return _transitCache!;
    final res = await _api.get(ApiEndpoints.publicVehicles);
    _transitCache =
        (res['data'] as List).map((j) => TransitVehicle.fromJson(j)).toList();
    return _transitCache!;
  }

  // ─────────────────────────────────────────────────────────
  // FOOD ENTRY — Tambah konsumsi makanan
  // ─────────────────────────────────────────────────────────

  /// quantity = berat dalam kg
  Future<ConsumptionEntryModel> createFoodEntry({
    required int foodItemId,
    required double quantity,
    required String entryDate,
    String? imagePath,
  }) async {
    if (imagePath != null) {
      final res = await _api.postMultipart(
        ApiEndpoints.foodEntries,
        fields: {
          'food_item_id': foodItemId.toString(),
          'quantity': quantity.toString(),
          'entry_date': entryDate,
        },
        fileField: 'image',
        filePath: imagePath,
      );
      return ConsumptionEntryModel.fromJson(res['data']);
    }
    final res = await _api.post(ApiEndpoints.foodEntries, body: {
      'food_item_id': foodItemId,
      'quantity': quantity,
      'entry_date': entryDate,
    });
    return ConsumptionEntryModel.fromJson(res['data']);
  }

  // ─────────────────────────────────────────────────────────
  // TRANSPORT ENTRY — Kendaraan Pribadi
  // ─────────────────────────────────────────────────────────

  /// quantity = jarak dalam km
  Future<ConsumptionEntryModel> createPrivateVehicleEntry({
    required int vehicleTypeId,
    required int fuelTypeId,
    required double distanceKm,
    double? customEfficiency,
    required String entryDate,
    String? imagePath,
  }) async {
    final body = <String, dynamic>{
      'mode': 'private',
      'vehicle_type_id': vehicleTypeId,
      'fuel_type_id': fuelTypeId,
      'quantity': distanceKm,
      'entry_date': entryDate,
      if (customEfficiency != null) 'custom_efficiency': customEfficiency,
    };

    if (imagePath != null) {
      final fields = body.map((k, v) => MapEntry(k, v.toString()));
      final res = await _api.postMultipart(
        ApiEndpoints.transportEntries,
        fields: fields,
        fileField: 'image',
        filePath: imagePath,
      );
      return ConsumptionEntryModel.fromJson(res['data']);
    }
    final res =
        await _api.post(ApiEndpoints.transportEntries, body: body);
    return ConsumptionEntryModel.fromJson(res['data']);
  }

  // ─────────────────────────────────────────────────────────
  // TRANSPORT ENTRY — Transportasi Umum
  // ─────────────────────────────────────────────────────────

  /// quantity = jarak dalam km
  Future<ConsumptionEntryModel> createPublicTransitEntry({
    required int transitVehicleId,
    required double distanceKm,
    required String entryDate,
    String? imagePath,
  }) async {
    final body = <String, dynamic>{
      'mode': 'public',
      'transit_vehicle_id': transitVehicleId,
      'quantity': distanceKm,
      'entry_date': entryDate,
    };

    if (imagePath != null) {
      final fields = body.map((k, v) => MapEntry(k, v.toString()));
      final res = await _api.postMultipart(
        ApiEndpoints.transportEntries,
        fields: fields,
        fileField: 'image',
        filePath: imagePath,
      );
      return ConsumptionEntryModel.fromJson(res['data']);
    }
    final res =
        await _api.post(ApiEndpoints.transportEntries, body: body);
    return ConsumptionEntryModel.fromJson(res['data']);
  }

  // ─────────────────────────────────────────────────────────
  // HISTORY — Riwayat semua domain
  // ─────────────────────────────────────────────────────────

  Future<List<ConsumptionEntryModel>> getEntries({
    String? date,
    String? startDate,
    String? endDate,
    String? entryType, // 'food' | 'private_vehicle' | 'public_transit'
  }) async {
    final params = <String, String>{};
    if (date != null) params['date'] = date;
    if (startDate != null) params['start_date'] = startDate;
    if (endDate != null) params['end_date'] = endDate;
    if (entryType != null) params['entry_type'] = entryType;

    final res = await _api.get(
      ApiEndpoints.entries,
      queryParams: params.isEmpty ? null : params,
    );
    return (res['data'] as List)
        .map((j) => ConsumptionEntryModel.fromJson(j))
        .toList();
  }

  Future<ConsumptionEntryModel> getEntry(int id) async {
    final res = await _api.get('${ApiEndpoints.entries}/$id');
    return ConsumptionEntryModel.fromJson(res['data']);
  }

  Future<void> deleteEntry(int id) async {
    await _api.delete('${ApiEndpoints.entries}/$id');
  }

  // ─────────────────────────────────────────────────────────
  // CACHE MANAGEMENT
  // ─────────────────────────────────────────────────────────

  void clearCache() {
    _foodItemsCache = null;
    _vehiclesCache  = null;
    _fuelsCache     = null;
    _transitCache   = null;
  }
}

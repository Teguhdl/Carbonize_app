import 'consumption_service.dart';

class EmissionService {
  final ConsumptionService _apiService = ConsumptionService();
  
  // Cache for emission factor data
  Map<String, Map<String, dynamic>>? _foodFactorsCache;
  Map<String, double>? _fixedValuesCache;
  Map<String, double>? _fuelFactorsCache;
  Map<String, double>? _vehicleEfficiencyCache;
  Map<String, double>? _publicTransportFactorsCache;
  Map<String, int>? _publicTransportPassengersCache;
  
  // Cache for factor item ID lookups (name → id)
  final Map<String, Map<String, int>> _factorItemIdCache = {};

  /// Look up the factor_items_id for a given item name and category.
  /// Returns 0 if not found.
  Future<int> getFactorItemId(String categoryName, String itemName) async {
    // Build cache for this category if not yet cached
    if (!_factorItemIdCache.containsKey(categoryName)) {
      final items = await _apiService.getFactorsByCategory(categoryName);
      _factorItemIdCache[categoryName] = {};
      for (final item in items) {
        _factorItemIdCache[categoryName]![item.name] = item.id;
        
        // For public transport items, also cache by clean name
        // e.g., 'City Bus (Emission)' -> also cached as 'City Bus'
        if (item.name.contains('(Emission)')) {
          final cleanName = item.name.replaceAll('(Emission)', '').trim();
          _factorItemIdCache[categoryName]![cleanName] = item.id;
        }
      }
    }
    return _factorItemIdCache[categoryName]?[itemName] ?? 0;
  }

  // Get food emission factors
  Future<Map<String, Map<String, dynamic>>> getFoodEmissionFactors() async {
    if (_foodFactorsCache != null) return _foodFactorsCache!;
    
    final items = await _apiService.getFactorsByCategory('food');
    _foodFactorsCache = {};
    for (final item in items) {
      _foodFactorsCache![item.name] = {
        'value': double.tryParse(item.value ?? '0') ?? 0,
        'climatiq_id': item.climatiqId,
      };
    }
    return _foodFactorsCache!;
  }

  // Get fixed emission values
  Future<Map<String, double>> getFixedEmissionValues() async {
    if (_fixedValuesCache != null) return _fixedValuesCache!;
    
    final items = await _apiService.getFactorsByCategory('fixed');
    _fixedValuesCache = {};
    for (final item in items) {
      _fixedValuesCache![item.name] = double.tryParse(item.value ?? '0') ?? 0;
    }
    return _fixedValuesCache!;
  }

  // Get fuel emission factors
  Future<Map<String, double>> getFuelEmissionFactors() async {
    if (_fuelFactorsCache != null) return _fuelFactorsCache!;
    
    final items = await _apiService.getFactorsByCategory('fuel');
    _fuelFactorsCache = {};
    for (final item in items) {
      _fuelFactorsCache![item.name] = double.tryParse(item.value ?? '0') ?? 0;
    }
    return _fuelFactorsCache!;
  }

  // Get vehicle efficiency values
  Future<Map<String, double>> getVehicleEfficiencyValues() async {
    if (_vehicleEfficiencyCache != null) return _vehicleEfficiencyCache!;
    
    final items = await _apiService.getFactorsByCategory('vehicle');
    _vehicleEfficiencyCache = {};
    for (final item in items) {
      _vehicleEfficiencyCache![item.name] = double.tryParse(item.value ?? '0') ?? 0;
    }
    return _vehicleEfficiencyCache!;
  }

  // Get public transport emission factors
  // Backend has items like 'City Bus (Emission)' under 'Public Transport' category
  Future<Map<String, double>> getPublicTransportEmissionFactors() async {
    if (_publicTransportFactorsCache != null) return _publicTransportFactorsCache!;
    
    final items = await _apiService.getFactorsByCategory('public transport');
    _publicTransportFactorsCache = {};
    for (final item in items) {
      if (item.name.contains('(Emission)')) {
        // Extract vehicle name: 'City Bus (Emission)' -> 'City Bus'
        final vehicleName = item.name.replaceAll('(Emission)', '').trim();
        _publicTransportFactorsCache![vehicleName] = double.tryParse(item.value ?? '0') ?? 0;
      }
    }
    return _publicTransportFactorsCache!;
  }

  // Get public transport average passengers
  // Backend has items like 'City Bus (Passengers)' under 'Public Transport' category
  Future<Map<String, int>> getPublicTransportAveragePassengers() async {
    if (_publicTransportPassengersCache != null) return _publicTransportPassengersCache!;
    
    final items = await _apiService.getFactorsByCategory('public transport');
    _publicTransportPassengersCache = {};
    for (final item in items) {
      if (item.name.contains('(Passengers)')) {
        // Extract vehicle name: 'City Bus (Passengers)' -> 'City Bus'
        final vehicleName = item.name.replaceAll('(Passengers)', '').trim();
        _publicTransportPassengersCache![vehicleName] = int.tryParse(item.value ?? '0') ?? 0;
      }
    }
    return _publicTransportPassengersCache!;
  }

  // Calculate food emissions
  Future<double> calculateFoodEmissions(String itemType, double quantity) async {
    final factors = await getFoodEmissionFactors();
    if (factors.containsKey(itemType)) {
      final factor = factors[itemType]!;
      final value = factor['value'] as double? ?? 0;
      return quantity * value;
    }
    return 0;
  }

  // Calculate fuel emissions
  Future<double> calculateFuelEmissions({
    required double distance,
    required String fuelType,
    required String vehicleType,
    double? customEfficiency,
  }) async {
    final fuelFactors = await getFuelEmissionFactors();
    final vehicleEfficiency = await getVehicleEfficiencyValues();
    
    final emissionFactor = fuelFactors[fuelType] ?? 0;
    final efficiency = customEfficiency ?? vehicleEfficiency[vehicleType] ?? 1;
    
    if (efficiency <= 0) return 0;
    return (distance / efficiency) * emissionFactor;
  }

  // Calculate public transport emissions
  Future<double> calculatePublicTransportEmissions({
    required double distance,
    required String vehicleType,
  }) async {
    final factors = await getPublicTransportEmissionFactors();
    final passengers = await getPublicTransportAveragePassengers();
    
    final emissionFactor = factors[vehicleType] ?? 0;
    final avgPassengers = passengers[vehicleType] ?? 1;
    
    if (avgPassengers <= 0) return 0;
    return (emissionFactor * distance) / avgPassengers;
  }

  // Get food item names for dropdown (dynamic from API)
  Future<List<String>> getFoodItemNames() async {
    final factors = await getFoodEmissionFactors();
    final names = factors.keys.toList();
    names.sort();
    return names;
  }

  // Get vehicle type names for dropdown (dynamic from API)
  Future<List<String>> getVehicleTypeNames() async {
    final factors = await getVehicleEfficiencyValues();
    final names = factors.keys.toList();
    names.sort();
    return names;
  }

  // Get public transport type names for dropdown (dynamic from API)
  Future<List<String>> getPublicTransportTypeNames() async {
    final factors = await getPublicTransportEmissionFactors();
    final names = factors.keys.toList();
    names.sort();
    return names;
  }

  // Get fuel type names for dropdown (dynamic from API)
  Future<List<String>> getFuelTypeNames() async {
    final factors = await getFuelEmissionFactors();
    final names = factors.keys.toList();
    names.sort();
    return names;
  }

  // Clear cache
  void clearCache() {
    _foodFactorsCache = null;
    _fixedValuesCache = null;
    _fuelFactorsCache = null;
    _vehicleEfficiencyCache = null;
    _publicTransportFactorsCache = null;
    _publicTransportPassengersCache = null;
  }
}

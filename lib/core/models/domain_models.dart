// ─────────────────────────────────────────────────────────────────────────────
// FOOD & PACKAGING MODELS
// ─────────────────────────────────────────────────────────────────────────────

class FoodItem {
  final int id;
  final String name;
  final String calculationMethod; // 'fixed' | 'climatiq'
  final double? emissionFactor;
  final String? climatiqId;

  const FoodItem({
    required this.id,
    required this.name,
    required this.calculationMethod,
    this.emissionFactor,
    this.climatiqId,
  });

  factory FoodItem.fromJson(Map<String, dynamic> json) {
    return FoodItem(
      id: json['id'] as int,
      name: json['name'] ?? '',
      calculationMethod: json['calculation_method'] ?? 'fixed',
      emissionFactor: json['emission_factor'] != null
          ? double.tryParse(json['emission_factor'].toString())
          : null,
      climatiqId: json['climatiq_id'],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TRANSPORT MODELS
// ─────────────────────────────────────────────────────────────────────────────

class VehicleType {
  final int id;
  final String name;
  final double defaultEfficiency; // km/liter

  const VehicleType({
    required this.id,
    required this.name,
    required this.defaultEfficiency,
  });

  factory VehicleType.fromJson(Map<String, dynamic> json) {
    return VehicleType(
      id: json['id'] as int,
      name: json['name'] ?? '',
      defaultEfficiency: double.tryParse(json['default_efficiency'].toString()) ?? 0,
    );
  }
}

class FuelType {
  final int id;
  final String name;
  final double emissionFactor; // kgCO2e/liter

  const FuelType({
    required this.id,
    required this.name,
    required this.emissionFactor,
  });

  factory FuelType.fromJson(Map<String, dynamic> json) {
    return FuelType(
      id: json['id'] as int,
      name: json['name'] ?? '',
      emissionFactor: double.tryParse(json['emission_factor'].toString()) ?? 0,
    );
  }
}

class TransitVehicle {
  final int id;
  final String name;
  final double emissionFactor; // kgCO2e/km per kendaraan
  final double avgPassengers;

  const TransitVehicle({
    required this.id,
    required this.name,
    required this.emissionFactor,
    required this.avgPassengers,
  });

  factory TransitVehicle.fromJson(Map<String, dynamic> json) {
    return TransitVehicle(
      id: json['id'] as int,
      name: json['name'] ?? '',
      emissionFactor: double.tryParse(json['emission_factor'].toString()) ?? 0,
      avgPassengers: double.tryParse(json['avg_passengers'].toString()) ?? 1,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CONSUMPTION ENTRY MODEL
// ─────────────────────────────────────────────────────────────────────────────

/// entry_type values: 'food' | 'private_vehicle' | 'public_transit'
class ConsumptionEntryModel {
  final int id;
  final int userId;
  final String entryType;
  final String entryDate;
  final double quantity;
  final double emissions;
  final String? image;
  final String? createdAt;

  // Relations — nullable based on entry_type
  final FoodItem? foodItem;
  final VehicleType? vehicleType;
  final FuelType? fuelType;
  final TransitVehicle? transitVehicle;

  const ConsumptionEntryModel({
    required this.id,
    required this.userId,
    required this.entryType,
    required this.entryDate,
    required this.quantity,
    required this.emissions,
    this.image,
    this.createdAt,
    this.foodItem,
    this.vehicleType,
    this.fuelType,
    this.transitVehicle,
  });

  factory ConsumptionEntryModel.fromJson(Map<String, dynamic> json) {
    return ConsumptionEntryModel(
      id:         json['id'] as int,
      userId:     (json['user_id'] as num?)?.toInt() ?? 0,
      entryType:  json['entry_type'] ?? '',
      entryDate:  json['entry_date'] ?? '',
      quantity:   double.tryParse(json['quantity'].toString()) ?? 0,
      emissions:  double.tryParse(json['emissions'].toString()) ?? 0,
      image:      json['image'],
      createdAt:  json['created_at'],
      foodItem:   json['food_item'] != null
          ? FoodItem.fromJson(json['food_item'])
          : null,
      vehicleType: json['vehicle_type'] != null
          ? VehicleType.fromJson(json['vehicle_type'])
          : null,
      fuelType: json['fuel_type'] != null
          ? FuelType.fromJson(json['fuel_type'])
          : null,
      transitVehicle: json['transit_vehicle'] != null
          ? TransitVehicle.fromJson(json['transit_vehicle'])
          : null,
    );
  }

  // ── Helper Getters ─────────────────────────────────────────

  /// Readable label berdasarkan entry_type
  String get displayLabel {
    switch (entryType) {
      case 'food':
        return foodItem?.name ?? 'Unknown Food';
      case 'private_vehicle':
        final v = vehicleType?.name ?? '';
        final f = fuelType?.name ?? '';
        return '$v ($f)';
      case 'public_transit':
        return transitVehicle?.name ?? 'Unknown Transit';
      default:
        return entryType;
    }
  }

  /// Category label untuk display (Food & Packaging / Transport)
  String get categoryLabel {
    switch (entryType) {
      case 'food':
        return 'Food & Packaging';
      case 'private_vehicle':
        return 'Private Vehicle';
      case 'public_transit':
        return 'Public Transit';
      default:
        return entryType;
    }
  }

  bool get isFood => entryType == 'food';
  bool get isTransport =>
      entryType == 'private_vehicle' || entryType == 'public_transit';
}

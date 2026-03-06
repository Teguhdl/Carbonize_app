class ConsumptionEntryModel {
  final int id;
  final int userId;
  final int factorItemsId;
  final double quantity;
  final double emissions;
  final String entryDate;
  final String? image;
  final Map<String, dynamic>? metadata;
  final String? createdAt;
  final String? updatedAt;
  final Map<String, dynamic>? factorItem;

  ConsumptionEntryModel({
    required this.id,
    required this.userId,
    required this.factorItemsId,
    required this.quantity,
    required this.emissions,
    required this.entryDate,
    this.image,
    this.metadata,
    this.createdAt,
    this.updatedAt,
    this.factorItem,
  });

  factory ConsumptionEntryModel.fromJson(Map<String, dynamic> json) {
    return ConsumptionEntryModel(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      userId: json['user_id'] is int
          ? json['user_id']
          : int.parse(json['user_id'].toString()),
      factorItemsId: json['factor_items_id'] is int
          ? json['factor_items_id']
          : int.parse(json['factor_items_id'].toString()),
      quantity: json['quantity'] is double
          ? json['quantity']
          : double.parse(json['quantity'].toString()),
      emissions: json['emissions'] is double
          ? json['emissions']
          : double.parse(json['emissions'].toString()),
      entryDate: json['entry_date'] ?? '',
      image: json['image'],
      metadata: json['metadata'] is Map<String, dynamic>
          ? json['metadata']
          : null,
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      factorItem: json['factor_item'] is Map<String, dynamic>
          ? json['factor_item']
          : null,
    );
  }

  // Helper getters for metadata
  String get vehicleType => metadata?['vehicleType'] ?? '';
  String get fuelType => metadata?['fuelType'] ?? '';
  String get transportationMode => metadata?['transportationMode'] ?? '';
  bool get useCustomEfficiency => metadata?['useCustomEfficiency'] == true ||
      metadata?['useCustomEfficiency'] == 'true';
  double? get customEfficiency {
    final val = metadata?['customEfficiency'];
    if (val == null) return null;
    return val is double ? val : double.tryParse(val.toString());
  }

  // Helper getter for factor item name
  String get factorItemName => factorItem?['name'] ?? '';
  String get categoryName => factorItem?['category']?['category_name'] ?? '';
}

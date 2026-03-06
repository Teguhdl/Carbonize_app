class EmissionFactorCategory {
  final int id;
  final String categoryName;

  EmissionFactorCategory({
    required this.id,
    required this.categoryName,
  });

  factory EmissionFactorCategory.fromJson(Map<String, dynamic> json) {
    return EmissionFactorCategory(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      categoryName: json['category_name'] ?? '',
    );
  }
}

class EmissionFactorItem {
  final int id;
  final int factorCategoryId;
  final String name;
  final String? value;
  final String? climatiqId;
  final EmissionFactorCategory? category;

  EmissionFactorItem({
    required this.id,
    required this.factorCategoryId,
    required this.name,
    this.value,
    this.climatiqId,
    this.category,
  });

  factory EmissionFactorItem.fromJson(Map<String, dynamic> json) {
    return EmissionFactorItem(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      factorCategoryId: json['factor_category_id'] is int
          ? json['factor_category_id']
          : int.parse(json['factor_category_id'].toString()),
      name: json['name'] ?? '',
      value: json['value']?.toString(),
      climatiqId: json['climatiq_id'],
      category: json['category'] != null
          ? EmissionFactorCategory.fromJson(json['category'])
          : null,
    );
  }
}

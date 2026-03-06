import 'dart:io';

/// Represents a local consumption entry for display in calculator screen.
class ConsumptionEntry {
  final String category;
  final String itemType;
  final double quantity;
  final DateTime date;
  final File? image;
  final double emissions;
  final String? imageUrl;
  final Map<String, dynamic>? metadata;
  final String? documentId; // API entry ID

  ConsumptionEntry({
    required this.category,
    required this.itemType,
    required this.quantity,
    required this.date,
    this.image,
    required this.emissions,
    this.imageUrl,
    this.metadata,
    this.documentId,
  });
}

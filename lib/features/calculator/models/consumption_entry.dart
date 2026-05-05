import 'dart:io';
import '../../../core/models/domain_models.dart';

/// UI model untuk menampilkan entry di calculator screen.
/// Dibuat dari ConsumptionEntryModel (API response).
class ConsumptionEntry {
  final String category;   // 'Food & Packaging' | 'Private Vehicle' | 'Public Transit'
  final String itemType;   // Nama item/kendaraan
  final double quantity;
  final DateTime date;
  final File? image;
  final double emissions;
  final String? imageUrl;
  final String? documentId; // ID entry di API
  final String entryType;   // 'food' | 'private_vehicle' | 'public_transit'

  ConsumptionEntry({
    required this.category,
    required this.itemType,
    required this.quantity,
    required this.date,
    required this.emissions,
    required this.entryType,
    this.image,
    this.imageUrl,
    this.documentId,
  });

  /// Factory dari API response model
  factory ConsumptionEntry.fromApiModel(ConsumptionEntryModel model) {
    return ConsumptionEntry(
      category:   model.categoryLabel,
      itemType:   model.displayLabel,
      quantity:   model.quantity,
      date:       DateTime.tryParse(model.entryDate) ?? DateTime.now(),
      emissions:  model.emissions,
      entryType:  model.entryType,
      imageUrl:   model.image,
      documentId: model.id.toString(),
    );
  }

  bool get isFood      => entryType == 'food';
  bool get isTransport => entryType == 'private_vehicle' || entryType == 'public_transit';
}

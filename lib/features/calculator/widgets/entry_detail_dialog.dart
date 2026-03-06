import 'package:flutter/material.dart';

import '../models/consumption_entry.dart';
import '../../auth/services/auth_service_adapter.dart';
import '../../profile/services/user_service_adapter.dart';
import '../services/consumption_service.dart';


/// Shows the entry detail dialog with image, metadata and delete/edit actions.
Future<void> showEntryDetailDialog({
  required BuildContext context,
  required ConsumptionEntry entry,
  required AuthServiceAdapter authService,
  required UserServiceAdapter userService,
  required VoidCallback onEntryDeleted,
  required void Function(ConsumptionEntry) onEditEntry,
}) {
  return showDialog(
    context: context,
    builder: (BuildContext context) {
      return _EntryDetailDialog(
        entry: entry,
        authService: authService,
        userService: userService,
        onEntryDeleted: onEntryDeleted,
        onEditEntry: onEditEntry,
      );
    },
  );
}

class _EntryDetailDialog extends StatelessWidget {
  final ConsumptionEntry entry;
  final AuthServiceAdapter authService;
  final UserServiceAdapter userService;
  final VoidCallback onEntryDeleted;
  final void Function(ConsumptionEntry) onEditEntry;

  const _EntryDetailDialog({
    required this.entry,
    required this.authService,
    required this.userService,
    required this.onEntryDeleted,
    required this.onEditEntry,
  });

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate = _formatDate(entry.date);
    final formattedEmissions = entry.emissions.toStringAsFixed(2);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.zero,
      child: Container(
        width: double.infinity,
        height: double.infinity,
        color: const Color(0xFFE4FFAC),
        child: Column(
          children: [
            // Header
            Container(
              color: const Color(0xFFEFEFEF),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.close, color: Color(0xFF626F47), size: 24),
                  ),
                  const Expanded(
                    child: Center(
                      child: Text(
                        'Entry Detail',
                        style: TextStyle(color: Color(0xFF626F47), fontSize: 18, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(width: 24),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Image
                    Center(
                      child: Container(
                        width: 250,
                        height: 250,
                        decoration: BoxDecoration(
                          color: const Color(0x66D9D9D9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: _buildImageContent(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Details
                    _buildDetailRow('Category', entry.category),
                    _buildDetailRow('Item Type', entry.itemType),
                    _buildDetailRow('Quantity', entry.quantity.toStringAsFixed(2)),
                    _buildDetailRow('Date', formattedDate),
                    _buildDetailRow('Emissions', '$formattedEmissions kg CO2e'),

                    // Metadata details for fuel entries
                    if (entry.metadata != null) ...[
                      if (entry.metadata!['transportationMode'] != null)
                        _buildDetailRow('Transport Mode', entry.metadata!['transportationMode']),
                      if (entry.metadata!['fuelType'] != null)
                        _buildDetailRow('Fuel Type', entry.metadata!['fuelType']),
                      if (entry.metadata!['useCustomEfficiency'] == true && entry.metadata!['customEfficiency'] != null)
                        _buildDetailRow('Custom Efficiency', '${entry.metadata!['customEfficiency']} km/l'),
                    ],

                    const SizedBox(height: 30),

                    // Action buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Edit button
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            onEditEntry(entry);
                          },
                          icon: const Icon(Icons.edit, size: 18),
                          label: const Text('Edit'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF626F47),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                        // Delete button
                        ElevatedButton.icon(
                          onPressed: () => _showDeleteConfirmation(context),
                          icon: const Icon(Icons.delete, size: 18),
                          label: const Text('Delete'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red[700],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(label,
                style: const TextStyle(color: Color(0xFF5D6C24), fontSize: 14, fontWeight: FontWeight.w600)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(color: Color(0xFF626F47), fontSize: 14)),
          ),
        ],
      ),
    );
  }

  Widget _buildImageContent() {
    // Try network image first
    if (entry.imageUrl != null && entry.imageUrl!.isNotEmpty) {
      return Image.network(
        entry.imageUrl!,
        width: 250,
        height: 250,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          print('Error loading network image: $error');
          return _buildLocalImageOrPlaceholder();
        },
      );
    }
    return _buildLocalImageOrPlaceholder();
  }

  Widget _buildLocalImageOrPlaceholder() {
    if (entry.image != null && entry.image!.existsSync()) {
      return Image.file(
        entry.image!,
        width: 250,
        height: 250,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildPlaceholder();
        },
      );
    }
    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    return Container(
      width: 250,
      height: 250,
      color: const Color(0x66D9D9D9),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.image_not_supported, size: 48, color: Color(0xFFA4B465)),
            SizedBox(height: 8),
            Text('No image available', style: TextStyle(color: Color(0xFFA4B465), fontSize: 14)),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFFE4FFAC),
          title: const Text('Delete Entry',
              style: TextStyle(color: Color(0xFF5D6C24), fontWeight: FontWeight.bold)),
          content: const Text('Are you sure you want to delete this consumption entry? This action cannot be undone.',
              style: TextStyle(color: Color(0xFF5D6C24))),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel', style: TextStyle(color: Color(0xFF626F47))),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(dialogContext); // Close confirmation
                Navigator.pop(context); // Close detail dialog
                
                // Delete via API
                if (entry.documentId != null) {
                  try {
                    final consumptionService = ConsumptionService();
                    await consumptionService.deleteEntry(int.parse(entry.documentId!));
                    print('Entry deleted from API');
                  } catch (e) {
                    print('Error deleting from API: $e');
                  }
                }
                
                onEntryDeleted();
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }
}

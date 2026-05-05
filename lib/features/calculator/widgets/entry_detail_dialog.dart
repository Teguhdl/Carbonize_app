import 'package:flutter/material.dart';

import '../models/consumption_entry.dart';
import '../../auth/services/auth_service_adapter.dart';
import '../../profile/services/user_service_adapter.dart';
import '../services/carbon_service.dart';

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
    final formattedDate      = _formatDate(entry.date);
    final formattedEmissions = entry.emissions.toStringAsFixed(4);
    final unit = entry.isFood ? 'kg' : 'km';

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.zero,
      child: Container(
        width: double.infinity,
        height: double.infinity,
        color: const Color(0xFFE4FFAC),
        child: Column(children: [
          // Header
          Container(
            color: const Color(0xFFEFEFEF),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(Icons.close, color: Color(0xFF626F47), size: 24),
              ),
              const Expanded(child: Center(child: Text('Entry Detail',
                  style: TextStyle(color: Color(0xFF626F47), fontSize: 18, fontWeight: FontWeight.w600)))),
              const SizedBox(width: 24),
            ]),
          ),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                // Image
                Center(
                  child: Container(
                    width: 250, height: 250,
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

                // Core details
                _buildDetailRow('Category',  entry.category),
                _buildDetailRow('Item',      entry.itemType),
                _buildDetailRow('Quantity',  '${entry.quantity.toStringAsFixed(2)} $unit'),
                _buildDetailRow('Date',      formattedDate),
                _buildDetailRow('Emissions', '$formattedEmissions kg CO2e'),

                // Transport-specific extras
                if (entry.entryType == 'private_vehicle')
                  _buildDetailRow('Mode', 'Private Vehicle'),
                if (entry.entryType == 'public_transit')
                  _buildDetailRow('Mode', 'Public Transit'),

                const SizedBox(height: 30),

                // Action buttons
                Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      onEditEntry(entry);
                    },
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text('Edit'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF626F47), foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _showDeleteConfirmation(context),
                    icon: const Icon(Icons.delete, size: 18),
                    label: const Text('Delete'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[700], foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ]),
              ]),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(width: 140, child: Text(label,
            style: const TextStyle(color: Color(0xFF5D6C24), fontSize: 14, fontWeight: FontWeight.w600))),
        Expanded(child: Text(value,
            style: const TextStyle(color: Color(0xFF626F47), fontSize: 14))),
      ]),
    );
  }

  Widget _buildImageContent() {
    if (entry.imageUrl != null && entry.imageUrl!.isNotEmpty) {
      return Image.network(
        entry.imageUrl!,
        width: 250, height: 250, fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildLocalImageOrPlaceholder(),
      );
    }
    return _buildLocalImageOrPlaceholder();
  }

  Widget _buildLocalImageOrPlaceholder() {
    if (entry.image != null && entry.image!.existsSync()) {
      return Image.file(entry.image!, width: 250, height: 250, fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildPlaceholder());
    }
    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    return Container(
      width: 250, height: 250, color: const Color(0x66D9D9D9),
      child: const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.image_not_supported, size: 48, color: Color(0xFFA4B465)),
        SizedBox(height: 8),
        Text('No image available', style: TextStyle(color: Color(0xFFA4B465), fontSize: 14)),
      ])),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFFE4FFAC),
        title: const Text('Delete Entry',
            style: TextStyle(color: Color(0xFF5D6C24), fontWeight: FontWeight.bold)),
        content: const Text('Yakin hapus entri ini? Tidak dapat dibatalkan.',
            style: TextStyle(color: Color(0xFF5D6C24))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF626F47))),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              Navigator.pop(context);
              if (entry.documentId != null) {
                try {
                  await CarbonService().deleteEntry(int.parse(entry.documentId!));
                } catch (e) {
                  debugPrint('Error deleting entry: $e');
                }
              }
              onEntryDeleted();
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

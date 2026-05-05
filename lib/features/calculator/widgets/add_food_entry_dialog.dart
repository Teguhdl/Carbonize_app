import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:intl/intl.dart';
import '../../../core/models/domain_models.dart';
import '../services/carbon_service.dart';
import '../widgets/custom_dropdown.dart';
import '../../auth/services/auth_service_adapter.dart';
import '../../profile/services/user_service_adapter.dart';

Future<void> showAddFoodEntryDialog({
  required BuildContext context,
  required CarbonService carbonService,
  required AuthServiceAdapter authService,
  required UserServiceAdapter userService,
  required DateTime viewDate,
  required VoidCallback onEntrySaved,
  required void Function(DateTime) onNavigateToDate,
}) {
  return showDialog(
    context: context,
    builder: (ctx) => _AddFoodEntryDialog(
      carbonService: carbonService,
      authService: authService,
      viewDate: viewDate,
      onEntrySaved: onEntrySaved,
      onNavigateToDate: onNavigateToDate,
    ),
  );
}

class _AddFoodEntryDialog extends StatefulWidget {
  final CarbonService carbonService;
  final AuthServiceAdapter authService;
  final DateTime viewDate;
  final VoidCallback onEntrySaved;
  final void Function(DateTime) onNavigateToDate;

  const _AddFoodEntryDialog({
    required this.carbonService,
    required this.authService,
    required this.viewDate,
    required this.onEntrySaved,
    required this.onNavigateToDate,
  });

  @override
  State<_AddFoodEntryDialog> createState() => _AddFoodEntryDialogState();
}

class _AddFoodEntryDialogState extends State<_AddFoodEntryDialog> {
  List<FoodItem> _foodItems = [];
  bool _isLoadingItems = true;
  String? _loadError;
  FoodItem? _selectedItem;
  DateTime _selectedDate = DateTime.now();
  File? _selectedImage;
  bool _isSubmitting = false;
  final TextEditingController _quantityController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.viewDate;
    _loadItems();
  }

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  Future<void> _loadItems() async {
    try {
      final items = await widget.carbonService.getFoodItems();
      if (mounted) setState(() { _foodItems = items; _isLoadingItems = false; });
    } catch (e) {
      if (mounted) setState(() { _loadError = e.toString(); _isLoadingItems = false; });
    }
  }

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (ctx, child) => Theme(
        data: ThemeData.light().copyWith(
          colorScheme: const ColorScheme.light(
            primary: Color(0xFF5D6C24), onPrimary: Colors.white,
            surface: Color(0xFFE4FFAC), onSurface: Color(0xFF5D6C24),
          ),
          dialogBackgroundColor: const Color(0xFFE4FFAC),
        ),
        child: child!,
      ),
    );
    if (picked != null && mounted) setState(() => _selectedDate = picked);
  }

  Future<void> _pickImage() async {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(child: Wrap(children: [
        ListTile(
          leading: const Icon(Icons.photo_camera),
          title: const Text('Take a photo'),
          onTap: () async {
            Navigator.pop(ctx);
            final xf = await _picker.pickImage(source: ImageSource.camera, maxWidth: 1024, maxHeight: 1024, imageQuality: 70);
            if (xf != null && mounted) setState(() => _selectedImage = File(xf.path));
          },
        ),
        ListTile(
          leading: const Icon(Icons.photo_library),
          title: const Text('Choose from gallery'),
          onTap: () async {
            Navigator.pop(ctx);
            final xf = await _picker.pickImage(source: ImageSource.gallery, maxWidth: 1024, maxHeight: 1024, imageQuality: 70);
            if (xf != null && mounted) setState(() => _selectedImage = File(xf.path));
          },
        ),
      ])),
    );
  }

  Future<void> _handleSubmit() async {
    if (_isSubmitting) return;
    if (_selectedItem == null) { _snack('Please select an item type'); return; }
    if (_quantityController.text.isEmpty) { _snack('Please enter a quantity'); return; }
    if (_selectedImage == null) { _snack('Documentation image is required'); return; }

    setState(() => _isSubmitting = true);
    try {
      final quantity = double.tryParse(_quantityController.text) ?? 0;
      final dateStr  = DateFormat('yyyy-MM-dd').format(_selectedDate);

      await widget.carbonService.createFoodEntry(
        foodItemId: _selectedItem!.id,
        quantity:   quantity,
        entryDate:  dateStr,
        imagePath:  _selectedImage!.path,
      );

      // Navigate to entry date if different from viewing date
      final isSameDay = _selectedDate.year  == widget.viewDate.year  &&
                        _selectedDate.month == widget.viewDate.month &&
                        _selectedDate.day   == widget.viewDate.day;
      if (!isSameDay && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Row(children: [
            Expanded(child: Text('Saved for ${_formatDate(_selectedDate)}')),
            TextButton(
              onPressed: () => widget.onNavigateToDate(_selectedDate),
              child: const Text('GO TO DATE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ]),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 5),
        ));
      }

      widget.onEntrySaved();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) _snack('Error: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _snack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: isError ? Colors.red : Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
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
              GestureDetector(onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.close, color: Color(0xFF626F47), size: 24)),
              const Expanded(child: Center(child: Text('Food & Packaging',
                  style: TextStyle(color: Color(0xFF626F47), fontSize: 18, fontWeight: FontWeight.w600)))),
              const SizedBox(width: 24),
            ]),
          ),

          Expanded(
            child: _isLoadingItems
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF5D6C24)))
                : _loadError != null
                    ? _buildError()
                    : SingleChildScrollView(
                        physics: const ClampingScrollPhysics(),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            // Item dropdown
                            const Text('Select Item Type',
                                style: TextStyle(color: Color(0xFF5D6C24), fontSize: 16, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 8),
                            CustomDropdown(
                              items: _foodItems.map((e) => e.name).toList(),
                              selectedValue: _selectedItem?.name,
                              hintText: 'Choose',
                              onChanged: (v) => setState(() =>
                                  _selectedItem = _foodItems.firstWhere((e) => e.name == v)),
                            ),

                            const SizedBox(height: 20),

                            // Quantity
                            const Text('Quantity (kg)',
                                style: TextStyle(color: Color(0xFF5D6C24), fontSize: 16, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 8),
                            _buildInput(_quantityController, 'Enter quantity in kg'),

                            const SizedBox(height: 20),

                            // Date
                            const Text('Date of Activity',
                                style: TextStyle(color: Color(0xFF5D6C24), fontSize: 16, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 8),
                            GestureDetector(
                              onTap: _selectDate,
                              child: _buildDateField(_formatDate(_selectedDate)),
                            ),

                            const SizedBox(height: 20),

                            // Image
                            const Text('Documentation',
                                style: TextStyle(color: Color(0xFF5D6C24), fontSize: 16, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 8),
                            _buildImagePicker(),

                            const SizedBox(height: 30),

                            Align(alignment: Alignment.centerRight, child: ElevatedButton(
                              onPressed: _isSubmitting ? null : _handleSubmit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF626F47), foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              child: _isSubmitting
                                  ? const SizedBox(width: 20, height: 20,
                                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                  : const Text('Calculate & Save',
                                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                            )),
                          ]),
                        ),
                      ),
          ),
        ]),
      ),
    );
  }

  Widget _buildError() => Center(child: Padding(
    padding: const EdgeInsets.all(24),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.error_outline, color: Colors.red, size: 48),
      const SizedBox(height: 16),
      Text(_loadError!, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
      const SizedBox(height: 16),
      ElevatedButton(
        onPressed: () { setState(() { _isLoadingItems = true; _loadError = null; }); _loadItems(); },
        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF626F47)),
        child: const Text('Retry', style: TextStyle(color: Colors.white)),
      ),
    ]),
  ));

  Widget _buildInput(TextEditingController ctrl, String hint) => Container(
    height: 50,
    decoration: BoxDecoration(
      color: const Color(0xFFA4B465), borderRadius: BorderRadius.circular(8),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 8, offset: const Offset(0, 4))],
    ),
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: TextField(
      controller: ctrl,
      keyboardType: TextInputType.number,
      style: const TextStyle(color: Colors.white, fontSize: 16),
      decoration: InputDecoration(
        hintText: hint, hintStyle: const TextStyle(color: Colors.white70, fontSize: 16),
        border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(vertical: 15),
      ),
    ),
  );

  Widget _buildDateField(String label) => Container(
    height: 50,
    decoration: BoxDecoration(
      color: const Color(0xFFA4B465), borderRadius: BorderRadius.circular(8),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 8, offset: const Offset(0, 4))],
    ),
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: const TextStyle(color: Colors.white, fontSize: 16)),
      Image.asset('assets/icons/dropdownbutton2_icon.png', width: 20, height: 20),
    ]),
  );

  Widget _buildImagePicker() => Center(child: GestureDetector(
    onTap: _pickImage,
    child: Container(
      width: 250, height: 250,
      decoration: BoxDecoration(color: const Color(0x66D9D9D9), borderRadius: BorderRadius.circular(8)),
      child: DottedBorder(
        color: Colors.black, strokeWidth: 2, dashPattern: const [6, 6],
        borderType: BorderType.RRect, radius: const Radius.circular(8), padding: EdgeInsets.zero,
        child: _selectedImage != null
            ? ClipRRect(borderRadius: BorderRadius.circular(8),
                child: Image.file(_selectedImage!, width: 250, height: 250, fit: BoxFit.cover))
            : Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Image.asset('assets/icons/image_icon.png', width: 40, height: 40),
                const SizedBox(height: 8),
                const Text('Upload a file or take a photo',
                    style: TextStyle(color: Color(0xFFA4B465), fontSize: 14)),
              ])),
      ),
    ),
  ));
}

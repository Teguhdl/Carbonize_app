import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:intl/intl.dart';
import '../models/consumption_entry.dart';
import '../services/emission_service.dart';
import '../widgets/custom_dropdown.dart';
import '../../auth/services/auth_service_adapter.dart';
import '../../profile/services/user_service_adapter.dart';
import '../../../../core/storage/token_storage.dart';

/// Shows the food & packaging entry dialog.
/// 
/// Callback [onEntryAdded] is invoked with the new entry when the user saves.
/// Callback [onNavigateToDate] is invoked if the entry date differs from [viewDate].
Future<void> showAddFoodEntryDialog({
  required BuildContext context,
  required EmissionService emissionService,
  required AuthServiceAdapter authService,
  required UserServiceAdapter userService,
  required DateTime viewDate,
  required VoidCallback onEntrySaved,
  required void Function(DateTime) onNavigateToDate,
}) {
  return showDialog(
    context: context,
    builder: (BuildContext dialogContext) {
      return _AddFoodEntryDialog(
        emissionService: emissionService,
        authService: authService,
        userService: userService,
        viewDate: viewDate,
        onEntrySaved: onEntrySaved,
        onNavigateToDate: onNavigateToDate,
      );
    },
  );
}

class _AddFoodEntryDialog extends StatefulWidget {
  final EmissionService emissionService;
  final AuthServiceAdapter authService;
  final UserServiceAdapter userService;
  final DateTime viewDate;
  final VoidCallback onEntrySaved;
  final void Function(DateTime) onNavigateToDate;

  const _AddFoodEntryDialog({
    required this.emissionService,
    required this.authService,
    required this.userService,
    required this.viewDate,
    required this.onEntrySaved,
    required this.onNavigateToDate,
  });

  @override
  State<_AddFoodEntryDialog> createState() => _AddFoodEntryDialogState();
}

class _AddFoodEntryDialogState extends State<_AddFoodEntryDialog> {
  // State
  List<String> _foodItemTypes = [];
  bool _isLoadingItems = true;
  String? _loadError;
  String? _selectedItemType;
  DateTime _selectedDate = DateTime.now();
  File? _selectedImage;
  bool _isCalculating = false;
  bool _isSubmitting = false;

  final TextEditingController _quantityController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadFoodItemTypes();
  }

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  Future<void> _loadFoodItemTypes() async {
    try {
      // Debug: check token state
      final sanctumToken = await TokenStorage.getToken();
      final customToken = await TokenStorage.getCustomToken();
      print('[FoodDialog] Token state - sanctum: ${sanctumToken != null ? "present" : "MISSING"}, custom: ${customToken != null ? "present" : "MISSING"}');
      
      final items = await widget.emissionService.getFoodItemNames();
      if (mounted) {
        setState(() {
          _foodItemTypes = items;
          _isLoadingItems = false;
        });
      }
    } catch (e) {
      print('[FoodDialog] Error loading food items: $e');
      if (mounted) {
        setState(() {
          _loadError = 'Failed to load food items: $e';
          _isLoadingItems = false;
        });
      }
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF5D6C24),
              onPrimary: Colors.white,
              surface: Color(0xFFE4FFAC),
              onSurface: Color(0xFF5D6C24),
            ),
            dialogBackgroundColor: const Color(0xFFE4FFAC),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _pickImage() async {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Take a photo'),
                onTap: () async {
                  Navigator.pop(context);
                  final XFile? photo = await _picker.pickImage(
                    source: ImageSource.camera,
                    maxWidth: 1024,
                    maxHeight: 1024,
                    imageQuality: 70,
                  );
                  if (photo != null && mounted) {
                    setState(() {
                      _selectedImage = File(photo.path);
                    });
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from gallery'),
                onTap: () async {
                  Navigator.pop(context);
                  final XFile? image = await _picker.pickImage(
                    source: ImageSource.gallery,
                    maxWidth: 1024,
                    maxHeight: 1024,
                    imageQuality: 70,
                  );
                  if (image != null && mounted) {
                    setState(() {
                      _selectedImage = File(image.path);
                    });
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _handleCalculate() async {
    if (_isCalculating || _isSubmitting) return;

    // Validate
    if (_selectedItemType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an item type'), backgroundColor: Colors.red),
      );
      return;
    }
    if (_quantityController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a quantity'), backgroundColor: Colors.red),
      );
      return;
    }
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Documentation image is required'), backgroundColor: Colors.red),
      );
      return;
    }

    // Debounce
    setState(() {
      _isSubmitting = true;
      _isCalculating = true;
    });
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _isSubmitting = false);
    });

    try {
      final quantity = double.tryParse(_quantityController.text) ?? 0;
      // Emissions will be calculated by the backend
      final entry = ConsumptionEntry(
        category: 'Food & Packaging Consumption',
        itemType: _selectedItemType!,
        quantity: quantity,
        date: _selectedDate,
        image: _selectedImage,
        emissions: 0, // Backend will calculate the actual emissions
        imageUrl: null,
      );

      if (!mounted) return;

      // Check same day
      final isSameDay = _selectedDate.year == widget.viewDate.year &&
          _selectedDate.month == widget.viewDate.month &&
          _selectedDate.day == widget.viewDate.day;

      if (!isSameDay) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Expanded(child: Text('Entry saved for ${_formatDate(_selectedDate)}')),
                TextButton(
                  onPressed: () {
                    widget.onNavigateToDate(_selectedDate);
                  },
                  child: const Text('GO TO DATE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 5),
          ),
        );
      }

      // Save to API
      try {
        await widget.authService.loadCurrentUser();
        final currentUser = widget.authService.currentUser;
        if (currentUser != null) {
          // Look up the factor_items_id for this food item
          final factorItemsId = await widget.emissionService.getFactorItemId('food', _selectedItemType!);
          
          final entryData = {
            'factor_items_id': factorItemsId,
            'quantity': entry.quantity,
            'entry_date': DateFormat('yyyy-MM-dd').format(entry.date),
            'metadata': entry.metadata,
          };
          await widget.userService.saveConsumptionEntry(currentUser.uid, entryData, entry.image);
          print('Entry saved to API');
        }
      } catch (e) {
        print('Error saving to API: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Entry saved locally but failed to sync: $e'), backgroundColor: Colors.orange),
          );
        }
      }

      // Notify parent and close
      widget.onEntrySaved();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() => _isCalculating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error calculating emissions: $e'), backgroundColor: Colors.red),
        );
      }
    }
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
                        'Food & Packaging',
                        style: TextStyle(color: Color(0xFF626F47), fontSize: 18, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(width: 24),
                ],
              ),
            ),

            // Form content
            Expanded(
              child: _isLoadingItems
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF5D6C24)))
                  : _loadError != null
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.error_outline, color: Colors.red, size: 48),
                                const SizedBox(height: 16),
                                Text(_loadError!, style: const TextStyle(color: Colors.red, fontSize: 16), textAlign: TextAlign.center),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: () {
                                    setState(() {
                                      _isLoadingItems = true;
                                      _loadError = null;
                                    });
                                    _loadFoodItemTypes();
                                  },
                                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF626F47)),
                                  child: const Text('Retry', style: TextStyle(color: Colors.white)),
                                ),
                              ],
                            ),
                          ),
                        )
                      : SingleChildScrollView(
                          physics: const ClampingScrollPhysics(),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Item Type
                                const Text('Select Item Type',
                                    style: TextStyle(color: Color(0xFF5D6C24), fontSize: 16, fontWeight: FontWeight.w600)),
                                const SizedBox(height: 8),
                                CustomDropdown(
                                  items: _foodItemTypes,
                                  selectedValue: _selectedItemType,
                                  hintText: 'Choose',
                                  onChanged: (value) => setState(() => _selectedItemType = value),
                                ),

                                const SizedBox(height: 20),

                                // Quantity
                                const Text('Quantity',
                                    style: TextStyle(color: Color(0xFF5D6C24), fontSize: 16, fontWeight: FontWeight.w600)),
                                const SizedBox(height: 8),
                                Container(
                                  width: double.infinity,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFA4B465),
                                    borderRadius: BorderRadius.circular(8),
                                    boxShadow: [
                                      BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 8, offset: const Offset(0, 4)),
                                    ],
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                  child: TextField(
                                    controller: _quantityController,
                                    keyboardType: TextInputType.number,
                                    style: const TextStyle(color: Colors.white, fontSize: 16),
                                    decoration: const InputDecoration(
                                      hintText: 'Enter quantity',
                                      hintStyle: TextStyle(color: Colors.white70, fontSize: 16),
                                      border: InputBorder.none,
                                      contentPadding: EdgeInsets.symmetric(vertical: 15),
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 20),

                                // Date
                                const Text('Date of Activity',
                                    style: TextStyle(color: Color(0xFF5D6C24), fontSize: 16, fontWeight: FontWeight.w600)),
                                const SizedBox(height: 8),
                                GestureDetector(
                                  onTap: _selectDate,
                                  child: Container(
                                    width: double.infinity,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFA4B465),
                                      borderRadius: BorderRadius.circular(8),
                                      boxShadow: [
                                        BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 8, offset: const Offset(0, 4)),
                                      ],
                                    ),
                                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(_formatDate(_selectedDate),
                                            style: const TextStyle(color: Colors.white, fontSize: 16)),
                                        Image.asset('assets/icons/dropdownbutton2_icon.png', width: 20, height: 20),
                                      ],
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 20),

                                // Documentation
                                const Text('Documentation',
                                    style: TextStyle(color: Color(0xFF5D6C24), fontSize: 16, fontWeight: FontWeight.w600)),
                                const SizedBox(height: 8),
                                Center(
                                  child: GestureDetector(
                                    onTap: _pickImage,
                                    child: Container(
                                      width: 250,
                                      height: 250,
                                      decoration: BoxDecoration(
                                        color: const Color(0x66D9D9D9),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: DottedBorder(
                                        color: Colors.black,
                                        strokeWidth: 2,
                                        dashPattern: const [6, 6],
                                        borderType: BorderType.RRect,
                                        radius: const Radius.circular(8),
                                        padding: const EdgeInsets.all(0),
                                        child: _selectedImage != null
                                            ? ClipRRect(
                                                borderRadius: BorderRadius.circular(8),
                                                child: Image.file(_selectedImage!, width: 250, height: 250, fit: BoxFit.cover),
                                              )
                                            : Center(
                                                child: Column(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    Image.asset('assets/icons/image_icon.png', width: 40, height: 40),
                                                    const SizedBox(height: 8),
                                                    const Text('Upload a file or take a photo',
                                                        style: TextStyle(color: Color(0xFFA4B465), fontSize: 14)),
                                                  ],
                                                ),
                                              ),
                                      ),
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 30),

                                // Calculate button
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: ElevatedButton(
                                    onPressed: (_isCalculating || _isSubmitting) ? null : _handleCalculate,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF626F47),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      elevation: 4,
                                    ),
                                    child: _isCalculating
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                          )
                                        : const Text('Calculate', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

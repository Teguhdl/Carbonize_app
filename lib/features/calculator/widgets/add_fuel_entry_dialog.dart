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

/// Shows the fuel consumption entry dialog.
Future<void> showAddFuelEntryDialog({
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
      return _AddFuelEntryDialog(
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

class _AddFuelEntryDialog extends StatefulWidget {
  final EmissionService emissionService;
  final AuthServiceAdapter authService;
  final UserServiceAdapter userService;
  final DateTime viewDate;
  final VoidCallback onEntrySaved;
  final void Function(DateTime) onNavigateToDate;

  const _AddFuelEntryDialog({
    required this.emissionService,
    required this.authService,
    required this.userService,
    required this.viewDate,
    required this.onEntrySaved,
    required this.onNavigateToDate,
  });

  @override
  State<_AddFuelEntryDialog> createState() => _AddFuelEntryDialogState();
}

class _AddFuelEntryDialogState extends State<_AddFuelEntryDialog> {
  // Dropdown data (loaded from API)
  List<String> _vehicleTypes = [];
  List<String> _publicTransportTypes = [];
  List<String> _fuelTypes = [];
  bool _isLoadingData = true;
  String? _loadError;

  // Form state
  String? _selectedTransportationMode;
  String? _selectedVehicleType;
  String? _selectedFuelType;
  String? _selectedCustomEfficiency;
  bool _useCustomEfficiency = false;
  DateTime _selectedDate = DateTime.now();
  File? _selectedImage;
  bool _isCalculating = false;
  bool _isSubmitting = false;

  final TextEditingController _distanceController = TextEditingController();
  final TextEditingController _efficiencyController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadDropdownData();
  }

  @override
  void dispose() {
    _distanceController.dispose();
    _efficiencyController.dispose();
    super.dispose();
  }

  Future<void> _loadDropdownData() async {
    try {
      final results = await Future.wait([
        widget.emissionService.getVehicleTypeNames(),
        widget.emissionService.getPublicTransportTypeNames(),
        widget.emissionService.getFuelTypeNames(),
      ]);
      if (mounted) {
        setState(() {
          _vehicleTypes = results[0];
          _publicTransportTypes = results[1];
          _fuelTypes = results[2];
          _isLoadingData = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadError = 'Failed to load data: $e';
          _isLoadingData = false;
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
      setState(() => _selectedDate = picked);
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
                  if (photo != null && mounted) setState(() => _selectedImage = File(photo.path));
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
                  if (image != null && mounted) setState(() => _selectedImage = File(image.path));
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
    if (_selectedTransportationMode == null) {
      _showError('Please select a transportation mode');
      return;
    }
    if (_distanceController.text.isEmpty) {
      _showError('Please enter a distance');
      return;
    }
    if (_selectedImage == null) {
      _showError('Documentation image is required');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _isCalculating = true;
    });
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _isSubmitting = false);
    });

    try {
      final distance = double.tryParse(_distanceController.text) ?? 0;
      // Emissions will be calculated by the backend

      final entry = ConsumptionEntry(
        category: 'Fuel Consumption',
        itemType: _selectedTransportationMode == 'Private Vehicle'
            ? _selectedVehicleType ?? 'Vehicle'
            : _selectedVehicleType ?? 'Public Transport',
        quantity: distance,
        date: _selectedDate,
        image: _selectedImage,
        emissions: 0, // Backend will calculate the actual emissions
        imageUrl: null,
        metadata: {
          'useCustomEfficiency': _useCustomEfficiency,
          'customEfficiency': _useCustomEfficiency && _efficiencyController.text.isNotEmpty
              ? double.parse(_efficiencyController.text)
              : null,
          'fuelType': _selectedTransportationMode == 'Private Vehicle' ? _selectedFuelType ?? 'Petrol' : null,
          'transportationMode': _selectedTransportationMode,
        },
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
                  onPressed: () => widget.onNavigateToDate(_selectedDate),
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
          // Look up the factor_items_id based on transportation mode
          int factorItemsId = 0;
          if (_selectedTransportationMode == 'Private Vehicle' && _selectedFuelType != null) {
            factorItemsId = await widget.emissionService.getFactorItemId('fuel', _selectedFuelType!);
          } else if (_selectedTransportationMode == 'Public Transport' && _selectedVehicleType != null) {
            factorItemsId = await widget.emissionService.getFactorItemId('public transport', _selectedVehicleType!);
          }
          
          final entryData = {
            'factor_items_id': factorItemsId,
            'quantity': entry.quantity,
            'entry_date': DateFormat('yyyy-MM-dd').format(entry.date),
            'metadata': entry.metadata,
            'vehicleType': _selectedVehicleType,
            'fuelType': _selectedFuelType,
            'transportationMode': _selectedTransportationMode,
            'customEfficiency': _useCustomEfficiency && _efficiencyController.text.isNotEmpty
                ? double.parse(_efficiencyController.text)
                : null,
            'useCustomEfficiency': _useCustomEfficiency,
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

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
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
                        'Fuel Consumption',
                        style: TextStyle(color: Color(0xFF626F47), fontSize: 18, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(width: 24),
                ],
              ),
            ),

            // Form
            Expanded(
              child: _isLoadingData
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
                                      _isLoadingData = true;
                                      _loadError = null;
                                    });
                                    _loadDropdownData();
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
                                // Transportation Mode
                                const Text('Transportation Mode',
                                    style: TextStyle(color: Color(0xFF5D6C24), fontSize: 16, fontWeight: FontWeight.w600)),
                                const SizedBox(height: 8),
                                CustomDropdown(
                                  items: const ['Private Vehicle', 'Public Transport'],
                                  selectedValue: _selectedTransportationMode,
                                  hintText: 'Choose',
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedTransportationMode = value;
                                      _selectedVehicleType = null;
                                      _selectedFuelType = null;
                                      _selectedCustomEfficiency = null;
                                      _useCustomEfficiency = false;
                                    });
                                  },
                                ),

                                // Vehicle Type (shown for both modes)
                                if (_selectedTransportationMode != null) ...[
                                  const SizedBox(height: 20),
                                  const Text('Select Vehicle Type',
                                      style: TextStyle(color: Color(0xFF5D6C24), fontSize: 16, fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 8),
                                  CustomDropdown(
                                    items: _selectedTransportationMode == 'Public Transport'
                                        ? _publicTransportTypes
                                        : _vehicleTypes,
                                    selectedValue: _selectedVehicleType,
                                    hintText: 'Choose',
                                    onChanged: (value) => setState(() => _selectedVehicleType = value),
                                  ),
                                ],

                                // Distance
                                if (_selectedTransportationMode != null) ...[
                                  const SizedBox(height: 20),
                                  const Text('Distance Traveled (km)',
                                      style: TextStyle(color: Color(0xFF5D6C24), fontSize: 16, fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 8),
                                  _buildInputField(
                                    controller: _distanceController,
                                    hintText: 'Enter distance',
                                  ),
                                ],

                                // Private Vehicle extras: Custom Efficiency + Fuel Type
                                if (_selectedTransportationMode == 'Private Vehicle') ...[
                                  const SizedBox(height: 20),
                                  Row(
                                    children: [
                                      const Text('Use Custom Efficiency?',
                                          style: TextStyle(color: Color(0xFF5D6C24), fontSize: 16, fontWeight: FontWeight.w600)),
                                      const SizedBox(width: 5),
                                      GestureDetector(
                                        onTap: () => _showCustomEfficiencyInfo(),
                                        child: Container(
                                          width: 20,
                                          height: 20,
                                          decoration: const BoxDecoration(color: Color(0xFF5D6C24), shape: BoxShape.circle),
                                          child: const Icon(Icons.info_outline, size: 16, color: Colors.white),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  CustomDropdown(
                                    items: const ['Yes', 'No'],
                                    selectedValue: _selectedCustomEfficiency,
                                    hintText: 'Choose',
                                    onChanged: (value) {
                                      setState(() {
                                        _selectedCustomEfficiency = value;
                                        _useCustomEfficiency = value == 'Yes';
                                      });
                                    },
                                  ),

                                  // Custom Fuel Efficiency input
                                  if (_selectedCustomEfficiency == 'Yes') ...[
                                    const SizedBox(height: 20),
                                    const Text('Custom Fuel Efficiency (km/l)',
                                        style: TextStyle(color: Color(0xFF5D6C24), fontSize: 16, fontWeight: FontWeight.w600)),
                                    const SizedBox(height: 8),
                                    _buildInputField(
                                      controller: _efficiencyController,
                                      hintText: 'Type',
                                    ),
                                  ],

                                  const SizedBox(height: 20),
                                  const Text('Fuel Type',
                                      style: TextStyle(color: Color(0xFF5D6C24), fontSize: 16, fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 8),
                                  CustomDropdown(
                                    items: _fuelTypes,
                                    selectedValue: _selectedFuelType,
                                    hintText: 'Type',
                                    onChanged: (value) => setState(() => _selectedFuelType = value),
                                  ),
                                ],

                                // Date
                                if (_selectedTransportationMode != null) ...[
                                  const SizedBox(height: 20),
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

  Widget _buildInputField({required TextEditingController controller, required String hintText}) {
    return Container(
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
        controller: controller,
        keyboardType: TextInputType.number,
        style: const TextStyle(color: Colors.white, fontSize: 16),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(color: Colors.white70, fontSize: 16),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 15),
        ),
      ),
    );
  }

  void _showCustomEfficiencyInfo() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFFE4FFAC),
          title: const Text('Custom Efficiency',
              style: TextStyle(color: Color(0xFF5D6C24), fontWeight: FontWeight.bold)),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Custom Efficiency allows you to input your vehicle\'s specific fuel consumption rate instead of using default values.',
                  style: TextStyle(fontSize: 14, color: Color(0xFF5D6C24))),
              SizedBox(height: 10),
              Text('How to use:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF5D6C24))),
              SizedBox(height: 5),
              Text('1. Select "Yes" to enable custom efficiency', style: TextStyle(fontSize: 14, color: Color(0xFF5D6C24))),
              Text('2. Enter your vehicle\'s fuel efficiency in km/l', style: TextStyle(fontSize: 14, color: Color(0xFF5D6C24))),
              Text('3. Select your fuel type', style: TextStyle(fontSize: 14, color: Color(0xFF5D6C24))),
              SizedBox(height: 10),
              Text('This will provide a more accurate carbon footprint calculation based on your specific vehicle.',
                  style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic, color: Color(0xFF5D6C24))),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Got it', style: TextStyle(color: Color(0xFF5D6C24), fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }
}

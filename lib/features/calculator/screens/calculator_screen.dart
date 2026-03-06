import 'package:flutter/material.dart';
import '../../../utils/constants.dart';

import 'package:intl/intl.dart';
import '../../auth/services/auth_service_adapter.dart';
import '../../profile/services/user_service_adapter.dart';
import '../services/emission_service.dart';
import '../services/consumption_service.dart';

import '../models/consumption_entry.dart';
import '../widgets/donut_chart_painter.dart';
import '../widgets/consumption_entry_card.dart';
import '../widgets/add_food_entry_dialog.dart';
import '../widgets/add_fuel_entry_dialog.dart';
import '../widgets/progress_chart_dialog.dart';
import '../widgets/entry_detail_dialog.dart';
import 'edit_food_entry_screen.dart';
import 'edit_fuel_consumption_screen.dart';

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  // Services
  final AuthServiceAdapter _authService = AuthServiceAdapter();
  final UserServiceAdapter _userService = UserServiceAdapter();
  final EmissionService _emissionService = EmissionService();

  // Emissions state
  String _currentDate = '';
  double _totalEmissions = 0;
  double _foodPackagingEmissions = 0;
  double _fuelEmissions = 0;
  int _dailyLimit = 6;
  double _progressPercentage = 0.0;
  double _currentEmissions = 0.0;
  bool _isLoading = true;

  // Date navigation
  DateTime _viewDate = DateTime.now();

  // Consumption entries
  List<ConsumptionEntry> _consumptionEntries = [];



  @override
  void initState() {
    super.initState();
    _viewDate = DateTime.now();
    _currentDate = _formatDate(_viewDate);
    _loadUserData();
    _loadConsumptionEntries();
  }

  @override
  void dispose() {
    super.dispose();
  }

  // ──────────────────── Data Loading ────────────────────

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    try {
      await _authService.loadCurrentUser();
      final currentUser = _authService.currentUser;
      if (currentUser != null) {
        Map<String, dynamic> userData = await _userService.getUserData(currentUser.uid);
        setState(() {
          _dailyLimit = (userData['dailyCarbonLimit'] as num?)?.toInt() ?? 6;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading user data: $e');
    } finally {
      if (mounted && _isLoading) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadConsumptionEntries() async {
    try {
      await _authService.loadCurrentUser();
      final currentUser = _authService.currentUser;
      if (currentUser != null) {
        setState(() => _isLoading = true);

        final consumptionService = ConsumptionService();
        final dateStr = DateFormat('yyyy-MM-dd').format(_viewDate);
        final apiEntries = await consumptionService.getEntries(
          startDate: dateStr,
          endDate: dateStr,
        );

        final entries = apiEntries.map((apiEntry) {
          DateTime date = DateTime.tryParse(apiEntry.entryDate) ?? DateTime.now();
          return ConsumptionEntry(
            category: apiEntry.categoryName,
            itemType: apiEntry.factorItemName,
            quantity: apiEntry.quantity,
            date: date,
            emissions: apiEntry.emissions,
            imageUrl: apiEntry.image,
            metadata: apiEntry.metadata,
            documentId: apiEntry.id.toString(),
          );
        }).toList();

        if (mounted) {
          setState(() {
            _consumptionEntries = entries;
            _isLoading = false;
          });
          _calculateEmissions();
        }

        print('Loaded ${entries.length} consumption entries for ${_formatDate(_viewDate)}');
      }
    } catch (e) {
      print('Error loading consumption entries: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // ──────────────────── Calculation ────────────────────

  void _calculateEmissions() {
    double totalFoodEmissions = 0;
    double totalFuelEmissions = 0;

    for (var entry in _consumptionEntries) {
      final cat = entry.category.toLowerCase();
      if (cat.contains('food') || cat.contains('packaging')) {
        totalFoodEmissions += entry.emissions;
      } else if (cat.contains('fuel') || cat.contains('transport')) {
        totalFuelEmissions += entry.emissions;
      }
    }

    setState(() {
      _foodPackagingEmissions = totalFoodEmissions;
      _fuelEmissions = totalFuelEmissions;
      _totalEmissions = totalFoodEmissions + totalFuelEmissions;
      _progressPercentage = _dailyLimit > 0
          ? (_totalEmissions / _dailyLimit * 100).clamp(0, 100)
          : 0;
      _currentEmissions = _totalEmissions;
    });
  }

  // ──────────────────── Navigation ────────────────────

  void _goToPreviousDay() {
    setState(() {
      _viewDate = _viewDate.subtract(const Duration(days: 1));
      _currentDate = _formatDate(_viewDate);
    });
    _loadConsumptionEntries();
  }

  void _goToNextDay() {
    setState(() {
      _viewDate = _viewDate.add(const Duration(days: 1));
      _currentDate = _formatDate(_viewDate);
    });
    _loadConsumptionEntries();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _viewDate,
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
    if (picked != null && picked != _viewDate) {
      _navigateToDate(picked);
    }
  }

  void _navigateToDate(DateTime date) {
    setState(() {
      _viewDate = date;
      _currentDate = _formatDate(_viewDate);
    });
    _loadConsumptionEntries();
  }

  String _formatDate(DateTime date) {
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }



  // ──────────────────── Dialog Launchers ────────────────────

  void _showCategorySelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFFE4FFAC),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(
                child: Text(
                  'Select Category',
                  style: TextStyle(
                    color: Color(0xFF5D6C24),
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Food & Packaging
              ListTile(
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFF626F47),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.restaurant, color: Colors.white),
                ),
                title: const Text('Food & Packaging Consumption',
                    style: TextStyle(color: Color(0xFF5D6C24), fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(context);
                  _showAddFoodEntryDialog();
                },
              ),
              const SizedBox(height: 8),
              // Fuel Consumption
              ListTile(
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFF626F47),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.directions_car, color: Colors.white),
                ),
                title: const Text('Fuel Consumption',
                    style: TextStyle(color: Color(0xFF5D6C24), fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(context);
                  _showAddFuelEntryDialog();
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _showAddFoodEntryDialog() {
    showAddFoodEntryDialog(
      context: context,
      emissionService: _emissionService,
      authService: _authService,
      userService: _userService,
      viewDate: _viewDate,
      onEntrySaved: () => _loadConsumptionEntries(),
      onNavigateToDate: _navigateToDate,
    );
  }

  void _showAddFuelEntryDialog() {
    showAddFuelEntryDialog(
      context: context,
      emissionService: _emissionService,
      authService: _authService,
      userService: _userService,
      viewDate: _viewDate,
      onEntrySaved: () => _loadConsumptionEntries(),
      onNavigateToDate: _navigateToDate,
    );
  }

  void _showProgressChart() {
    showProgressChartDialog(
      context: context,
      authService: _authService,
      viewDate: _viewDate,
      progressPercentage: _progressPercentage,
      currentEmissions: _currentEmissions,
      dailyLimit: _dailyLimit,
    );
  }

  void _showEntryDetail(ConsumptionEntry entry) {
    showEntryDetailDialog(
      context: context,
      entry: entry,
      authService: _authService,
      userService: _userService,
      onEntryDeleted: () => _loadConsumptionEntries(),
      onEditEntry: (entry) => _findDocumentIdAndEdit(entry),
    );
  }

  // ──────────────────── Edit Navigation ────────────────────

  Future<void> _findDocumentIdAndEdit(ConsumptionEntry entry) async {
    try {
      setState(() => _isLoading = true);

      if (entry.documentId != null) {
        final cat = entry.category.toLowerCase();
        if (cat.contains('food') || cat.contains('packaging')) {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EditFoodEntryScreen(
                itemType: entry.itemType,
                quantity: entry.quantity,
                date: entry.date,
                image: entry.image,
                imageUrl: entry.imageUrl,
                documentId: entry.documentId!,
              ),
            ),
          );
          if (result == true) _loadConsumptionEntries();
        } else if (cat.contains('fuel') || cat.contains('transport') || cat.contains('vehicle')) {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EditFuelConsumptionScreen(
                itemType: entry.itemType,
                quantity: entry.quantity,
                date: entry.date,
                image: entry.image,
                imageUrl: entry.imageUrl,
                documentId: entry.documentId!,
                transportationMode: entry.metadata?['transportationMode'] ?? 'Private Vehicle',
              ),
            ),
          );
          if (result == true) _loadConsumptionEntries();
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cannot edit: entry has no document ID'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Error navigating to edit screen: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ──────────────────── Build ────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.gradientTop,
              AppColors.gradientBottom,
            ],
            stops: [0.07, 1.0],
          ),
        ),
        child: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: AppColors.accentGreen))
              : _buildCalculatorContent(),
        ),
      ),
    );
  }

  Widget _buildCalculatorContent() {
    return Stack(
      children: [
        // Main content
        SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),

                // Title
                const Text(
                  'Emission Calculator',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Track your daily carbon footprint',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),

                const SizedBox(height: 20),

                // Date navigation
                _buildDateNavigation(),

                const SizedBox(height: 20),

                // Donut chart + emissions info
                _buildEmissionsSummary(),

                const SizedBox(height: 20),

                // Category breakdown
                _buildCategoryBreakdown(),

                const SizedBox(height: 20),

                // Entries list
                _buildEntriesList(),

                const SizedBox(height: 100),
              ],
            ),
          ),
        ),

        // Bottom navigation bar
        Positioned(
          left: 0,
          right: 0,
          bottom: 20,
          child: Center(
            child: Container(
              width: MediaQuery.of(context).size.width * 0.70,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFFF0BB78),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // PROFILE ICON
                  GestureDetector(
                    onTap: () {
                      Navigator.pushReplacementNamed(context, '/profile');
                    },
                    child: Image.asset(
                      'assets/icons/profileunselect_icon.png',
                      width: 70,
                      height: 70,
                    ),
                  ),
                  
                  // HOME ICON
                  GestureDetector(
                    onTap: () {
                      Navigator.pushReplacementNamed(context, '/home');
                    },
                    child: Image.asset(
                      'assets/icons/homeunselect_icon.png',
                      width: 70,
                      height: 70,
                    ),
                  ),
                  
                  // CALCULATOR BUTTON (SELECTED - BROWN CONTAINER)
                  Container(
                    width: 74,
                    height: 70,
                    decoration: BoxDecoration(
                      color: const Color(0xFF55481D),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Image.asset(
                        'assets/icons/calculatorselect_icon.png',
                        width: 70,
                        height: 70,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateNavigation() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Previous day button
          GestureDetector(
            onTap: _goToPreviousDay,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.chevron_left, color: Colors.white, size: 24),
            ),
          ),
          const SizedBox(width: 12),
          // Date text - tap to open picker
          GestureDetector(
            onTap: _selectDate,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.calendar_today, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Text(
                  _currentDate,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_drop_down, color: Colors.white, size: 24),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Next day button
          GestureDetector(
            onTap: _goToNextDay,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.chevron_right, color: Colors.white, size: 24),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmissionsSummary() {
    return GestureDetector(
      onTap: _showProgressChart,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF626F47),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Donut chart
            SizedBox(
              width: 100,
              height: 100,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: const Size(100, 100),
                    painter: DonutChartPainter(
                      percentage: _progressPercentage,
                      backgroundColor: const Color(0xFFB9C982),
                      progressColor: const Color(0xFFDCE4C0),
                    ),
                  ),
                  Text(
                    '${_progressPercentage.toStringAsFixed(0)}%',
                    style: const TextStyle(
                      color: Color(0xCCE259A4),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 20),
            // Emissions info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Total Emissions',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_totalEmissions.toStringAsFixed(2)} kg CO2e',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Daily limit: $_dailyLimit kg CO2e',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryBreakdown() {
    return Row(
      children: [
        Expanded(
          child: _buildCategoryCard(
            icon: Icons.restaurant,
            label: 'Food & Packaging',
            value: '${_foodPackagingEmissions.toStringAsFixed(2)} kg',
            color: const Color(0xFF8B9D5B),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildCategoryCard(
            icon: Icons.directions_car,
            label: 'Fuel',
            value: '${_fuelEmissions.toStringAsFixed(2)} kg',
            color: const Color(0xFF7A8C4A),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white, size: 24),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEntriesList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Today\'s Entries',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Row(
              children: [
                Text(
                  '${_consumptionEntries.length} entries',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _showCategorySelector,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF626F47),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.add, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_consumptionEntries.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 40.0),
              child: Column(
                children: [
                  Icon(Icons.eco, size: 48, color: Colors.white.withOpacity(0.5)),
                  const SizedBox(height: 12),
                  Text(
                    'No entries for this date',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tap + to add a new entry',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ...(_consumptionEntries.map((entry) => ConsumptionEntryCard(
                entry: entry,
                onTap: () => _showEntryDetail(entry),
              ))),
      ],
    );
  }
}
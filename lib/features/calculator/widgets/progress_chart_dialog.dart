import 'package:flutter/material.dart';
import 'package:intl/intl.dart';


import '../services/consumption_service.dart';
import '../widgets/donut_chart_painter.dart';
import '../../auth/services/auth_service_adapter.dart';

/// Shows the circular progress chart dialog with date navigation.
Future<void> showProgressChartDialog({
  required BuildContext context,
  required AuthServiceAdapter authService,
  required DateTime viewDate,
  required double progressPercentage,
  required double currentEmissions,
  required int dailyLimit,
}) {
  return showDialog(
    context: context,
    builder: (BuildContext context) {
      return _ProgressChartDialog(
        authService: authService,
        viewDate: viewDate,
        progressPercentage: progressPercentage,
        currentEmissions: currentEmissions,
        dailyLimit: dailyLimit,
      );
    },
  );
}

class _ProgressChartDialog extends StatefulWidget {
  final AuthServiceAdapter authService;
  final DateTime viewDate;
  final double progressPercentage;
  final double currentEmissions;
  final int dailyLimit;

  const _ProgressChartDialog({
    required this.authService,
    required this.viewDate,
    required this.progressPercentage,
    required this.currentEmissions,
    required this.dailyLimit,
  });

  @override
  State<_ProgressChartDialog> createState() => _ProgressChartDialogState();
}

class _ProgressChartDialogState extends State<_ProgressChartDialog> {
  late DateTime _dialogDate;
  late String _dialogDateStr;
  late double _dialogProgressPercentage;
  late double _dialogCurrentEmissions;

  @override
  void initState() {
    super.initState();
    _dialogDate = widget.viewDate;
    _dialogDateStr = _formatDate(_dialogDate);
    _dialogProgressPercentage = widget.progressPercentage;
    _dialogCurrentEmissions = widget.currentEmissions;
  }

  String _formatDate(DateTime date) {
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  Future<void> _loadDialogDateData() async {
    try {
      await widget.authService.loadCurrentUser();
      final currentUser = widget.authService.currentUser;
      if (currentUser != null) {
        final consumptionService = ConsumptionService();
        final dateStr = DateFormat('yyyy-MM-dd').format(_dialogDate);
        final apiEntries = await consumptionService.getEntries(
          startDate: dateStr,
          endDate: dateStr,
        );

        double totalFoodEmissions = 0;
        double totalFuelEmissions = 0;
        for (var entry in apiEntries) {
          final emissions = entry.emissions;
          final category = entry.categoryName;
          if (category == 'Food & Packaging Consumption') {
            totalFoodEmissions += emissions;
          } else if (category == 'Fuel Consumption') {
            totalFuelEmissions += emissions;
          }
        }

        double totalEmissions = totalFoodEmissions + totalFuelEmissions;
        double progressPercentage = widget.dailyLimit > 0
            ? (totalEmissions / widget.dailyLimit * 100).clamp(0, 100)
            : 0;

        if (mounted) {
          setState(() {
            _dialogProgressPercentage = progressPercentage;
            _dialogCurrentEmissions = totalEmissions;
            _dialogDateStr = _formatDate(_dialogDate);
          });
        }
      }
    } catch (e) {
      print('Error loading dialog date data: $e');
    }
  }

  void _goToPreviousDay() {
    setState(() => _dialogDate = _dialogDate.subtract(const Duration(days: 1)));
    _loadDialogDateData();
  }

  void _goToNextDay() {
    setState(() => _dialogDate = _dialogDate.add(const Duration(days: 1)));
    _loadDialogDateData();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dialogDate,
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
    if (picked != null && picked != _dialogDate) {
      setState(() => _dialogDate = picked);
      _loadDialogDateData();
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
              child: Column(
                children: [
                  Container(
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
                              'Daily Carbon Footprint',
                              style: TextStyle(color: Color(0xFF626F47), fontSize: 18, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                        const SizedBox(width: 24),
                      ],
                    ),
                  ),
                  // Date navigation
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: _goToPreviousDay,
                          child: Image.asset('assets/icons/previous1_button.png', width: 24, height: 24),
                        ),
                        const SizedBox(width: 10),
                        GestureDetector(
                          onTap: _selectDate,
                          child: Row(
                            children: [
                              Text(_dialogDateStr,
                                  style: const TextStyle(color: Color(0xFF626F47), fontSize: 16, fontWeight: FontWeight.w600)),
                              Image.asset('assets/icons/dropdownbutton1_icon.png', width: 35, height: 35),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        GestureDetector(
                          onTap: _goToNextDay,
                          child: Image.asset('assets/icons/next1_button.png', width: 24, height: 24),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Chart
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 200,
                      height: 200,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CustomPaint(
                            size: const Size(200, 200),
                            painter: DonutChartPainter(
                              percentage: _dialogProgressPercentage,
                              backgroundColor: const Color(0xFFB9C982),
                              progressColor: const Color(0xFFDCE4C0),
                            ),
                          ),
                          Text(
                            '${_dialogProgressPercentage.toStringAsFixed(1)}%',
                            style: const TextStyle(
                              color: Color(0xCCE259A4),
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      '$_dialogCurrentEmissions / ${widget.dailyLimit} kg CO2e',
                      style: const TextStyle(color: Color(0xFF626F47), fontSize: 18, fontWeight: FontWeight.w600),
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
}

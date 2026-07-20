import 'package:flutter/material.dart';
import '../../profile/screens/profile_screen.dart';
import './home_screen.dart';
import '../../calculator/screens/calculator_screen.dart';

class MainScreen extends StatefulWidget {
  final int initialIndex;
  
  const MainScreen({super.key, this.initialIndex = 1}); // Default ke Home (index 1)

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late int _selectedIndex;
  late PageController _pageController;

  // Daftar halaman yang dipertahankan statenya dalam memori
  final List<Widget> _pages = const [
    ProfileScreen(),     // Index 0
    HomeScreen(),        // Index 1
    CalculatorScreen(),  // Index 2
  ];

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _selectedIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    if (_selectedIndex != index) {
      setState(() {
        _selectedIndex = index;
      });
      _pageController.jumpToPage(index);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // PageView dengan NeverScrollableScrollPhysics untuk Lazy Loading tab
          Positioned.fill(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: _pages,
            ),
          ),

          // Bottom Navigation Bar terapung (Floating) persis dengan desain asli
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
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // PROFILE ITEM (INDEX 0)
                    _buildNavItem(
                      index: 0,
                      selectedIcon: 'assets/icons/profileselect_icon.png',
                      unselectedIcon: 'assets/icons/profileunselect_icon.png',
                    ),

                    // HOME ITEM (INDEX 1)
                    _buildNavItem(
                      index: 1,
                      selectedIcon: 'assets/icons/homeselect_icon.png',
                      unselectedIcon: 'assets/icons/homeunselect_icon.png',
                    ),

                    // CALCULATOR ITEM (INDEX 2)
                    _buildNavItem(
                      index: 2,
                      selectedIcon: 'assets/icons/calculatorselect_icon.png',
                      unselectedIcon: 'assets/icons/calculatorunselect_icon.png',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required String selectedIcon,
    required String unselectedIcon,
  }) {
    final bool isSelected = _selectedIndex == index;

    if (isSelected) {
      return Container(
        width: 74,
        height: 70,
        decoration: BoxDecoration(
          color: const Color(0xFF55481D),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Image.asset(
            selectedIcon,
            width: 70,
            height: 70,
          ),
        ),
      );
    } else {
      return GestureDetector(
        onTap: () => _onItemTapped(index),
        behavior: HitTestBehavior.opaque,
        child: Image.asset(
          unselectedIcon,
          width: 70,
          height: 70,
        ),
      );
    }
  }
}

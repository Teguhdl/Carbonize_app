import 'package:flutter/material.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/register_screen.dart';
import 'features/auth/screens/splash_screen.dart';
import 'features/home/screens/home_screen.dart';
import 'features/profile/screens/profile_screen.dart';
import 'features/calculator/screens/calculator_screen.dart';
import 'features/profile/screens/terms_policies_screen.dart';
import 'features/profile/screens/report_problem_screen.dart';
import 'features/calculator/screens/food_packaging_details_screen.dart';
import 'features/calculator/screens/fuel_consumption_details_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Carbonize App',
      debugShowCheckedModeBanner: false,
      restorationScopeId: 'app',
      navigatorKey: GlobalKey<NavigatorState>(),
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF5D6C24)),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: const SplashScreen(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/home': (context) => const HomeScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/calculator': (context) => const CalculatorScreen(),
        '/terms': (context) => const TermsPoliciesScreen(),
        '/report': (context) => const ReportProblemScreen(),
        '/food_packaging_details': (context) => const FoodPackagingDetailsScreen(),
        '/fuel_consumption_details': (context) => const FuelConsumptionDetailsScreen(),
      },
    );
  }
}

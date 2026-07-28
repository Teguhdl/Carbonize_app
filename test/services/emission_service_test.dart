import 'package:flutter_test/flutter_test.dart';
import 'package:carbonize_app/core/models/domain_models.dart';
import 'package:carbonize_app/features/calculator/services/consumption_service.dart';
import 'package:carbonize_app/features/calculator/services/emission_service.dart';

// Mock ConsumptionService untuk simulasi lingkungan pengujian terisolasi
class MockConsumptionService extends ConsumptionService {
  @override
  Future<List<FoodItem>> getFoodItems() async {
    return [
      // EmissionDataSeeder: FoodItem fixed, 0.85 kgCO2e/kg.
      const FoodItem(id: 1, name: 'Cardboard Boxes', calculationMethod: 'fixed', emissionFactor: 0.85),
      const FoodItem(id: 2, name: 'Plastic Bags/Films', calculationMethod: 'fixed', emissionFactor: 0.2),
      const FoodItem(id: 3, name: 'Plastic Bottles', calculationMethod: 'fixed', emissionFactor: 0.083),
      const FoodItem(id: 4, name: 'Tissue Paper', calculationMethod: 'fixed', emissionFactor: 0.692),
    ];
  }

  @override
  Future<List<FuelType>> getFuelTypes() async {
    return [
      // EmissionDataSeeder: Pertalite = 2.31 kgCO2e/liter.
      const FuelType(id: 1, name: 'Pertalite', emissionFactor: 2.31),
      const FuelType(id: 2, name: 'Pertamax', emissionFactor: 2.31),
    ];
  }

  @override
  Future<List<VehicleType>> getVehicleTypes() async {
    return [
      // EmissionDataSeeder: Motorcycle = 40 km/liter.
      const VehicleType(id: 1, name: 'Motorcycle', defaultEfficiency: 40.0),
      const VehicleType(id: 2, name: 'City Car', defaultEfficiency: 20.0),
    ];
  }

  @override
  Future<List<TransitVehicle>> getPublicVehicles() async {
    return [
      // EmissionDataSeeder: City Bus = 1.085 kgCO2e/km, 20 passengers.
      const TransitVehicle(id: 1, name: 'City Bus', emissionFactor: 1.085, avgPassengers: 20.0),
      const TransitVehicle(id: 2, name: 'MRT', emissionFactor: 0.026, avgPassengers: 300.0),
    ];
  }
}

void _printHeader(String title) {
  print('\n' + '=' * 80);
  print('  [UNIT TEST] $title');
  print('=' * 80);
}

void _printLog({
  required String scenario,
  required String input,
  required String formula,
  required double expected,
  required double actual,
}) {
  print('Skenario      : $scenario');
  print('Input Param   : $input');
  print('Rumus Uji     : $formula');
  print('Nilai Harapan : $expected kgCO2e');
  print('Output Sistem : $actual kgCO2e');
  print('Status Uji    : ${expected == actual || (expected - actual).abs() < 0.001 ? "✔ PASSED (Akurat 100%)" : "❌ FAILED"}');
  print('-' * 80);
}

void main() {
  group('Pengujian Core Logic Kalkulator Karbon (EmissionService)', () {
    late EmissionService emissionService;
    late MockConsumptionService mockService;

    setUp(() {
      mockService = MockConsumptionService();
      emissionService = EmissionService(apiService: mockService);
    });

    test('1. Pengujian Algoritma Perhitungan Emisi Makanan (Food)', () async {
      _printHeader('PERHITUNGAN EMISI MAKANAN (FOOD EMISSIONS)');

      // Kasus 1: Cardboard Boxes dari EmissionDataSeeder
      final resultCardboard = await emissionService.calculateFoodEmissions('Cardboard Boxes', 1.0);
      _printLog(
        scenario: 'Konsumsi Cardboard Boxes seberat 1.0 kg',
        input: 'Item = Cardboard Boxes, Quantity = 1.0 kg, Faktor Emisi = 0.85 kgCO2e/kg',
        formula: 'Quantity × Emission Factor (1.0 × 0.85)',
        expected: 0.85,
        actual: resultCardboard,
      );
      expect(resultCardboard, closeTo(0.85, 0.0001));

      // Kasus 2: Plastic Bottles dari EmissionDataSeeder
      final resultBottles = await emissionService.calculateFoodEmissions('Plastic Bottles', 3.0);
      _printLog(
        scenario: 'Konsumsi Plastic Bottles seberat 3.0 kg',
        input: 'Item = Plastic Bottles, Quantity = 3.0 kg, Faktor Emisi = 0.083 kgCO2e/kg',
        formula: 'Quantity × Emission Factor (3.0 × 0.083)',
        expected: 0.249,
        actual: resultBottles,
      );
      expect(resultBottles, closeTo(0.249, 0.0001));

      // Kasus 3: Makanan Tidak Dikenal (Edge Case)
      final resultUnknown = await emissionService.calculateFoodEmissions('Alien Food', 1.0);
      _printLog(
        scenario: 'Konsumsi Makanan di Luar Database (Edge Case Handling)',
        input: 'Item = Alien Food, Quantity = 1.0 kg',
        formula: 'Return Default 0 (Prevent Crash)',
        expected: 0.0,
        actual: resultUnknown,
      );
      expect(resultUnknown, equals(0.0));
    });

    test('2. Pengujian Algoritma Emisi Kendaraan Pribadi (Efisiensi Default)', () async {
      _printHeader('PERHITUNGAN EMISI BBM KENDARAAN PRIBADI (DEFAULT EFFICIENCY)');

      // Kasus 1: Motor + Pertalite
      // Kasus 1: Motorcycle + Pertalite dari EmissionDataSeeder
      final resultMotorcycle = await emissionService.calculateFuelEmissions(
        distance: 80.0,
        fuelType: 'Pertalite',
        vehicleType: 'Motorcycle',
      );
      _printLog(
        scenario: 'Perjalanan Motorcycle sejauh 80 km menggunakan Pertalite',
        input: 'Jarak = 80 km, Efisiensi Motorcycle = 40 km/L, Faktor Emisi = 2.31 kgCO2e/L',
        formula: '(Jarak / Efisiensi) × Faktor Emisi ((80 / 40) × 2.31)',
        expected: 4.62,
        actual: resultMotorcycle,
      );
      expect(resultMotorcycle, closeTo(4.62, 0.0001));

      // Kasus 2: City Car + Pertamax dari EmissionDataSeeder
      final resultCityCar = await emissionService.calculateFuelEmissions(
        distance: 60.0,
        fuelType: 'Pertamax',
        vehicleType: 'City Car',
      );
      _printLog(
        scenario: 'Perjalanan City Car sejauh 60 km menggunakan Pertamax',
        input: 'Jarak = 60 km, Efisiensi City Car = 20 km/L, Faktor Emisi = 2.31 kgCO2e/L',
        formula: '(Jarak / Efisiensi) × Faktor Emisi ((60 / 20) × 2.31)',
        expected: 6.93,
        actual: resultCityCar,
      );
      expect(resultCityCar, closeTo(6.93, 0.0001));
    });

    test('3. Pengujian Algoritma Emisi Kendaraan Pribadi (Custom Efficiency)', () async {
      _printHeader('PERHITUNGAN EMISI BBM KENDARAAN PRIBADI (CUSTOM EFFICIENCY)');

      final resultCustom = await emissionService.calculateFuelEmissions(
        distance: 100.0,
        fuelType: 'Pertalite',
        vehicleType: 'Motorcycle',
        customEfficiency: 50.0,
      );
      _printLog(
        scenario: 'Pengguna Memasukkan Efisiensi Motorcycle Sendiri (50 km/L)',
        input: 'Jarak = 100 km, Custom Efficiency = 50 km/L, Faktor Emisi Pertalite = 2.31 kgCO2e/L',
        formula: '(Jarak / Custom Efficiency) × Faktor Emisi ((100 / 50) × 2.31)',
        expected: 4.62,
        actual: resultCustom,
      );
      expect(resultCustom, closeTo(4.62, 0.0001));
    });

    test('4. Pengujian Algoritma Emisi Kendaraan Umum (Public Transport)', () async {
      _printHeader('PERHITUNGAN EMISI KENDARAAN UMUM / MASSAL (PUBLIC TRANSPORT)');

      // Kasus 1: City Bus dari EmissionDataSeeder
      final resultCityBus = await emissionService.calculatePublicTransportEmissions(
        distance: 80.0,
        vehicleType: 'City Bus',
      );
      _printLog(
        scenario: 'Perjalanan City Bus sejauh 80 km',
        input: 'Jarak = 80 km, Faktor Emisi = 1.085 kgCO2e/km, Rata-rata Penumpang = 20',
        formula: '(Faktor Emisi × Jarak) / Rata-rata Penumpang ((1.085 × 80) / 20)',
        expected: 4.34,
        actual: resultCityBus,
      );
      expect(resultCityBus, closeTo(4.34, 0.0001));

      // Kasus 2: MRT dari EmissionDataSeeder
      final resultMrt = await emissionService.calculatePublicTransportEmissions(
        distance: 100.0,
        vehicleType: 'MRT',
      );
      _printLog(
        scenario: 'Perjalanan MRT sejauh 100 km',
        input: 'Jarak = 100 km, Faktor Emisi = 0.026 kgCO2e/km, Rata-rata Penumpang = 300',
        formula: '(Faktor Emisi × Jarak) / Rata-rata Penumpang ((0.026 × 100) / 300)',
        expected: 0.0086666667,
        actual: resultMrt,
      );
      expect(resultMrt, closeTo(0.0086666667, 0.0001));
    });
  });
}

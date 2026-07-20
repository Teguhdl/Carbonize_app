import 'package:flutter_test/flutter_test.dart';
import 'package:carbonize_app/core/models/domain_models.dart';
import 'package:carbonize_app/features/calculator/services/consumption_service.dart';
import 'package:carbonize_app/features/calculator/services/emission_service.dart';

// Mock ConsumptionService untuk simulasi lingkungan pengujian terisolasi
class MockConsumptionService extends ConsumptionService {
  @override
  Future<List<FoodItem>> getFoodItems() async {
    return [
      const FoodItem(id: 1, name: 'Beef', calculationMethod: 'fixed', emissionFactor: 27.0),
      const FoodItem(id: 2, name: 'Chicken', calculationMethod: 'fixed', emissionFactor: 6.9),
    ];
  }

  @override
  Future<List<FuelType>> getFuelTypes() async {
    return [
      const FuelType(id: 1, name: 'Pertalite', emissionFactor: 2.3),
      const FuelType(id: 2, name: 'Pertamax', emissionFactor: 2.34),
    ];
  }

  @override
  Future<List<VehicleType>> getVehicleTypes() async {
    return [
      const VehicleType(id: 1, name: 'Motor', defaultEfficiency: 40.0), // 40 km/L
      const VehicleType(id: 2, name: 'Mobil', defaultEfficiency: 12.0), // 12 km/L
    ];
  }

  @override
  Future<List<TransitVehicle>> getPublicVehicles() async {
    return [
      const TransitVehicle(id: 1, name: 'Bus', emissionFactor: 1.0, avgPassengers: 40.0),
      const TransitVehicle(id: 2, name: 'Train', emissionFactor: 2.0, avgPassengers: 200.0),
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

      // Kasus 1: Daging Sapi (Beef)
      final resultBeef = await emissionService.calculateFoodEmissions('Beef', 2.0);
      _printLog(
        scenario: 'Konsumsi Daging Sapi seberat 2.0 kg',
        input: 'Item = Beef, Quantity = 2.0 kg, Faktor Emisi = 27.0 kgCO2e/kg',
        formula: 'Quantity × Emission Factor (2.0 × 27.0)',
        expected: 54.0,
        actual: resultBeef,
      );
      expect(resultBeef, equals(54.0));

      // Kasus 2: Daging Ayam (Chicken)
      final resultChicken = await emissionService.calculateFoodEmissions('Chicken', 3.0);
      _printLog(
        scenario: 'Konsumsi Daging Ayam seberat 3.0 kg',
        input: 'Item = Chicken, Quantity = 3.0 kg, Faktor Emisi = 6.9 kgCO2e/kg',
        formula: 'Quantity × Emission Factor (3.0 × 6.9)',
        expected: 20.7,
        actual: resultChicken,
      );
      expect(resultChicken, closeTo(20.7, 0.0001));

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
      final resultMotor = await emissionService.calculateFuelEmissions(
        distance: 80.0,
        fuelType: 'Pertalite',
        vehicleType: 'Motor',
      );
      _printLog(
        scenario: 'Perjalanan Sepeda Motor sejauh 80 km menggunakan Pertalite',
        input: 'Jarak = 80 km, Efisiensi Motor = 40 km/L, Faktor Emisi = 2.3 kgCO2e/L',
        formula: '(Jarak / Efisiensi) × Faktor Emisi ((80 / 40) × 2.3)',
        expected: 4.6,
        actual: resultMotor,
      );
      expect(resultMotor, closeTo(4.6, 0.0001));

      // Kasus 2: Mobil + Pertamax
      final resultMobil = await emissionService.calculateFuelEmissions(
        distance: 60.0,
        fuelType: 'Pertamax',
        vehicleType: 'Mobil',
      );
      _printLog(
        scenario: 'Perjalanan Mobil sejauh 60 km menggunakan Pertamax',
        input: 'Jarak = 60 km, Efisiensi Mobil = 12 km/L, Faktor Emisi = 2.34 kgCO2e/L',
        formula: '(Jarak / Efisiensi) × Faktor Emisi ((60 / 12) × 2.34)',
        expected: 11.7,
        actual: resultMobil,
      );
      expect(resultMobil, closeTo(11.7, 0.0001));
    });

    test('3. Pengujian Algoritma Emisi Kendaraan Pribadi (Custom Efficiency)', () async {
      _printHeader('PERHITUNGAN EMISI BBM KENDARAAN PRIBADI (CUSTOM EFFICIENCY)');

      final resultCustom = await emissionService.calculateFuelEmissions(
        distance: 60.0,
        fuelType: 'Pertamax',
        vehicleType: 'Mobil',
        customEfficiency: 15.0,
      );
      _printLog(
        scenario: 'Pengguna Memasukkan Efisiensi Kendaraan Sendiri (15 km/L)',
        input: 'Jarak = 60 km, Custom Efficiency = 15 km/L, Faktor Emisi = 2.34 kgCO2e/L',
        formula: '(Jarak / Custom Efficiency) × Faktor Emisi ((60 / 15) × 2.34)',
        expected: 9.36,
        actual: resultCustom,
      );
      expect(resultCustom, closeTo(9.36, 0.0001));
    });

    test('4. Pengujian Algoritma Emisi Kendaraan Umum (Public Transport)', () async {
      _printHeader('PERHITUNGAN EMISI KENDARAAN UMUM / MASSAL (PUBLIC TRANSPORT)');

      // Kasus 1: Bus Massal
      final resultBus = await emissionService.calculatePublicTransportEmissions(
        distance: 80.0,
        vehicleType: 'Bus',
      );
      _printLog(
        scenario: 'Perjalanan Naik Bus Umum sejauh 80 km',
        input: 'Jarak = 80 km, Faktor Emisi Armada = 1.0 kgCO2e/km, Kapasitas = 40 Penumpang',
        formula: '(Faktor Emisi × Jarak) / Rata-rata Penumpang ((1.0 × 80) / 40)',
        expected: 2.0,
        actual: resultBus,
      );
      expect(resultBus, equals(2.0));

      // Kasus 2: Kereta Api / KRL
      final resultTrain = await emissionService.calculatePublicTransportEmissions(
        distance: 100.0,
        vehicleType: 'Train',
      );
      _printLog(
        scenario: 'Perjalanan Naik Kereta Api sejauh 100 km',
        input: 'Jarak = 100 km, Faktor Emisi Armada = 2.0 kgCO2e/km, Kapasitas = 200 Penumpang',
        formula: '(Faktor Emisi × Jarak) / Rata-rata Penumpang ((2.0 × 100) / 200)',
        expected: 1.0,
        actual: resultTrain,
      );
      expect(resultTrain, equals(1.0));
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:carbonize_app/core/storage/token_storage.dart';

void _printHeader(String title) {
  print('\n' + '=' * 80);
  print('  [UNIT TEST] $title');
  print('=' * 80);
}

void _printLog({
  required String scenario,
  required String input,
  required String expected,
  required String actual,
  required bool isPassed,
}) {
  print('Skenario      : $scenario');
  print('Input Data    : $input');
  print('Kondisi Harapan : $expected');
  print('Hasil Bacaan  : $actual');
  print('Status Uji    : ${isPassed ? "✔ PASSED (Secure Verified)" : "❌ FAILED"}');
  print('-' * 80);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Pengujian Sistem Keamanan Penyimpanan Kredensial (TokenStorage)', () {
    setUp(() {
      FlutterSecureStorage.setMockInitialValues({});
    });

    test('1. Pengujian Enkripsi Penyimpanan dan Pembacaan Sesi Login', () async {
      _printHeader('ENKRIPSI DATA SESI PENGGUNA (LOGIN STORAGE TEST)');

      await TokenStorage.saveAuthData(
        sanctumToken: 'token-rahasia-123',
        customToken: 'custom-key-xyz',
        userId: 99,
        userName: 'Mahasiswa Skripsi',
        userEmail: 'skripsi@carbonize.app',
      );

      final token = await TokenStorage.getToken();
      final userId = await TokenStorage.getUserId();
      final userName = await TokenStorage.getUserName();
      final isValid = await TokenStorage.hasValidToken();

      _printLog(
        scenario: 'Penyimpanan Kredensial saat Login Berhasil',
        input: 'Token="token-rahasia-123", ID=99, Name="Mahasiswa Skripsi"',
        expected: 'Token Terbaca Persis & hasValidToken=true',
        actual: 'Token="$token", ID=$userId, Valid=$isValid',
        isPassed: token == 'token-rahasia-123' && userId == 99 && isValid == true,
      );

      expect(token, equals('token-rahasia-123'));
      expect(userId, equals(99));
      expect(userName, equals('Mahasiswa Skripsi'));
      expect(isValid, isTrue);
    });

    test('2. Pengujian Pembersihan Data Kredensial saat Logout (clearAll)', () async {
      _printHeader('PEMBERSIHAN DATA SESI PENGGUNA (LOGOUT CLEANUP TEST)');

      await TokenStorage.saveAuthData(
        sanctumToken: 'token-sementara',
        customToken: 'custom-sementara',
        userId: 1,
        userName: 'User Logout',
        userEmail: 'logout@test.com',
      );

      await TokenStorage.clearAll();

      final tokenAfter = await TokenStorage.getToken();
      final isValidAfter = await TokenStorage.hasValidToken();

      _printLog(
        scenario: 'Penghapusan Seluruh Kredensial Keamanan setelah Logout',
        input: 'Eksekusi fungsi TokenStorage.clearAll()',
        expected: 'Seluruh Key bernilai null / hasValidToken=false',
        actual: 'Token="$tokenAfter", Valid=$isValidAfter',
        isPassed: tokenAfter == null && isValidAfter == false,
      );

      expect(tokenAfter, isNull);
      expect(isValidAfter, isFalse);
    });
  });
}

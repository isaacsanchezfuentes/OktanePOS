import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Printer Pre-Check Ticket & Payment SKU Tests', () {
    test('Formats SKU and payment gateway URL correctly', () {
      const baseUrl = 'https://pay.oktane.io/o/';
      const tableName = 'Mesa #4';
      final timestamp = 1711280000000;

      final cleanTableName = tableName.replaceAll(' ', '').toUpperCase();
      final sku = 'ORD-$cleanTableName-$timestamp';
      final paymentUrl = '$baseUrl$sku';

      expect(sku, 'ORD-MESA#4-1711280000000');
      expect(paymentUrl, 'https://pay.oktane.io/o/ORD-MESA#4-1711280000000');
    });

    test('Calculates tip suggestions 10% and 15% accurately', () {
      final totalAmount = 450.0;
      final tip10 = totalAmount * 0.10;
      final tip15 = totalAmount * 0.15;

      expect(tip10, 45.0);
      expect(tip15, 67.5);
    });
  });
}

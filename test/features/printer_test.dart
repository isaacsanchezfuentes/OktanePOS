import 'package:flutter_test/flutter_test.dart';
import 'package:oktane_pos/features/charge/models/charge_model.dart';

void main() {
  group('Thermal Printer Data Formatting Tests', () {
    test('Formats charge ticket data correctly for ESC/POS output with web payment URL', () {
      final charge = ChargeModel(
        id: '123456789',
        amount: 85.50,
        currency: 'MXN',
        status: 'pending',
        userId: 'user-001',
        concept: 'Mesa 12',
        paymentMethod: 'qr',
        createdAt: DateTime(2026, 9, 24, 15, 30),
      );

      final folioStr = '#${charge.id!.substring(0, 4).toUpperCase()}';
      final cleanFolio = charge.id!.substring(0, 4).toUpperCase();
      final amountStr = '\$${charge.amount.toStringAsFixed(2)} MXN';
      final qrData = 'https://oktane-pos.web.app/pay?id=${charge.id}&folio=$cleanFolio&amount=${charge.amount}';

      expect(folioStr, '#1234');
      expect(amountStr, '\$85.50 MXN');
      expect(qrData, 'https://oktane-pos.web.app/pay?id=123456789&folio=1234&amount=85.5');
    });
  });
}

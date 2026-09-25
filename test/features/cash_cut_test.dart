import 'package:flutter_test/flutter_test.dart';
import 'package:oktane_pos/features/cash_cut/models/cash_cut_model.dart';

void main() {
  group('Cash Cut Summary Model Tests', () {
    test('Correctly calculates cash, card, qr totals and transaction metrics', () {
      final rawCharges = [
        {'status': 'paid', 'payment_method': 'efectivo', 'amount': 100.0},
        {'status': 'paid', 'payment_method': 'efectivo', 'amount': 50.0},
        {'status': 'paid', 'payment_method': 'tarjeta', 'amount': 200.0},
        {'status': 'paid', 'payment_method': 'qr', 'amount': 150.0},
        {'status': 'pending', 'payment_method': 'efectivo', 'amount': 75.0},
        {'status': 'cancelled', 'payment_method': 'efectivo', 'amount': 500.0},
      ];

      final summary = CashCutSummaryModel.fromCharges(rawCharges, 'user-123');

      expect(summary.totalCash, 150.0);
      expect(summary.totalCard, 200.0);
      expect(summary.totalQr, 150.0);
      expect(summary.totalCollected, 500.0);
      expect(summary.totalTransactions, 4);
      expect(summary.pendingTransactions, 1);
      expect(summary.averageTicket, 125.0);
    });

    test('Drawer balancing difference calculation (Sobrante and Faltante)', () {
      final rawCharges = [
        {'status': 'paid', 'payment_method': 'efectivo', 'amount': 300.0},
      ];

      final summary = CashCutSummaryModel.fromCharges(rawCharges, 'user-123');

      final initialFloat = 500.0;
      final expectedCash = initialFloat + summary.totalCash; // 800.0

      // Exact
      final countedExact = 800.0;
      expect(countedExact - expectedCash, 0.0);

      // Sobrante
      final countedSurplus = 850.0;
      expect(countedSurplus - expectedCash, 50.0);

      // Faltante
      final countedShortage = 780.0;
      expect(countedShortage - expectedCash, -20.0);
    });
  });
}

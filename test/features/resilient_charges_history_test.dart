import 'package:flutter_test/flutter_test.dart';
import 'package:oktane_pos/features/charge/models/charge_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Resilient Hybrid Charges Stream Tests', () {
    test('Calculates total paid and pending metrics correctly from charges list', () {
      final charges = [
        ChargeModel(
          id: 'ch-1',
          amount: 250.0,
          currency: 'MXN',
          userId: 'u-1',
          status: 'paid',
          concept: 'Mesa #1',
          paymentMethod: 'cash',
          createdAt: DateTime.now(),
        ),
        ChargeModel(
          id: 'ch-2',
          amount: 120.0,
          currency: 'MXN',
          userId: 'u-1',
          status: 'pending',
          concept: 'Mesa #2',
          paymentMethod: 'cash',
          createdAt: DateTime.now(),
        ),
        ChargeModel(
          id: 'ch-3',
          amount: 300.0,
          currency: 'MXN',
          userId: 'u-1',
          status: 'paid',
          concept: 'Barra',
          paymentMethod: 'card',
          createdAt: DateTime.now(),
        ),
      ];

      final totalPaid = charges
          .where((c) => c.status == 'paid')
          .fold(0.0, (sum, c) => sum + c.amount);

      final pendingCount = charges.where((c) => c.status == 'pending').length;

      expect(totalPaid, 550.0);
      expect(pendingCount, 1);
    });
  });
}

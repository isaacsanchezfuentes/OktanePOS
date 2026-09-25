import 'package:flutter_test/flutter_test.dart';
import 'package:oktane_pos/features/charge/models/charge_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Atomic Ticket Lifecycle & Settlement Tests', () {
    test('Calculates total paid and pending metrics correctly from charges stream list', () {
      final charges = [
        ChargeModel(id: 'ch-1', amount: 250.0, status: 'paid', concept: 'Mesa 1', paymentMethod: 'efectivo', userId: 'u-1'),
        ChargeModel(id: 'ch-2', amount: 680.0, status: 'paid', concept: 'Mesa 3', paymentMethod: 'tarjeta', userId: 'u-2'),
        ChargeModel(id: 'ch-3', amount: 150.0, status: 'pending', concept: 'Mesa 2 - Cocina', paymentMethod: 'efectivo', userId: 'u-1'),
        ChargeModel(id: 'ch-4', amount: 90.0, status: 'cancelled', concept: 'Mesa 4', paymentMethod: 'efectivo', userId: 'u-3'),
      ];

      final totalPaid = charges
          .where((c) => c.status == 'paid')
          .fold(0.0, (sum, c) => sum + c.amount);

      final pendingCount = charges.where((c) => c.status == 'pending').length;

      expect(totalPaid, 930.0);
      expect(pendingCount, 1);
    });
  });
}

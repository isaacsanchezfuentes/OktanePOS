import 'package:flutter_test/flutter_test.dart';
import 'package:oktane_pos/features/charge/models/charge_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Waiter ID Sanitization & Foreign Key 23503 Fix Tests', () {
    test('Omits waiter_id if equal to userId to avoid constraint charges_waiter_id_fkey 23503 error', () {
      const activeUserUuid = '00000000-0000-4000-8000-000000000099';
      const validTableUuid = '00000000-0000-4000-8000-000000000001';

      final sameUserCharge = ChargeModel(
        amount: 200.0,
        userId: activeUserUuid,
        concept: 'Mesa #1 - Consumo',
        paymentMethod: 'efectivo',
        tableId: validTableUuid,
        waiterId: activeUserUuid, // Same as userId -> Should be sanitized out of JSON
      );

      final json = sameUserCharge.toSupabaseJson();

      expect(json['user_id'], activeUserUuid);
      expect(json['table_id'], validTableUuid);
      expect(json.containsKey('waiter_id'), isFalse); // Omitted so FK constraint charges_waiter_id_fkey succeeds!
    });

    test('Includes waiter_id if explicitly assigned to a distinct waiter profile UUID', () {
      const activeUserUuid = '00000000-0000-4000-8000-000000000099';
      const distinctWaiterUuid = '00000000-0000-4000-8000-000000000088';
      const validTableUuid = '00000000-0000-4000-8000-000000000001';

      final distinctCharge = ChargeModel(
        amount: 200.0,
        userId: activeUserUuid,
        concept: 'Mesa #1 - Consumo',
        paymentMethod: 'efectivo',
        tableId: validTableUuid,
        waiterId: distinctWaiterUuid, // Distinct valid waiter profile
      );

      final json = distinctCharge.toSupabaseJson();

      expect(json['user_id'], activeUserUuid);
      expect(json['waiter_id'], distinctWaiterUuid);
      expect(json['table_id'], validTableUuid);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:oktane_pos/features/charge/models/charge_model.dart';
import 'package:oktane_pos/features/tables/services/table_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Table UUID Validation & Postgres 22P02/23503 Prevention Tests', () {
    test('ChargeModel.toSupabaseJson() filters non-UUID strings to prevent Postgres 22P02 error', () {
      final invalidCharge = ChargeModel(
        amount: 150.0,
        userId: 'u-100',
        concept: 'Mesa 1 - Consumo',
        paymentMethod: 'efectivo',
        tableId: 't-1', // Invalid non-UUID format
      );

      final json = invalidCharge.toSupabaseJson();
      expect(json.containsKey('table_id'), isFalse); // Omitted so Postgres doesn't throw 22P02

      final validCharge = ChargeModel(
        amount: 150.0,
        userId: 'u-100',
        concept: 'Mesa 1 - Consumo',
        paymentMethod: 'efectivo',
        tableId: '00000000-0000-4000-8000-000000000001', // Valid v4 UUID
      );

      final validJson = validCharge.toSupabaseJson();
      expect(validJson['table_id'], '00000000-0000-4000-8000-000000000001');
    });

    test('TableService initializes default tables with syntactically valid v4 UUIDs', () {
      final tableService = TableService();
      final zones = tableService.getZones();

      for (final zone in zones) {
        final tables = tableService.getTablesByZone(zone.id);
        for (final table in tables) {
          final isUuid = RegExp(
            r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
          ).hasMatch(table.id);
          expect(isUuid, isTrue);
        }
      }
    });
  });
}

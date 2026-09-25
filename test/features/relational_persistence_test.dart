import 'package:flutter_test/flutter_test.dart';
import 'package:oktane_pos/features/charge/models/charge_model.dart';
import 'package:oktane_pos/features/tables/services/table_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Relational Table ID & Draft Persistence Tests', () {
    test('ChargeModel.toSupabaseJson() includes table_id and waiter_id matching Supabase schema', () {
      const validTableUuid = '00000000-0000-4000-8000-000000000001';
      const validUserUuid = '00000000-0000-4000-8000-000000000099';
      const distinctWaiterUuid = '00000000-0000-4000-8000-000000000088';

      final charge = ChargeModel(
        id: 'c-100',
        amount: 320.0,
        currency: 'MXN',
        status: 'pending',
        userId: validUserUuid,
        concept: 'Mesa #1 - Consumo Consolidado',
        paymentMethod: 'efectivo',
        tableId: validTableUuid,
        waiterId: distinctWaiterUuid,
      );

      final json = charge.toSupabaseJson();

      expect(json['table_id'], validTableUuid);
      expect(json['waiter_id'], distinctWaiterUuid);
      expect(json['user_id'], validUserUuid);
      expect(json['amount'], 320.0);
      expect(json['status'], 'pending');

      final deserialized = ChargeModel.fromJson(json);
      expect(deserialized.tableId, validTableUuid);
      expect(deserialized.waiterId, distinctWaiterUuid);
    });

    test('TableService saves, loads, and clears table order drafts correctly', () {
      final tableService = TableService();
      const tableId = '00000000-0000-4000-8000-000000000004';

      final draftItems = [
        {'item_id': 'm-1', 'name': 'Tacos de Pastor', 'price': 85.0, 'quantity': 2, 'subtotal': 170.0},
        {'item_id': 'm-2', 'name': 'Agua de Horchata', 'price': 35.0, 'quantity': 1, 'subtotal': 35.0},
      ];

      tableService.saveTableDraft(tableId, draftItems);

      final loadedDraft = tableService.getTableDraft(tableId);
      expect(loadedDraft.length, 2);
      expect(loadedDraft.first['name'], 'Tacos de Pastor');

      tableService.clearTableDraft(tableId);
      final emptyDraft = tableService.getTableDraft(tableId);
      expect(emptyDraft.isEmpty, isTrue);
    });
  });
}

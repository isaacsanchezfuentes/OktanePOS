import 'package:flutter_test/flutter_test.dart';
import 'package:oktane_pos/features/tables/services/table_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Calculator (QuickChargeScreen) to Table Order Bridge Tests', () {
    test('Transfers captured calculator items to table draft and loads them correctly', () {
      final tableService = TableService();
      const tableId = '00000000-0000-4000-8000-000000000001';

      final capturedCalculatorItems = [
        {
          'item_id': 'm-1',
          'name': 'Pizza Individual Pepperoni',
          'price': 120.0,
          'quantity': 2,
          'subtotal': 240.0,
          'is_takeaway': false,
          'notes': 'Sin cebolla',
        },
        {
          'item_id': 'm-2',
          'name': 'Cerveza Corona',
          'price': 65.0,
          'quantity': 1,
          'subtotal': 65.0,
          'is_takeaway': false,
          'notes': '',
        },
      ];

      // 1. QuickChargeScreen saves draft before navigating to TableOrderDetailScreen
      tableService.saveTableDraft(tableId, capturedCalculatorItems);

      // 2. TableOrderDetailScreen loads draft into newRoundItems
      final draftItems = tableService.getTableDraft(tableId);

      expect(draftItems.length, 2);
      expect(draftItems.first['name'], 'Pizza Individual Pepperoni');
      expect(draftItems.first['subtotal'], 240.0);
      expect(draftItems.last['name'], 'Cerveza Corona');

      // 3. Calculate preliminary subtotal of transferred round items
      final preliminaryRoundTotal = draftItems.fold(
        0.0,
        (sum, item) => sum + ((item['subtotal'] as num?)?.toDouble() ?? 0.0),
      );
      expect(preliminaryRoundTotal, 305.0);

      // 4. Upon kitchen dispatch or settlement, clear draft
      tableService.clearTableDraft(tableId);
      final emptyDraft = tableService.getTableDraft(tableId);
      expect(emptyDraft.isEmpty, isTrue);
    });
  });
}

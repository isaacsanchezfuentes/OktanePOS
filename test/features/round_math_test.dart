import 'package:flutter_test/flutter_test.dart';
import 'package:oktane_pos/features/charge/models/charge_model.dart';
import 'package:oktane_pos/features/tables/services/table_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Atomic Accumulative Kitchen Rounds & Table Math Tests', () {
    test('Calculates strictly accumulative round additions without dropping', () {
      double tableTotal = 100.0;

      // Round 1: + $35.00 (Refresco)
      const round1Amount = 35.0;
      tableTotal += round1Amount;
      expect(tableTotal, 135.0);

      // Round 2: + $45.00 (Café)
      const round2Amount = 45.0;
      tableTotal += round2Amount;
      expect(tableTotal, 180.0);

      // Round 3: + $120.00 (Tacos)
      const round3Amount = 120.0;
      tableTotal += round3Amount;
      expect(tableTotal, 300.0);
    });

    test('TableService updates tickets and retains accumulated total', () {
      final tableService = TableService();
      const zoneId = '11111111-1111-4000-8000-000000000001';
      const tableId = '00000000-0000-4000-8000-000000000001';

      tableService.addTicketToTable(
        zoneId,
        tableId,
        amount: 100.0,
        concept: 'Ronda 1: Tacos',
        waiterId: 'u-1',
        waiterName: 'Juan',
      );

      var tables = tableService.getTablesByZone(zoneId);
      var table = tables.firstWhere((t) => t.id == tableId);
      double total1 = table.activeTickets.fold(0.0, (sum, t) => sum + ((t['amount'] as num?)?.toDouble() ?? 0.0));
      expect(total1, 100.0);

      tableService.addTicketToTable(
        zoneId,
        tableId,
        amount: 35.0,
        concept: 'Ronda 2: Refresco',
        waiterId: 'u-1',
        waiterName: 'Juan',
      );

      tables = tableService.getTablesByZone(zoneId);
      table = tables.firstWhere((t) => t.id == tableId);
      double total2 = table.activeTickets.fold(0.0, (sum, t) => sum + ((t['amount'] as num?)?.toDouble() ?? 0.0));
      expect(total2, 135.0);
    });
  });
}

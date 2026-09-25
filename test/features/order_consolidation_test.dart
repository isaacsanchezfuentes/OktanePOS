import 'package:flutter_test/flutter_test.dart';
import 'package:oktane_pos/features/tables/services/table_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Single Table Order Consolidation Tests', () {
    test('Consolidates multiple kitchen rounds into single table total without fragmenting', () {
      final tableService = TableService();
      final zones = tableService.getZones();
      final salonZoneId = zones.first.id;

      final tables = tableService.getTablesByZone(salonZoneId);
      final testTable = tables.firstWhere((t) => t.tableNumber == 2); // Free table

      // Round 1
      tableService.addTicketToTable(
        salonZoneId,
        testTable.id,
        amount: 120.0,
        concept: r'Ronda 1: 2x Tacos ($120)',
        waiterId: 'u-waiter-1',
        waiterName: 'Carlos',
      );

      var updatedTables = tableService.getTablesByZone(salonZoneId);
      var currentTable = updatedTables.firstWhere((t) => t.id == testTable.id);

      expect(currentTable.status, 'occupied');
      expect(currentTable.activeTickets.length, 1);

      var totalTableAmount = currentTable.activeTickets.fold(0.0, (sum, t) => sum + ((t['amount'] as num).toDouble()));
      expect(totalTableAmount, 120.0);

      // Round 2 (Additional order)
      tableService.addTicketToTable(
        salonZoneId,
        testTable.id,
        amount: 85.0,
        concept: r'Ronda 2: 1x Refresco ($35), 1x Flán ($50)',
        waiterId: 'u-waiter-1',
        waiterName: 'Carlos',
      );

      updatedTables = tableService.getTablesByZone(salonZoneId);
      currentTable = updatedTables.firstWhere((t) => t.id == testTable.id);

      expect(currentTable.activeTickets.length, 2);
      totalTableAmount = currentTable.activeTickets.fold(0.0, (sum, t) => sum + ((t['amount'] as num).toDouble()));
      expect(totalTableAmount, 205.0);

      // Settlement: Clear all table tickets -> Liberate table
      tableService.clearAllTableTickets(salonZoneId, testTable.id);

      updatedTables = tableService.getTablesByZone(salonZoneId);
      currentTable = updatedTables.firstWhere((t) => t.id == testTable.id);

      expect(currentTable.status, 'free');
      expect(currentTable.activeTickets.isEmpty, true);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:oktane_pos/features/tables/services/table_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Consolidated Table Charging & Table Liberation Tests', () {
    test('Calculates total table amount and clears table tickets upon payment completion', () {
      final tableService = TableService();
      final zones = tableService.getZones();
      final salonZoneId = zones.first.id;

      final tables = tableService.getTablesByZone(salonZoneId);
      final freeTable = tables.firstWhere((t) => t.status == 'free');

      tableService.addTicketToTable(
        salonZoneId,
        freeTable.id,
        amount: 250.0,
        concept: 'Mesa 1 - Bebidas',
        waiterId: 'u-1',
        waiterName: 'Carlos',
      );

      final updatedTables1 = tableService.getTablesByZone(salonZoneId);
      final occupiedTable = updatedTables1.firstWhere((t) => t.id == freeTable.id);

      expect(occupiedTable.activeTickets.isNotEmpty, isTrue);

      final totalAmount = occupiedTable.activeTickets.fold(0.0, (sum, t) {
        return sum + ((t['amount'] as num?)?.toDouble() ?? 0.0);
      });

      expect(totalAmount, 250.0);

      // Execute table liberation
      tableService.clearAllTableTickets(salonZoneId, occupiedTable.id);

      final updatedTables2 = tableService.getTablesByZone(salonZoneId);
      final freedTable = updatedTables2.firstWhere((t) => t.id == occupiedTable.id);

      expect(freedTable.status, 'free');
      expect(freedTable.assignedWaiter, isNull);
      expect(freedTable.activeTickets.isEmpty, isTrue);
    });
  });
}

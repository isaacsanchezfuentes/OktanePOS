import 'package:flutter_test/flutter_test.dart';
import 'package:oktane_pos/features/tables/services/table_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Table Order Detail & Round Calculations Tests', () {
    test('Calculates previous rounds and new round subtotals correctly', () {
      final tableService = TableService();
      final zones = tableService.getZones();
      final salonZoneId = zones.first.id;

      final tables = tableService.getTablesByZone(salonZoneId);
      final freeTable = tables.firstWhere((t) => t.status == 'free');

      tableService.addTicketToTable(
        salonZoneId,
        freeTable.id,
        amount: 250.0,
        concept: r'Mesa 1 - Consumo ($250)',
        waiterId: 'u-1',
        waiterName: 'Carlos',
      );

      final updatedTables = tableService.getTablesByZone(salonZoneId);
      final occupiedTable = updatedTables.firstWhere((t) => t.id == freeTable.id);

      final previousRoundsTotal = occupiedTable.activeTickets.fold(0.0, (sum, ticket) {
        return sum + ((ticket['amount'] as num?)?.toDouble() ?? 0.0);
      });

      expect(previousRoundsTotal, 250.0);

      // Simulate new round items
      final newRoundItems = [
        {'name': 'Tacos de Asada', 'price': 110.0, 'quantity': 2, 'subtotal': 220.0},
        {'name': 'Capuchino', 'price': 45.0, 'quantity': 1, 'subtotal': 45.0},
      ];

      final newRoundTotal = newRoundItems.fold(0.0, (sum, item) {
        return sum + ((item['subtotal'] as num?)?.toDouble() ?? 0.0);
      });

      expect(newRoundTotal, 265.0);

      final grandTotal = previousRoundsTotal + newRoundTotal;
      expect(grandTotal, 515.0);
    });
  });
}

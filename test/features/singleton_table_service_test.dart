import 'package:flutter_test/flutter_test.dart';
import 'package:oktane_pos/features/tables/services/table_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Singleton TableService & Reactive Map Tests', () {
    test('TableService() always returns the exact same shared singleton instance', () {
      final instance1 = TableService();
      final instance2 = TableService();

      expect(identical(instance1, instance2), isTrue);
    });

    test('addTicketToTable updates table status to occupied and triggers listener notification', () async {
      final tableService = TableService();
      const tableId = '00000000-0000-4000-8000-000000000001';

      bool listenerNotified = false;
      tableService.addListener(() {
        listenerNotified = true;
      });

      await tableService.addTicketToTable(
        '11111111-1111-4000-8000-000000000001',
        tableId,
        amount: 250.0,
        concept: '2x Tacos + 1x Refresco',
        waiterId: 'u-waiter',
        waiterName: 'Carlos',
      );

      expect(listenerNotified, isTrue);

      final zones = tableService.getZones();
      final tables = tableService.getTablesByZone(zones.first.id);
      final updatedTable = tables.firstWhere((t) => t.id == tableId);

      expect(updatedTable.status, 'occupied');
      expect(updatedTable.activeTickets.isNotEmpty, isTrue);
      expect(updatedTable.activeTickets.last['amount'], 250.0);
    });
  });
}

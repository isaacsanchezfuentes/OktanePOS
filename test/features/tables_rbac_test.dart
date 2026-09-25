import 'package:flutter_test/flutter_test.dart';
import 'package:oktane_pos/features/auth/services/rbac_service.dart';
import 'package:oktane_pos/features/tables/services/table_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('RBAC Service Unit Tests', () {
    test('Correctly identifies roles for waiter, manager, admin', () {
      final rbac = RbacService();

      expect(rbac.parseRole('CHOFER'), PosRole.waiter);
      expect(rbac.parseRole('MESERO'), PosRole.waiter);
      expect(rbac.parseRole('GERENTE'), PosRole.manager);
      expect(rbac.parseRole('ADMIN'), PosRole.admin);

      expect(rbac.isWaiter('CHOFER'), isTrue);
      expect(rbac.isManagerOrAdmin('ADMIN'), isTrue);
      expect(rbac.isManagerOrAdmin('GERENTE'), isTrue);
      expect(rbac.isManagerOrAdmin('CHOFER'), isFalse);
    });
  });

  group('Table Service & Ticket Management Tests', () {
    test('Adds tickets to table and marks peer support correctly', () {
      final tableService = TableService();
      final zones = tableService.getZones();
      final salonZoneId = zones.first.id;

      final tables = tableService.getTablesByZone(salonZoneId);
      final freeTable = tables.firstWhere((t) => t.status == 'free');

      // Add first ticket by Carlos
      tableService.addTicketToTable(
        salonZoneId,
        freeTable.id,
        amount: 300.0,
        concept: 'Mesa ${freeTable.tableNumber} - Consumo 1',
        waiterId: 'u-carlos',
        waiterName: 'Carlos',
      );

      final updatedTables1 = tableService.getTablesByZone(salonZoneId);
      final occupiedTable = updatedTables1.firstWhere((t) => t.id == freeTable.id);

      expect(occupiedTable.status, 'occupied');
      expect(occupiedTable.assignedWaiter, 'Carlos');
      expect(occupiedTable.activeTickets.length, 1);
      expect(occupiedTable.activeTickets.first['is_peer_support'], isFalse);

      // Add second ticket by peer Ana (Apoyo)
      tableService.addTicketToTable(
        salonZoneId,
        freeTable.id,
        amount: 150.0,
        concept: 'Mesa ${freeTable.tableNumber} - Bebidas',
        waiterId: 'u-ana',
        waiterName: 'Ana (Apoyo)',
      );

      final updatedTables2 = tableService.getTablesByZone(salonZoneId);
      final peerSupportedTable = updatedTables2.firstWhere((t) => t.id == freeTable.id);

      expect(peerSupportedTable.activeTickets.length, 2);
      final peerTicket = peerSupportedTable.activeTickets.last;
      expect(peerTicket['is_peer_support'], isTrue);
    });

    test('Removes ticket and frees table when active tickets become empty', () {
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

      final tablesWithTicket = tableService.getTablesByZone(salonZoneId);
      final tableWithTickets = tablesWithTicket.firstWhere((t) => t.id == freeTable.id);

      final ticketId = tableWithTickets.activeTickets.first['ticket_id'];

      tableService.removeTicketAndCheckFree(salonZoneId, tableWithTickets.id, ticketId);

      final updatedTables = tableService.getTablesByZone(salonZoneId);
      final clearedTable = updatedTables.firstWhere((t) => t.id == freeTable.id);

      expect(clearedTable.activeTickets.isEmpty, isTrue);
      expect(clearedTable.status, 'free');
      expect(clearedTable.assignedWaiter, isNull);
    });
  });
}

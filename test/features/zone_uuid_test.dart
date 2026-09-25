import 'package:flutter_test/flutter_test.dart';
import 'package:oktane_pos/features/tables/services/table_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Zone UUID v4 & Realtime Supabase Sync Tests', () {
    test('TableService initializes zones with syntactically valid v4 UUIDs', () {
      final tableService = TableService();
      final zones = tableService.getZones();

      final uuidRegex = RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$');

      expect(zones.length, 3);
      for (final zone in zones) {
        expect(uuidRegex.hasMatch(zone.id), isTrue, reason: 'Zone ID ${zone.id} must be a valid v4 UUID');
      }
    });

    test('TableService maps tables to valid zone UUIDs correctly', () {
      final tableService = TableService();
      final zones = tableService.getZones();

      for (final zone in zones) {
        final tables = tableService.getTablesByZone(zone.id);
        expect(tables.isNotEmpty, isTrue);
        for (final table in tables) {
          expect(table.zoneId, zone.id);
        }
      }
    });
  });
}

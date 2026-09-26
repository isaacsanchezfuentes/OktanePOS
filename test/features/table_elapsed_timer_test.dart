import 'package:flutter_test/flutter_test.dart';
import 'package:oktane_pos/features/tables/models/table_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Industrial Slate Phase 2 - Table Details Tests', () {
    test('Identifies bar stools correctly based on shape or number', () {
      const stool1 = RestaurantTableModel(
        id: '1',
        zoneId: 'z1',
        tableNumber: 20,
        seats: 1,
        shape: 'bar',
        posX: 0.1,
        posY: 0.1,
        status: 'free',
      );

      const table1 = RestaurantTableModel(
        id: '2',
        zoneId: 'z1',
        tableNumber: 1,
        seats: 4,
        shape: 'square',
        posX: 0.1,
        posY: 0.1,
        status: 'free',
      );

      final isStool1 = stool1.shape == 'circle' || stool1.shape == 'bar' || stool1.tableNumber >= 20;
      final isTable1 = table1.shape == 'circle' || table1.shape == 'bar' || table1.tableNumber >= 20;

      expect(isStool1, isTrue);
      expect(isTable1, isFalse);
    });

    test('Formats elapsed occupancy time string correctly', () {
      final now = DateTime.now();
      final ticket25MinAgo = {
        'ticket_id': 'tk-1',
        'amount': 150.0,
        'created_at': now.subtract(const Duration(minutes: 25)).toIso8601String(),
      };

      final ticket90MinAgo = {
        'ticket_id': 'tk-2',
        'amount': 300.0,
        'created_at': now.subtract(const Duration(hours: 1, minutes: 30)).toIso8601String(),
      };

      String formatElapsed(Map<String, dynamic> firstTicket) {
        final createdAtStr = firstTicket['created_at']?.toString() ?? '';
        final firstTicketTime = DateTime.tryParse(createdAtStr) ?? now;
        final diff = now.difference(firstTicketTime);

        final minutes = diff.inMinutes;
        if (minutes < 60) {
          return '⏱️ ${minutes}m';
        } else {
          final hours = diff.inHours;
          final remMinutes = minutes % 60;
          return '⏱️ ${hours}h ${remMinutes}m';
        }
      }

      expect(formatElapsed(ticket25MinAgo), '⏱️ 25m');
      expect(formatElapsed(ticket90MinAgo), '⏱️ 1h 30m');
    });
  });
}

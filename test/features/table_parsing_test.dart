import 'package:flutter_test/flutter_test.dart';
import 'package:oktane_pos/features/tables/models/table_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('RestaurantTableModel Robust Type Parsing Tests', () {
    test('Correctly parses String table_number, seats, and double position fields from Supabase JSON', () {
      final StringJson = {
        'id': '00000000-0000-4000-8000-000000000001',
        'zone_id': '11111111-1111-4000-8000-000000000001',
        'table_number': '1', // String from Supabase text column
        'seats': '4', // String representation
        'pos_x': '0.25', // String representation
        'pos_y': '0.35', // String representation
        'status': 'occupied',
      };

      final table = RestaurantTableModel.fromJson(StringJson);

      expect(table.tableNumber, 1);
      expect(table.seats, 4);
      expect(table.posX, 0.25);
      expect(table.posY, 0.35);
      expect(table.status, 'occupied');
    });

    test('Correctly parses numeric table_number, seats, and double position fields', () {
      final NumericJson = {
        'id': '00000000-0000-4000-8000-000000000002',
        'zone_id': '11111111-1111-4000-8000-000000000001',
        'table_number': 2,
        'seats': 6,
        'pos_x': 0.50,
        'pos_y': 0.60,
        'status': 'free',
      };

      final table = RestaurantTableModel.fromJson(NumericJson);

      expect(table.tableNumber, 2);
      expect(table.seats, 6);
      expect(table.posX, 0.50);
      expect(table.posY, 0.60);
      expect(table.status, 'free');
    });
  });
}

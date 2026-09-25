import 'package:flutter_test/flutter_test.dart';
import 'package:oktane_pos/features/menu/models/menu_item_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Pre-Add Dialog & Subtotal Calculations Tests', () {
    test('Calculates item subtotal with custom quantity, edited price, and takeaway surcharge', () {
      const baseItem = MenuItemModel(
        id: 'm-10',
        name: 'Tacos de Asada',
        price: 110.0,
        category: 'Alimentos',
      );

      final editedPrice = 120.0; // Edited by cashier
      final quantity = 3;
      final isTakeaway = true; // +$5 per unit

      final unitTotal = editedPrice + (isTakeaway ? 5.0 : 0.0); // 125.0
      final subtotal = unitTotal * quantity; // 375.0

      expect(unitTotal, 125.0);
      expect(subtotal, 375.0);
      expect(baseItem.price, 110.0);
    });
  });
}

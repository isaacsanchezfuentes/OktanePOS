import 'package:flutter_test/flutter_test.dart';
import 'package:oktane_pos/features/menu/models/menu_item_model.dart';
import 'package:oktane_pos/features/menu/services/menu_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Menu Catalog & Fast Entry Tests', () {
    test('MenuService loads default products and filters active items', () {
      final service = MenuService();
      final allItems = service.getMenuItems();

      expect(allItems.isNotEmpty, isTrue);
      expect(allItems.length, greaterThanOrEqualTo(8));

      // Toggle active status
      final firstItem = allItems.first;
      service.toggleItemActive(firstItem.id);

      final activeItems = service.getMenuItems(activeOnly: true);
      expect(activeItems.any((i) => i.id == firstItem.id), isFalse);
    });

    test('Saves new menu product and updates existing product', () {
      final service = MenuService();

      const newProduct = MenuItemModel(
        id: 'm-99',
        name: 'Taza de Chocolate Hot',
        price: 40.0,
        category: 'Bebidas',
      );

      service.saveMenuItem(newProduct);
      final itemsAfterSave = service.getMenuItems();

      expect(itemsAfterSave.any((i) => i.id == 'm-99'), isTrue);

      const updatedProduct = MenuItemModel(
        id: 'm-99',
        name: 'Taza de Chocolate Hot Especial',
        price: 50.0,
        category: 'Bebidas',
      );

      service.saveMenuItem(updatedProduct);
      final itemsAfterUpdate = service.getMenuItems();
      final saved = itemsAfterUpdate.firstWhere((i) => i.id == 'm-99');

      expect(saved.name, 'Taza de Chocolate Hot Especial');
      expect(saved.price, 50.0);
    });
  });
}

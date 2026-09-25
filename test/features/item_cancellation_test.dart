import 'package:flutter_test/flutter_test.dart';

List<Map<String, dynamic>> parseItemsFromConcept(String concept) {
  final List<Map<String, dynamic>> items = [];
  final regExp = RegExp(r'(?:(\d+)\s*x\s*)?([^\(\$]+?)\s*\(\$([\d\.]+)\)');
  final matches = regExp.allMatches(concept);

  for (final match in matches) {
    final qtyStr = match.group(1);
    var rawName = match.group(2)?.trim() ?? 'Producto';
    final priceStr = match.group(3);

    var qty = int.tryParse(qtyStr ?? '1') ?? 1;
    final price = double.tryParse(priceStr ?? '0.0') ?? 0.0;

    rawName = rawName.replaceAll(RegExp(r'^[,\s]+'), '');
    rawName = rawName.replaceAll(RegExp(r'Mesa\s*#?\d+\s*-\s*'), '');
    rawName = rawName.replaceAll(RegExp(r'Ronda:\s*'), '');
    rawName = rawName.replaceAll(RegExp(r'Ronda\s*'), '');
    rawName = rawName.replaceAll(RegExp(r'^[,\s]+'), '');

    final qtyPrefixMatch = RegExp(r'^(\d+)\s*x\s*').firstMatch(rawName);
    if (qtyPrefixMatch != null) {
      qty = int.tryParse(qtyPrefixMatch.group(1)!) ?? qty;
      rawName = rawName.substring(qtyPrefixMatch.group(0)!.length).trim();
    }

    final cleanName = rawName.trim();
    final subtotal = price * qty;

    if (cleanName.isNotEmpty && price > 0) {
      items.add({
        'name': cleanName,
        'quantity': qty,
        'price': price,
        'subtotal': subtotal,
      });
    }
  }

  return items;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Individual Dispatched Items Breakdown & Item Cancellation Tests', () {
    test('Parses concept string into individual structured items correctly', () {
      const concept = 'Mesa #1 - Ronda: 1x Pizza Pepperoni (\$120.0), 1x Cerveza Corona (\$65.0)';

      final items = parseItemsFromConcept(concept);

      expect(items.length, 2);
      expect(items[0]['name'], 'Pizza Pepperoni');
      expect(items[0]['quantity'], 1);
      expect(items[0]['price'], 120.0);

      expect(items[1]['name'], 'Cerveza Corona');
      expect(items[1]['quantity'], 1);
      expect(items[1]['price'], 65.0);
    });

    test('Recalculates amount when an item is deleted, and reaches 0 when all items deleted', () {
      final items = [
        {'name': 'Pizza Pepperoni', 'quantity': 1, 'price': 120.0},
        {'name': 'Cerveza Corona', 'quantity': 1, 'price': 65.0},
      ];

      double initialTotal = items.fold(0.0, (sum, i) => sum + ((i['price'] as double) * (i['quantity'] as int)));
      expect(initialTotal, 185.0);

      // Remove Cerveza Corona
      items.removeWhere((i) => i['name'] == 'Cerveza Corona');
      double updatedTotal = items.fold(0.0, (sum, i) => sum + ((i['price'] as double) * (i['quantity'] as int)));
      expect(updatedTotal, 120.0);

      // Remove Pizza Pepperoni
      items.removeWhere((i) => i['name'] == 'Pizza Pepperoni');
      double finalTotal = items.fold(0.0, (sum, i) => sum + ((i['price'] as double) * (i['quantity'] as int)));
      expect(finalTotal, 0.0);
    });
  });
}

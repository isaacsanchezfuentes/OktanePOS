import 'package:flutter/foundation.dart';
import '../models/menu_item_model.dart';

class MenuService {
  final List<MenuItemModel> _items = [
    const MenuItemModel(id: 'm-1', name: 'Café Americano', price: 35.0, category: 'Bebidas'),
    const MenuItemModel(id: 'm-2', name: 'Capuchino', price: 45.0, category: 'Bebidas'),
    const MenuItemModel(id: 'm-3', name: 'Refresco 600ml', price: 30.0, category: 'Bebidas'),
    const MenuItemModel(id: 'm-4', name: 'Cerveza Artesanal', price: 65.0, category: 'Bebidas'),
    const MenuItemModel(id: 'm-5', name: 'Tacos de Asada (Orden)', price: 110.0, category: 'Alimentos'),
    const MenuItemModel(id: 'm-6', name: 'Hamburguesa Clásica', price: 135.0, category: 'Alimentos'),
    const MenuItemModel(id: 'm-7', name: 'Pizza Individual Pepperoni', price: 120.0, category: 'Alimentos'),
    const MenuItemModel(id: 'm-8', name: 'Pastel de Chocolate', price: 55.0, category: 'Postres'),
  ];

  List<MenuItemModel> getMenuItems({bool activeOnly = false}) {
    if (activeOnly) {
      return List.unmodifiable(_items.where((item) => item.isActive));
    }
    return List.unmodifiable(_items);
  }

  void saveMenuItem(MenuItemModel item) {
    final index = _items.indexWhere((i) => i.id == item.id);
    if (index != -1) {
      _items[index] = item;
      debugPrint('✏️ Producto actualizado: ${item.name} (\$${item.price})');
    } else {
      _items.add(item);
      debugPrint('➕ Nuevo producto agregado al catálogo: ${item.name}');
    }
  }

  void toggleItemActive(String id) {
    final index = _items.indexWhere((i) => i.id == id);
    if (index != -1) {
      _items[index] = _items[index].copyWith(isActive: !_items[index].isActive);
      debugPrint('🔄 Estatus cambiado para ${_items[index].name}: ${_items[index].isActive}');
    }
  }

  void deleteMenuItem(String id) {
    _items.removeWhere((i) => i.id == id);
    debugPrint('🗑️ Producto $id eliminado del catálogo');
  }
}

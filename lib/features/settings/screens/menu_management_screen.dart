import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../menu/models/menu_item_model.dart';
import '../../menu/services/menu_service.dart';

class MenuManagementScreen extends StatefulWidget {
  final MenuService? menuService;

  const MenuManagementScreen({
    super.key,
    this.menuService,
  });

  @override
  State<MenuManagementScreen> createState() => _MenuManagementScreenState();
}

class _MenuManagementScreenState extends State<MenuManagementScreen> {
  late final MenuService _menuService;
  final TextEditingController _searchController = TextEditingController();

  List<MenuItemModel> _allItems = [];
  List<MenuItemModel> _filteredItems = [];

  @override
  void initState() {
    super.initState();
    _menuService = widget.menuService ?? MenuService();
    _loadItems();
  }

  void _loadItems() {
    final list = _menuService.getMenuItems();
    setState(() {
      _allItems = list;
      _applySearchFilter();
    });
  }

  void _applySearchFilter() {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      _filteredItems = List.from(_allItems);
    } else {
      _filteredItems = _allItems.where((item) {
        final nameMatch = item.name.toLowerCase().contains(query);
        final catMatch = item.category.toLowerCase().contains(query);
        return nameMatch || catMatch;
      }).toList();
    }
  }

  String _formatCurrency(double amount) {
    return NumberFormat.currency(locale: 'es_MX', symbol: '\$', decimalDigits: 2).format(amount);
  }

  void _showAddEditItemDialog([MenuItemModel? existingItem]) {
    final nameCtrl = TextEditingController(text: existingItem?.name ?? '');
    final priceCtrl = TextEditingController(text: existingItem?.price.toStringAsFixed(2) ?? '');
    String selectedCategory = existingItem?.category ?? 'Alimentos';
    final formKey = GlobalKey<FormState>();

    final categories = ['Alimentos', 'Bebidas', 'Postres', 'Otros'];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          title: Text(existingItem == null ? '+ Nuevo Producto' : 'Editar Producto'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Nombre del Producto', border: OutlineInputBorder()),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: priceCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Precio', prefixText: '\$ ', border: OutlineInputBorder()),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Requerido';
                    if (double.tryParse(v.trim()) == null) return 'Precio inválido';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  decoration: const InputDecoration(labelText: 'Categoría', border: OutlineInputBorder()),
                  items: categories.map((cat) => DropdownMenuItem(value: cat, child: Text(cat))).toList(),
                  onChanged: (val) {
                    if (val != null) setModalState(() => selectedCategory = val);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () {
                if (!formKey.currentState!.validate()) return;

                final newItem = MenuItemModel(
                  id: existingItem?.id ?? 'm-${DateTime.now().millisecondsSinceEpoch}',
                  name: nameCtrl.text.trim(),
                  price: double.tryParse(priceCtrl.text.trim()) ?? 0.0,
                  category: selectedCategory,
                  isActive: existingItem?.isActive ?? true,
                );

                _menuService.saveMenuItem(newItem);
                Navigator.pop(ctx);
                _loadItems();

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('✅ Producto ${newItem.name} guardado exitosamente')),
                );
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Catálogo de Menú', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar producto por nombre o categoría...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _applySearchFilter());
                        },
                      )
                    : null,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onChanged: (_) => setState(() => _applySearchFilter()),
            ),
          ),

          // Product List
          Expanded(
            child: _filteredItems.isEmpty
                ? Center(
                    child: Text('No se encontraron productos', style: TextStyle(color: Colors.grey[600])),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _filteredItems.length,
                    itemBuilder: (context, index) {
                      final item = _filteredItems[index];

                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        elevation: 1,
                        child: ListTile(
                          title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('Categoría: ${item.category}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _formatCurrency(item.price),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green),
                              ),
                              const SizedBox(width: 8),
                              Switch(
                                value: item.isActive,
                                onChanged: (_) {
                                  _menuService.toggleItemActive(item.id);
                                  _loadItems();
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit, size: 20, color: Colors.blue),
                                onPressed: () => _showAddEditItemDialog(item),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditItemDialog(),
        icon: const Icon(Icons.add),
        label: const Text('NUEVO PRODUCTO'),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../menu/models/menu_item_model.dart';

class ItemPreAddDialog extends StatefulWidget {
  final MenuItemModel menuItem;

  const ItemPreAddDialog({
    super.key,
    required this.menuItem,
  });

  static Future<Map<String, dynamic>?> show(
    BuildContext context, {
    required MenuItemModel menuItem,
  }) {
    return showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: true,
      builder: (context) => ItemPreAddDialog(menuItem: menuItem),
    );
  }

  @override
  State<ItemPreAddDialog> createState() => _ItemPreAddDialogState();
}

class _ItemPreAddDialogState extends State<ItemPreAddDialog> {
  late final TextEditingController _priceController;
  final TextEditingController _notesController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  int _quantity = 1;
  bool _isTakeaway = false;

  @override
  void initState() {
    super.initState();
    _priceController = TextEditingController(
      text: widget.menuItem.price.toStringAsFixed(2),
    );
  }

  @override
  void dispose() {
    _priceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  double get _editedPrice => double.tryParse(_priceController.text.trim()) ?? widget.menuItem.price;

  double get _unitTotal => _editedPrice + (_isTakeaway ? 5.0 : 0.0);

  double get _itemSubtotal => _unitTotal * _quantity;

  String _formatCurrency(double val) {
    return NumberFormat.currency(locale: 'es_MX', symbol: '\$', decimalDigits: 2).format(val);
  }

  void _confirmAdd() {
    if (!_formKey.currentState!.validate()) return;

    final result = {
      'item_id': widget.menuItem.id,
      'name': widget.menuItem.name,
      'price': _editedPrice,
      'quantity': _quantity,
      'is_takeaway': _isTakeaway,
      'notes': _notesController.text.trim(),
      'subtotal': _itemSubtotal,
    };

    Navigator.pop(context, result);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          const Icon(Icons.fastfood, color: Colors.indigo),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              widget.menuItem.name,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Price and Quantity Row
              Row(
                children: [
                  // Editable Price Field
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      controller: _priceController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Precio Unitario',
                        prefixText: '\$ ',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Requerido';
                        if (double.tryParse(v.trim()) == null) return 'Inválido';
                        return null;
                      },
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Quantity Selector
                  Expanded(
                    flex: 3,
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[400]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove, size: 18),
                            onPressed: _quantity > 1
                                ? () => setState(() => _quantity--)
                                : null,
                          ),
                          Text(
                            '$_quantity',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add, size: 18),
                            onPressed: () => setState(() => _quantity++),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Takeaway Toggle Chip
              Align(
                alignment: Alignment.centerLeft,
                child: FilterChip(
                  label: const Text('+\$5 Para llevar', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  selected: _isTakeaway,
                  selectedColor: Colors.deepOrange[100],
                  onSelected: (val) => setState(() => _isTakeaway = val),
                ),
              ),
              const SizedBox(height: 12),

              // Prep Notes Text Field
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notas de Preparación (Opcional)',
                  hintText: 'Ej. sin sal, salsa aparte, extra picante',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                ),
              ),
              const SizedBox(height: 16),

              // Subtotal Highlight Banner
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.indigo[50],
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.indigo[200]!),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('SUBTOTAL ÍTEM:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.indigo)),
                    Text(
                      _formatCurrency(_itemSubtotal),
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo[900]),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton.icon(
          onPressed: _confirmAdd,
          icon: const Icon(Icons.add_shopping_cart, size: 18),
          label: const Text('AGREGAR A LA ORDEN'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.indigo[800],
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }
}

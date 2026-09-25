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
    final mediaQuery = MediaQuery.of(context);
    final isTablet = mediaQuery.size.width > 600;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: isTablet ? 500 : mediaQuery.size.width * 0.92,
          maxHeight: mediaQuery.size.height * 0.85,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Title Header
              Row(
                children: [
                  const Icon(Icons.fastfood, color: Colors.indigo, size: 24),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.menuItem.name,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Scrollable Form Body
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Form(
                    key: _formKey,
                    child: Column(
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
                                decoration: InputDecoration(
                                  labelText: 'Precio Unitario',
                                  prefixText: '\$ ',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey[400]!),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.remove, size: 20),
                                      onPressed: _quantity > 1
                                          ? () => setState(() => _quantity--)
                                          : null,
                                    ),
                                    Text(
                                      '$_quantity',
                                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.add, size: 20),
                                      onPressed: () => setState(() => _quantity++),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

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
                        const SizedBox(height: 14),

                        // Prep Notes Text Field
                        TextFormField(
                          controller: _notesController,
                          decoration: InputDecoration(
                            labelText: 'Notas de Preparación (Opcional)',
                            hintText: 'Ej. sin sal, salsa aparte, extra picante',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Subtotal Highlight Banner
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.indigo[50],
                            borderRadius: BorderRadius.circular(12),
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
              ),
              const SizedBox(height: 12),

              // Actions Footer
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _confirmAdd,
                    icon: const Icon(Icons.add_shopping_cart, size: 18),
                    label: const Text('AGREGAR A LA ORDEN'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo[800],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

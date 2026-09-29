import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/charge_service.dart';
import '../widgets/amount_display.dart';
import '../widgets/pos_keypad.dart';
import '../widgets/payment_method_bottom_sheet.dart';
import '../widgets/item_pre_add_dialog.dart';
import 'charges_history_screen.dart';
import '../../printer/screens/printer_settings_screen.dart';
import '../../cash_cut/services/shift_service.dart';
import '../../tables/theme/table_theme.dart';
import 'package:oktane_pos/core/localization/app_locale.dart';
import 'package:oktane_pos/core/theme/theme_service.dart';
import '../../tables/screens/tables_map_screen.dart';
import '../../tables/services/table_service.dart';
import 'package:oktane_pos/features/tables/models/zone_model.dart';
import 'package:oktane_pos/features/tables/models/table_model.dart';
import 'package:oktane_pos/features/menu/models/menu_item_model.dart';
import 'package:oktane_pos/features/menu/services/menu_service.dart';
import 'package:oktane_pos/features/settings/screens/settings_screen.dart';
import 'package:oktane_pos/features/tables/screens/table_order_detail_screen.dart';

class QuickChargeScreen extends StatefulWidget {
  final double? initialAmount;
  final String? initialConcept;
  final String? tableId;
  final String? zoneId;
  final String? tableName;
  final TableService? tableService;
  final VoidCallback? onPaymentSuccess;

  const QuickChargeScreen({
    super.key,
    this.initialAmount,
    this.initialConcept,
    this.tableId,
    this.zoneId,
    this.tableName,
    this.tableService,
    this.onPaymentSuccess,
  });

  @override
  State<QuickChargeScreen> createState() => _QuickChargeScreenState();
}

class _QuickChargeScreenState extends State<QuickChargeScreen> {
  late final ChargeService _chargeService;
  late final ShiftService _shiftService;
  late final TableService _tableService;
  late final MenuService _menuService;

  TextEditingController? _menuSearchController;

  double _amount = 0.0;
  String _rawInput = '0';
  String _calculatorExpression = '';
  double? _lastAnswer;
  bool _isScientificMode = false;
  final TextEditingController _conceptController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  String _selectedTableLabel = 'Barra / Mostrador';
  String? _selectedWaiterId;
  String? _selectedWaiterName;

  final List<Map<String, dynamic>> _pendingOrderItems = [];
  int? _lastModifiedIndex;
  Timer? _highlightTimer;

  // Filtro activo de categoría
  String _selectedCategory = 'Todos';
  final List<String> _categories = ['Todos', 'Bebidas', 'Alimentos', 'Postres', 'Otros'];

  @override
  void initState() {
    super.initState();
    _chargeService = ChargeService();
    _shiftService = ShiftService();
    _tableService = widget.tableService ?? TableService();
    _menuService = MenuService();

    if (widget.initialAmount != null && widget.initialAmount! > 0) {
      _amount = widget.initialAmount!;
      _rawInput = widget.initialAmount!.toStringAsFixed(2);
    }
    if (widget.initialConcept != null && widget.initialConcept!.isNotEmpty) {
      _conceptController.text = widget.initialConcept!;
    }
    if (widget.tableName != null && widget.tableName!.isNotEmpty) {
      _selectedTableLabel = widget.tableName!;
    }
  }

  void _triggerHighlight(int index) {
    _highlightTimer?.cancel();
    setState(() {
      _lastModifiedIndex = index;
    });
    _highlightTimer = Timer(const Duration(milliseconds: 1400), () {
      if (mounted) {
        setState(() {
          _lastModifiedIndex = null;
        });
      }
    });
  }

  void _onProductQuickTapped(MenuItemModel item) {
    final existingIdx = _pendingOrderItems.indexWhere((it) => it['id'] == item.id);
    setState(() {
      if (existingIdx >= 0) {
        final currentQty = (_pendingOrderItems[existingIdx]['quantity'] as num).toInt();
        final newQty = currentQty + 1;
        _pendingOrderItems[existingIdx]['quantity'] = newQty;
        _pendingOrderItems[existingIdx]['subtotal'] = item.price * newQty;
        _triggerHighlight(existingIdx);
      } else {
        _pendingOrderItems.add({
          'id': item.id,
          'name': item.name,
          'price': item.price,
          'quantity': 1,
          'is_takeaway': false,
          'notes': '',
          'subtotal': item.price,
        });
        _triggerHighlight(_pendingOrderItems.length - 1);
      }
      _recalculateTotalFromPendingItems();
    });
  }

  void _removeLastInsertion() {
    setState(() {
      if (_pendingOrderItems.isNotEmpty) {
        final lastIdx = _pendingOrderItems.length - 1;
        final currentQty = (_pendingOrderItems[lastIdx]['quantity'] as num).toInt();
        if (currentQty > 1) {
          _pendingOrderItems[lastIdx]['quantity'] = currentQty - 1;
          _pendingOrderItems[lastIdx]['subtotal'] =
              (_pendingOrderItems[lastIdx]['price'] as num) * (currentQty - 1);
          _triggerHighlight(lastIdx);
        } else {
          _pendingOrderItems.removeAt(lastIdx);
          if (_pendingOrderItems.isNotEmpty) {
            _triggerHighlight(_pendingOrderItems.length - 1);
          }
        }
        _recalculateTotalFromPendingItems();
      } else {
        _handleKeyTap('BACKSPACE');
      }
    });
  }

  void _openScientificWithAns() {
    setState(() {
      _isScientificMode = true;
      _lastAnswer = _amount;
      _calculatorExpression = 'Ans (${_amount.toStringAsFixed(2)})';
      _rawInput = '0';
    });
  }

  void _resetKeypad() {
    setState(() {
      _amount = 0.0;
      _rawInput = '0';
      _calculatorExpression = '';
      _conceptController.clear();
      _notesController.clear();
      _pendingOrderItems.clear();
      _lastModifiedIndex = null;
    });
  }

  void _handleKeyTap(String key) {
    setState(() {
      if (key == 'CLEAR' || key == 'C' || key == 'CA') {
        _resetKeypad();
        return;
      }

      if (key == 'BACKSPACE' || key == '⌫' || key == 'DEL') {
        if (_rawInput.length > 1) {
          _rawInput = _rawInput.substring(0, _rawInput.length - 1);
        } else {
          _rawInput = '0';
        }
        _amount = double.tryParse(_rawInput) ?? 0.0;
        return;
      }

      if (key == '=') {
        _calculateExpressionResult();
        return;
      }

      if (key == 'Ans') {
        if (_lastAnswer != null) {
          _rawInput = _lastAnswer!.toStringAsFixed(2);
          _amount = _lastAnswer!;
          _calculatorExpression += ' Ans';
        }
        return;
      }

      if (key == '×10') {
        _amount = _amount * 10.0;
        _rawInput = _amount.toStringAsFixed(2);
        _calculatorExpression += ' ×10';
        return;
      }

      if (key == '+' || key == '-' || key == '×' || key == '÷') {
        if (_calculatorExpression.contains('Ans') && _rawInput == '0') {
          _calculatorExpression = '$_calculatorExpression $key';
        } else {
          _calculatorExpression += ' ${_amount.toStringAsFixed(2)} $key';
        }
        _rawInput = '0';
        _amount = 0.0;
        return;
      }

      if (_rawInput == '0') {
        if (key == '.') {
          _rawInput = '0.';
        } else {
          _rawInput = key;
        }
      } else {
        if (key == '.' && _rawInput.contains('.')) return;
        if (_rawInput.contains('.') && _rawInput.split('.')[1].length >= 2) return;
        _rawInput += key;
      }

      _amount = double.tryParse(_rawInput) ?? 0.0;
    });
  }

  void _calculateExpressionResult() {
    if (_calculatorExpression.isEmpty) return;

    final fullExpr = '$_calculatorExpression ${_amount.toStringAsFixed(2)}';
    String normalizedExpr = fullExpr;
    if (_lastAnswer != null) {
      normalizedExpr = normalizedExpr.replaceAll(
        RegExp(r'Ans(\s*\([\d\.]+\))?'),
        _lastAnswer!.toStringAsFixed(2),
      );
    }

    final parts = normalizedExpr.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return;

    double accumulator = double.tryParse(parts[0]) ?? 0.0;
    String currentOp = '';

    for (int i = 1; i < parts.length; i++) {
      final token = parts[i];
      if (token == '+' || token == '-' || token == '×' || token == '÷') {
        currentOp = token;
      } else {
        final val = double.tryParse(token) ?? 0.0;
        if (currentOp == '+') {
          accumulator += val;
        } else if (currentOp == '-') {
          accumulator -= val;
        } else if (currentOp == '×') {
          accumulator *= val;
        } else if (currentOp == '÷') {
          if (val != 0) accumulator /= val;
        }
      }
    }

    _lastAnswer = accumulator;
    _amount = accumulator;
    _rawInput = accumulator.toStringAsFixed(2);
    _calculatorExpression = '$fullExpr =';
  }

  void _removePendingItem(int index) {
    setState(() {
      _pendingOrderItems.removeAt(index);
      _recalculateTotalFromPendingItems();
    });
  }

  void _onMenuItemSelected(MenuItemModel selected) async {
    _menuSearchController?.clear();

    final result = await ItemPreAddDialog.show(context, menuItem: selected);

    if (result != null) {
      setState(() {
        final qty = (result['quantity'] as num?)?.toInt() ?? 1;
        final isTakeaway = result['is_takeaway'] == true;
        final notes = result['notes']?.toString() ?? '';
        final takeawayExtra = isTakeaway ? 5.0 : 0.0;
        final subtotal = (selected.price + takeawayExtra) * qty;

        final resultItem = {
          'id': selected.id,
          'name': selected.name,
          'price': selected.price,
          'quantity': qty,
          'is_takeaway': isTakeaway,
          'notes': notes,
          'subtotal': subtotal,
        };

        _pendingOrderItems.add(resultItem);
        _triggerHighlight(_pendingOrderItems.length - 1);
        _recalculateTotalFromPendingItems();
      });
    }
  }

  void _recalculateTotalFromPendingItems() {
    double sum = 0.0;
    for (final item in _pendingOrderItems) {
      sum += (item['subtotal'] as num?)?.toDouble() ?? 0.0;
    }
    _amount = sum;
    _rawInput = sum.toStringAsFixed(2);
  }

  void _navigateToTableOrderDetail() async {
    RestaurantTableModel? targetTable;
    ZoneModel? targetZone;

    for (final z in _tableService.getZones()) {
      for (final t in _tableService.getTablesByZone(z.id)) {
        final label = 'Mesa #${t.tableNumber} (${z.name})';
        if (label == _selectedTableLabel) {
          targetTable = t;
          targetZone = z;
          break;
        }
      }
    }

    if (targetTable == null) {
      targetTable = const RestaurantTableModel(
        id: '00000000-0000-4000-8000-000000000020',
        tableNumber: 20,
        zoneId: '11111111-1111-4000-8000-000000000001',
      );
      targetZone = _tableService.getZones().first;
    }

    if (targetZone != null) {
      if (_pendingOrderItems.isNotEmpty) {
        _tableService.saveTableDraft(targetTable.id, _pendingOrderItems);
      }

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TableOrderDetailScreen(
            table: targetTable!,
            zone: targetZone!,
            tableService: _tableService,
          ),
        ),
      );

      final remainingDraft = _tableService.getTableDraft(targetTable.id);
      setState(() {
        if (remainingDraft.isEmpty) {
          _pendingOrderItems.clear();
          _amount = 0.0;
          _rawInput = '0';
        } else {
          _pendingOrderItems.clear();
          _pendingOrderItems.addAll(remainingDraft);
          _recalculateTotalFromPendingItems();
        }
      });
    }
  }

  void _onWaiterChanged(String name, String id) {
    setState(() {
      _selectedWaiterName = name;
      _selectedWaiterId = id;
    });
  }

  Future<bool> _showMandatoryOpenShiftDialog(BuildContext context, String userId) async {
    final TextEditingController initialCashController = TextEditingController(text: '0.00');

    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.lock_clock, color: Colors.orange, size: 28),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Apertura de Turno Requerida',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Para realizar cobros o comandas es obligatorio abrir un turno de caja.',
              style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: initialCashController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              decoration: const InputDecoration(
                labelText: 'Fondo Inicial de Caja',
                labelStyle: TextStyle(color: Color(0xFF94A3B8)),
                prefixText: '\$ ',
                prefixStyle: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF475569))),
                focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF38BDF8))),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar', style: TextStyle(color: Color(0xFF94A3B8))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              final initialCash = double.tryParse(initialCashController.text) ?? 0.0;
              try {
                await _shiftService.openShift(userId: userId, initialCash: initialCash);
                if (context.mounted) Navigator.pop(context, true);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error abriendo turno: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: const Text('Abrir Turno', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    ).then((val) => val == true);
  }

  void _sendOrderToKitchen() {
    final activeUser = Supabase.instance.client.auth.currentUser;
    final currentUserId = _selectedWaiterId ?? (activeUser?.id ?? 'waiter-1');
    final currentWaiterName = _selectedWaiterName ?? (activeUser?.email?.split('@').first ?? 'Mesero');

    String tableId = widget.tableId ?? '00000000-0000-4000-8000-000000000020';
    String zoneId = widget.zoneId ?? '11111111-1111-4000-8000-000000000001';

    if (widget.tableId == null) {
      for (final z in _tableService.getZones()) {
        for (final t in _tableService.getTablesByZone(z.id)) {
          final label = 'Mesa #${t.tableNumber} (${z.name})';
          if (label == _selectedTableLabel || _selectedTableLabel.contains('Mesa #${t.tableNumber}')) {
            tableId = t.id;
            zoneId = z.id;
            break;
          }
        }
      }
    }

    final conceptFinal = _conceptController.text.trim().isEmpty
        ? 'Ronda de Consumo'
        : _conceptController.text.trim();

    _tableService.addTicketToTable(
      zoneId,
      tableId,
      amount: _amount,
      concept: conceptFinal,
      waiterId: currentUserId,
      waiterName: currentWaiterName,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.send_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Comanda enviada a preparación (\$${_amount.toStringAsFixed(2)} MXN) en $_selectedTableLabel',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.indigo[800],
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );

    _pendingOrderItems.clear();
    _resetKeypad();
    widget.onPaymentSuccess?.call();
  }

  Future<void> _openPaymentModal() async {
    if (_amount <= 0) return;

    final userId = _selectedWaiterId ?? (Supabase.instance.client.auth.currentUser?.id ?? '');
    final activeShift = await _shiftService.getActiveShift(userId);
    if (!mounted) return;

    if (activeShift == null) {
      final bool opened = await _showMandatoryOpenShiftDialog(context, userId);
      if (!opened || !mounted) return;
    }

    String conceptText = _conceptController.text.trim().isEmpty
        ? 'Consumo mostrador'
        : _conceptController.text.trim();

    if (_notesController.text.trim().isNotEmpty) {
      conceptText = '$conceptText (${_notesController.text.trim()})';
    }

    if (_selectedTableLabel != 'Barra / Mostrador') {
      conceptText = '$_selectedTableLabel - $conceptText';
    }

    if (!mounted) return;

    final currentWaiterName = _selectedWaiterName ??
        (Supabase.instance.client.auth.currentUser?.email?.split('@').first ?? 'Mesero');

    final resultCharge = await PaymentMethodBottomSheet.show(
      context,
      amount: _amount,
      concept: conceptText,
      waiterId: userId,
      waiterName: currentWaiterName,
      chargeService: _chargeService,
    );

    if (resultCharge != null && mounted) {
      final methodDisplay = resultCharge.paymentMethod == 'qr'
          ? 'Ticket QR impreso'
          : resultCharge.paymentMethod == 'tarjeta'
          ? 'Pago con tarjeta registrado'
          : 'Pago en efectivo registrado';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Text('✅ $methodDisplay (\$${resultCharge.amount.toStringAsFixed(2)} MXN)'),
              ),
            ],
          ),
          backgroundColor: Colors.green[700],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );

      if (widget.tableId != null && widget.zoneId != null) {
        try {
          (widget.tableService ?? TableService()).clearAllTableTickets(widget.zoneId!, widget.tableId!);
          widget.onPaymentSuccess?.call();
        } catch (e) {
          debugPrint('⚠️ Error liberando mesa tras pago: $e');
        }
      }

      _resetKeypad();
    }
  }

  String _formatCurrency(double val) {
    return NumberFormat.currency(locale: 'es_MX', symbol: '\$', decimalDigits: 2).format(val);
  }

  @override
  void dispose() {
    _highlightTimer?.cancel();
    _conceptController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeUserEmail = Supabase.instance.client.auth.currentUser?.email;
    final activeUserName = activeUserEmail != null && activeUserEmail.contains('@')
        ? activeUserEmail.split('@').first
        : 'cliente001';

    final List<Map<String, String>> waitersList = [
      {'id': 'waiter-1', 'name': activeUserName},
      {'id': 'waiter-2', 'name': 'Carlos (Mesero 1)'},
      {'id': 'waiter-3', 'name': 'Sofía (Mesero 2)'},
      {'id': 'waiter-4', 'name': 'Ana (Mesero 3)'},
    ];

    final List<String> availableTables = ['Barra / Mostrador'];
    for (final z in _tableService.getZones()) {
      for (final t in _tableService.getTablesByZone(z.id)) {
        availableTables.add('Mesa #${t.tableNumber} (${z.name})');
      }
    }
    if (!availableTables.contains(_selectedTableLabel)) {
      _selectedTableLabel = availableTables.first;
    }

    final List<MenuItemModel> menuItems = _menuService.getMenuItems(activeOnly: true);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        titleSpacing: 16,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF3B3836), Color(0xFF4A4644)],
            ),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 140),
          child: InkWell(
            onTap: () {
              setState(() {
                _isScientificMode = !_isScientificMode;
              });
            },
            borderRadius: BorderRadius.circular(6),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _isScientificMode ? const Color(0xFF1D4ED8) : const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: _isScientificMode ? const Color(0xFF60A5FA) : const Color(0xFF475569),
                  width: 0.8,
                ),
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _isScientificMode ? Icons.restaurant_menu_rounded : Icons.calculate_outlined,
                      size: 14,
                      color: _isScientificMode ? const Color(0xFF38BDF8) : const Color(0xFFF97316),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _isScientificMode ? 'Menú Táctil' : 'Calculadora',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.local_fire_department_rounded,
                      size: 20,
                      color: Color(0xFFF97316),
                    ),
                    const SizedBox(width: 4),
                    RichText(
                      text: const TextSpan(
                        children: [
                          TextSpan(
                            text: 'Oktane ',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16),
                          ),
                          TextSpan(
                            text: 'POS',
                            style: TextStyle(color: Color(0xFF38BDF8), fontWeight: FontWeight.w900, fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ListenableBuilder(
                    listenable: AppLocale.instance,
                    builder: (context, _) {
                      final isEs = AppLocale.instance.currentLang == 'es';
                      return InkWell(
                        onTap: () => AppLocale.instance.toggle(),
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E293B),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFF475569), width: 0.8),
                          ),
                          child: Text(
                            isEs ? '🇲🇽 ES' : '🇺🇸 EN',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFFE2E8F0)),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.settings_outlined, color: Color(0xFFE2E8F0)),
                  tooltip: 'Ajustes',
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.fromLTRB(4, 0, 0, 0),
                  visualDensity: VisualDensity.compact,
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen()));
                  },
                ),
              ],
            ),
          ),
        ],
      ),
      resizeToAvoidBottomInset: false,
      body: OrientationBuilder(
        builder: (context, orientation) {
          final isLandscape = orientation == Orientation.landscape;

          return Stack(
            children: [
              // Fondo de acero cepillado con centro elevado
              Positioned.fill(
                child: Transform.scale(
                  scale: 1.15,
                  child: Transform.translate(
                    offset: const Offset(0, -50),
                    child: Image.asset(
                      'assets/images/faceplates/Gemini_Generated_Image_cpngq2cpngq2cpng.jpg',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(color: const Color(0xFF2D3033));
                      },
                    ),
                  ),
                ),
              ),

              SafeArea(
                child: isLandscape
                    ? _buildLandscapeLayout(context, availableTables, activeUserName, waitersList, menuItems)
                    : _buildPortraitLayout(context, availableTables, activeUserName, waitersList, menuItems),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPortraitLayout(
      BuildContext context,
      List<String> availableTables,
      String activeUserName,
      List<Map<String, String>> waitersList,
      List<MenuItemModel> menuItems,
      ) {
    return Column(
      children: [
        AmountDisplay(
          amount: _amount,
          rawInput: _rawInput,
          expression: _calculatorExpression,
          orderItems: _pendingOrderItems,
          lastModifiedIndex: _lastModifiedIndex,
          onRemoveItem: _removePendingItem,
          onTapTables: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const TablesMapScreen()));
          },
          onTapPrinter: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const PrinterSettingsScreen()));
          },
          onTapHistory: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const ChargesHistoryScreen()));
          },
        ),
        _buildSubStrip(ThemeService.instance),
        _buildControlsCard(ThemeService.instance, availableTables, activeUserName, waitersList, menuItems),

        Expanded(
          child: _isScientificMode
              ? PosKeypad(
            onKeyTap: _handleKeyTap,
            isScientificMode: true,
          )
              : _buildProductSection(menuItems),
        ),
        _buildCobrarButton(ThemeService.instance),
      ],
    );
  }

  Widget _buildControlsCard(
      ThemeService theme,
      List<String> availableTables,
      String activeUserName,
      List<Map<String, String>> waitersList,
      List<MenuItemModel> menuItems,
      ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 3.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedTableLabel,
                  isExpanded: true,
                  icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF0F172A), size: 24),
                  dropdownColor: const Color(0xFFF8FAFC),
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Mesa / Ubicación',
                    labelStyle: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0F172A),
                    ),
                    floatingLabelBehavior: FloatingLabelBehavior.always,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.08),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFF0F172A), width: 1.3),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFF0F172A), width: 1.3),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFF0F172A), width: 1.6),
                    ),
                  ),
                  items: availableTables.map((t) {
                    return DropdownMenuItem(
                      value: t,
                      child: Text(t, overflow: TextOverflow.ellipsis),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedTableLabel = val);
                  },
                ),
              ),
              const SizedBox(width: 8),

              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedWaiterName ?? activeUserName,
                  isExpanded: true,
                  icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF0F172A), size: 24),
                  dropdownColor: const Color(0xFFF8FAFC),
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Mesero / Atención',
                    labelStyle: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0F172A),
                    ),
                    floatingLabelBehavior: FloatingLabelBehavior.always,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.08),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFF0F172A), width: 1.3),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFF0F172A), width: 1.3),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFF0F172A), width: 1.6),
                    ),
                  ),
                  items: waitersList.map((w) {
                    return DropdownMenuItem<String>(
                      value: w['name'],
                      child: Text(w['name']!, overflow: TextOverflow.ellipsis),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      final selected = waitersList.firstWhere((w) => w['name'] == val);
                      _onWaiterChanged(selected['name']!, selected['id']!);
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          SizedBox(
            width: double.infinity,
            height: 38,
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF3B67B5),
                    Color(0xFF2C5094),
                    Color(0xFF213F7B),
                  ],
                ),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF0F172A), width: 1.3),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x33000000),
                    offset: Offset(0, 2),
                    blurRadius: 2,
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _navigateToTableOrderDetail,
                  borderRadius: BorderRadius.circular(10),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.assignment_outlined, size: 18, color: Colors.white),
                      SizedBox(width: 8),
                      Icon(Icons.delete_outline_rounded, size: 18, color: Colors.white),
                      SizedBox(width: 10),
                      FittedBox(
                        child: Text(
                          'TOMAR PEDIDO COMPLETO / VER MESA',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.6,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),

          Autocomplete<MenuItemModel>(
            optionsBuilder: (TextEditingValue textEditingValue) {
              final query = textEditingValue.text.trim();
              if (query.isEmpty) {
                return const Iterable<MenuItemModel>.empty();
              }
              return menuItems.where((item) {
                return item.name.toLowerCase().contains(query.toLowerCase());
              });
            },
            displayStringForOption: (option) => option.name,
            onSelected: (option) {
              _onMenuItemSelected(option);
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _menuSearchController?.clear();
                FocusScope.of(context).unfocus();
              });
            },
            optionsViewBuilder: (context, onSelected, options) {
              final query = _menuSearchController?.text.trim() ?? '';
              if (query.isEmpty || options.isEmpty) {
                return const SizedBox.shrink();
              }
              return Align(
                alignment: Alignment.topLeft,
                child: Material(
                  elevation: 8,
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.white,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: 180,
                      maxWidth: MediaQuery.of(context).size.width - 28,
                    ),
                    child: ListView.builder(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      itemCount: options.length,
                      itemBuilder: (context, index) {
                        final option = options.elementAt(index);
                        return ListTile(
                          dense: true,
                          visualDensity: VisualDensity.compact,
                          title: Text(
                            option.name,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                          ),
                          trailing: Text(
                            '\$${option.price.toStringAsFixed(2)}',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF2563EB)),
                          ),
                          onTap: () => onSelected(option),
                        );
                      },
                    ),
                  ),
                ),
              );
            },
            fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
              _menuSearchController = controller;
              return SizedBox(
                height: 40,
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Buscar producto en menú (ej. Tacos, ...)',
                    hintStyle: TextStyle(
                      color: const Color(0xFF0F172A).withOpacity(0.65),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    prefixIcon: const Icon(
                      Icons.search,
                      size: 20,
                      color: Color(0xFF334155),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFF0F172A), width: 1.3),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFF0F172A), width: 1.3),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFF0F172A), width: 1.6),
                    ),
                    suffixIcon: controller.text.isNotEmpty
                        ? InkWell(
                      onTap: () {
                        controller.clear();
                        FocusScope.of(context).unfocus();
                        setState(() {});
                      },
                      child: const Icon(Icons.clear, size: 16, color: Colors.black54),
                    )
                        : null,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // SECCIÓN DE PRODUCTOS: ALINEACIÓN MILIMÉTRICA + TECLAS DERECHAS IDÉNTICAS A LA CALCULADORA
  Widget _buildProductSection(List<MenuItemModel> menuItems) {
    final filteredItems = _selectedCategory == 'Todos'
        ? menuItems
        : menuItems.where((m) {
      final cat = m.category.toLowerCase();
      final name = m.name.toLowerCase();
      final sel = _selectedCategory.toLowerCase();
      if (sel == 'bebidas') {
        return cat.contains('beb') || name.contains('café') || name.contains('cerveza') || name.contains('refresco') || name.contains('agua');
      } else if (sel == 'alimentos') {
        return cat.contains('alim') || cat.contains('comid') || name.contains('taco') || name.contains('hamburguesa') || name.contains('pizza');
      } else if (sel == 'postres') {
        return cat.contains('postre') || name.contains('pastel') || name.contains('flan') || name.contains('helado') || name.contains('dulce');
      } else if (sel == 'otros') {
        final isKnown = name.contains('café') || name.contains('cerveza') || name.contains('refresco') || name.contains('taco') || name.contains('hamburguesa') || name.contains('pizza') || name.contains('pastel') || name.contains('flan');
        return !isKnown && !cat.contains('beb') && !cat.contains('alim') && !cat.contains('postre');
      }
      return cat == sel;
    }).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 1.0),
      child: Column(
        children: [
          // 1. Cuadrícula y Teclas Laterales sincronizadas
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _buildProductGrid(filteredItems),
                ),
                const SizedBox(width: 5),

                // Columna derecha con las 3 teclas con el MISMO ESTILO EXACTO de la calculadora
                SizedBox(
                  width: 52,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ⌫ Alineado exactamente con la Fila 1
                      Expanded(
                        child: _buildThinKeyButton(
                          child: const Icon(
                            Icons.backspace_outlined,
                            size: 22,
                            color: Color(0xFF0F172A),
                          ),
                          onTap: _removeLastInsertion,
                        ),
                      ),
                      const SizedBox(height: 5),

                      // C Alineado exactamente con la Fila 2
                      Expanded(
                        child: _buildThinKeyButton(
                          child: const Text(
                            'C',
                            style: TextStyle(
                              color: Color(0xFFDC2626),
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          onTap: _resetKeypad,
                        ),
                      ),
                      const SizedBox(height: 5),

                      // ↵ Alineado exactamente con la Fila 3 (Verde salvia translúcido)
                      Expanded(
                        child: _buildThinKeyButton(
                          isEnter: true,
                          child: const Icon(
                            Icons.keyboard_return_rounded,
                            size: 26,
                            color: Color(0xFF142412),
                          ),
                          onTap: _openScientificWithAns,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),

          // 2. Barra de Categorías a ANCHO COMPLETO
          _buildCategoryFilterBar(),
        ],
      ),
    );
  }

  Widget _buildCategoryFilterBar() {
    return SizedBox(
      height: 36,
      child: Row(
        children: _categories.map((cat) {
          final isSelected = _selectedCategory == cat;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 1.5),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  setState(() {
                    _selectedCategory = cat;
                  });
                },
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                    )
                        : const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFFF1F5F9), Color(0xFFCBD5E1)],
                    ),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isSelected ? const Color(0xFF93C5FD) : const Color(0xFF8492A6),
                      width: isSelected ? 1.2 : 0.8,
                    ),
                    boxShadow: const [
                      BoxShadow(color: Color(0x33000000), offset: Offset(0, 1.5), blurRadius: 1.5),
                    ],
                  ),
                  child: Text(
                    cat,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                      color: isSelected ? Colors.white : const Color(0xFF1E293B),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // BOTÓN IDÉNTICO AL DISEÑO DE TECLAS DE LA CALCULADORA CIENTÍFICA
  Widget _buildThinKeyButton({
    required Widget child,
    required VoidCallback onTap,
    bool isEnter = false,
  }) {
    // Exactamente el mismo gradiente transparente biselado de pos_keypad.dart
    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: isEnter
          ? [
        const Color(0xFFB5C4AF).withOpacity(0.55), // Tinte verde salvia translúcido
        const Color(0xFF8DA387).withOpacity(0.20),
        const Color(0xFF5E7358).withOpacity(0.35),
      ]
          : [
        Colors.white.withOpacity(0.55), // Reflejo de luz superior izquierda
        Colors.white.withOpacity(0.06), // Cuerpo transparente translúcido
        Colors.black.withOpacity(0.22), // Sombra de bisel inferior derecha
      ],
      stops: const [0.0, 0.35, 1.0],
    );

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(7),
          border: Border.all(
            color: isEnter
                ? const Color(0xFF5E7358).withOpacity(0.60)
                : Colors.black.withOpacity(0.28),
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.20),
              offset: const Offset(1.5, 2.0),
              blurRadius: 2.5,
            ),
          ],
        ),
        child: Center(child: child),
      ),
    );
  }

  Widget _buildProductGrid(List<MenuItemModel> items) {
    if (items.isEmpty) {
      return Center(
        child: Text(
          tr('menu_empty'),
          style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 11),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        const crossAxisCount = 3;
        const spacing = 5.0;

        final totalHeight = constraints.maxHeight;
        final rowHeight = (totalHeight - (spacing * 2)) / 3;
        final colWidth = (constraints.maxWidth - (spacing * 2)) / crossAxisCount;
        final calculatedAspectRatio = colWidth / rowHeight;

        return GridView.builder(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.zero,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: calculatedAspectRatio.clamp(0.5, 3.0),
            crossAxisSpacing: spacing,
            mainAxisSpacing: spacing,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            final existing = _pendingOrderItems.firstWhere(
                  (it) => it['id'] == item.id,
              orElse: () => {},
            );
            final currentQty = existing.isNotEmpty ? (existing['quantity'] as num).toInt() : 0;

            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _onProductQuickTapped(item),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: currentQty > 0
                        ? const [Color(0xFFE2F0D9), Color(0xFFC4E0B2)]
                        : const [Color(0xFFF8FAFC), Color(0xFFCBD5E1)],
                  ),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: currentQty > 0 ? const Color(0xFF548235) : const Color(0xFF8492A6),
                    width: currentQty > 0 ? 1.4 : 1.0,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x33000000),
                      offset: Offset(0, 1.8),
                      blurRadius: 1.5,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (currentQty > 0)
                          Container(
                            margin: const EdgeInsets.only(right: 3),
                            padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2E7D32),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '${currentQty}x',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        Flexible(
                          child: Text(
                            item.name,
                            style: TextStyle(
                              color: currentQty > 0 ? const Color(0xFF1E391A) : const Color(0xFF0F172A),
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                            ),
                            maxLines: 2,
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '\$${item.price.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: currentQty > 0 ? const Color(0xFF2E7D32) : const Color(0xFF1E40AF),
                        fontSize: 9.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildLandscapeLayout(
      BuildContext context,
      List<String> availableTables,
      String activeUserName,
      List<Map<String, String>> waitersList,
      List<MenuItemModel> menuItems,
      ) {
    return Column(
      children: [
        Expanded(
          child: Row(
            children: [
              Expanded(
                flex: 5,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      AmountDisplay(
                        amount: _amount,
                        rawInput: _rawInput,
                        expression: _calculatorExpression,
                        orderItems: _pendingOrderItems,
                        lastModifiedIndex: _lastModifiedIndex,
                        onRemoveItem: _removePendingItem,
                        onTapTables: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => const TablesMapScreen()));
                        },
                        onTapPrinter: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => const PrinterSettingsScreen()));
                        },
                        onTapHistory: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => const ChargesHistoryScreen()));
                        },
                      ),
                      _buildSubStrip(ThemeService.instance),
                      _buildControlsCard(ThemeService.instance, availableTables, activeUserName, waitersList, menuItems),
                    ],
                  ),
                ),
              ),
              Expanded(
                flex: 5,
                child: _isScientificMode
                    ? PosKeypad(
                  onKeyTap: _handleKeyTap,
                  isScientificMode: true,
                )
                    : _buildProductSection(menuItems),
              ),
            ],
          ),
        ),
        _buildCobrarButton(ThemeService.instance),
      ],
    );
  }

  Widget _buildSubStrip(ThemeService theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 1.5),
      child: SizedBox(
        width: double.infinity,
        height: 32,
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFD97706), Color(0xFFC2410C), Color(0xFF9A3412)],
              stops: [0.0, 0.5, 1.0],
            ),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: const Color(0xFFFDBA74), width: 0.8),
            boxShadow: const [
              BoxShadow(color: Color(0x33000000), offset: Offset(0, 1.5), blurRadius: 2),
            ],
          ),
          child: ElevatedButton.icon(
            onPressed: _amount > 0
                ? () {
              if (_pendingOrderItems.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Selecciona al menos un platillo o bebida del menú.'),
                    backgroundColor: Colors.orange,
                    duration: Duration(seconds: 2),
                  ),
                );
                return;
              }
              _sendOrderToKitchen();
            }
                : null,
            icon: const Icon(Icons.send_rounded, size: 14, color: Colors.white),
            label: const FittedBox(
              child: Text(
                'MANDAR A PREPARACIÓN',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 0.5, color: Colors.white),
              ),
            ),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              backgroundColor: Colors.transparent,
              disabledBackgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCobrarButton(ThemeService theme) {
    final bool isReadyToCharge = _amount > 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 4.0),
      child: Container(
        padding: const EdgeInsets.all(3.0),
        decoration: BoxDecoration(
          color: const Color(0xFF1E2226),
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(color: Color(0x99000000), offset: Offset(0, 3), blurRadius: 4),
            BoxShadow(color: Color(0x66FFFFFF), offset: Offset(0, -1), blurRadius: 1),
          ],
        ),
        child: isReadyToCharge
            ? TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0.35, end: 0.85),
          duration: const Duration(milliseconds: 1000),
          builder: (context, animatedGlow, child) {
            return Container(
              width: double.infinity,
              height: 48,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF8CE680),
                    Color(0xFF5BCE50),
                  ],
                ),
                borderRadius: BorderRadius.circular(13),
                border: Border.all(
                  color: const Color(0xFF388E3C),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF5BCE50).withOpacity(animatedGlow),
                    blurRadius: 12 * animatedGlow,
                    spreadRadius: 2 * animatedGlow,
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: _openPaymentModal,
                icon: const Icon(Icons.shopping_cart_checkout_rounded, size: 20, color: Color(0xFF092606)),
                label: FittedBox(
                  child: Text(
                    'COBRAR ${_formatCurrency(_amount)}',
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                      color: Color(0xFF092606),
                    ),
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  disabledBackgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
                ),
              ),
            );
          },
        )
            : Container(
          width: double.infinity,
          height: 48,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF4A5647),
                Color(0xFF3B4438),
              ],
            ),
            borderRadius: BorderRadius.circular(13),
            border: Border.all(
              color: const Color(0xFF2A3328),
              width: 1.5,
            ),
          ),
          child: ElevatedButton.icon(
            onPressed: null,
            icon: const Icon(Icons.shopping_cart_checkout_rounded, size: 20, color: Color(0x66152013)),
            label: FittedBox(
              child: Text(
                'COBRAR \$0.00',
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                  color: Color(0x66152013),
                ),
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              disabledBackgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
            ),
          ),
        ),
      ),
    );
  }
}
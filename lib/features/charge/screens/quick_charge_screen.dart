import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:oktane_pos/providers/auth_provider.dart';
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
import 'package:oktane_pos/core/services/currency_service.dart';
import '../../tables/screens/tables_map_screen.dart';
import '../../tables/services/table_service.dart';
import 'package:oktane_pos/features/tables/models/zone_model.dart';
import 'package:oktane_pos/features/tables/models/table_model.dart';
import 'package:oktane_pos/features/tables/screens/table_order_detail_screen.dart';
import '../../auth/services/rbac_service.dart';
import '../../menu/models/menu_item_model.dart';
import '../../menu/services/menu_service.dart';
import '../../settings/screens/settings_screen.dart';

class QuickChargeScreen extends StatefulWidget {
  final double? initialAmount;
  final String? initialConcept;
  final String? tableId;
  final String? zoneId;
  final TableService? tableService;
  final VoidCallback? onPaymentSuccess;

  const QuickChargeScreen({
    super.key,
    this.initialAmount,
    this.initialConcept,
    this.tableId,
    this.zoneId,
    this.tableService,
    this.onPaymentSuccess,
  });

  @override
  State<QuickChargeScreen> createState() => _QuickChargeScreenState();
}

class _QuickChargeScreenState extends State<QuickChargeScreen> {
  final ChargeService _chargeService = ChargeService();
  final ShiftService _shiftService = ShiftService();
  final RbacService _rbacService = RbacService();
  final MenuService _menuService = MenuService();
  late final TableService _tableService;

  final TextEditingController _conceptController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  TextEditingController? _menuSearchController;
  final List<Map<String, dynamic>> _pendingOrderItems = [];

  String _rawInput = '0';
  String _selectedTableLabel = 'Barra / Mostrador';
  String? _selectedWaiterName;
  String? _selectedWaiterId;

  @override
  void initState() {
    super.initState();
    _tableService = widget.tableService ?? TableService();

    if (widget.initialAmount != null && widget.initialAmount! > 0) {
      _rawInput = widget.initialAmount!.toStringAsFixed(2);
    }
    if (widget.initialConcept != null && widget.initialConcept!.isNotEmpty) {
      _conceptController.text = widget.initialConcept!;
    }

    // Postpone background tasks until AFTER the first frame renders
    WidgetsBinding.instance.addPostFrameCallback((_) {
      CurrencyService.instance.updateRateInBackground();
    });
  }

  bool _isScientificMode = false;
  String _calculatorExpression = '';

  double get _amount => double.tryParse(_rawInput) ?? 0.0;

  void _handleKeyTap(String key) {
    setState(() {
      if (key == 'CLEAR' || key == 'CA') {
        _rawInput = '0';
        _calculatorExpression = '';
        _pendingOrderItems.clear();
        _conceptController.clear();
      } else if (key == 'BACKSPACE' || key == 'DEL') {
        if (_rawInput.length > 1) {
          _rawInput = _rawInput.substring(0, _rawInput.length - 1);
        } else {
          _rawInput = '0';
        }
        if (_calculatorExpression.isNotEmpty) {
          _calculatorExpression = _calculatorExpression.substring(0, _calculatorExpression.length - 1);
        }
      } else if (key == '+' || key == '-' || key == '×' || key == '÷') {
        _calculatorExpression = '$_rawInput $key ';
        _rawInput = '0';
      } else if (key == '=') {
        if (_calculatorExpression.isNotEmpty) {
          final parts = _calculatorExpression.trim().split(' ');
          if (parts.length >= 2) {
            final op1 = double.tryParse(parts[0]) ?? 0.0;
            final operator = parts[1];
            final op2 = double.tryParse(_rawInput) ?? 0.0;
            double result = 0.0;
            if (operator == '+') result = op1 + op2;
            if (operator == '-') result = op1 - op2;
            if (operator == '×') result = op1 * op2;
            if (operator == '÷') result = op2 != 0 ? op1 / op2 : 0.0;

            _calculatorExpression = '$op1 $operator $op2 =';
            _rawInput = result.toStringAsFixed(2);
          }
        }
      } else if (key == 'Ans') {
        _rawInput = _amount.toStringAsFixed(2);
      } else if (key == '×10') {
        final val = _amount * 10;
        _rawInput = val.toStringAsFixed(2);
      } else if (key == '.') {
        if (!_rawInput.contains('.')) {
          _rawInput = '$_rawInput.';
        }
      } else if (key == '00') {
        if (_rawInput != '0') {
          if (_rawInput.contains('.')) {
            final parts = _rawInput.split('.');
            if (parts[1].isEmpty) {
              _rawInput = '${_rawInput}00';
            } else if (parts[1].length == 1) {
              _rawInput = '${_rawInput}0';
            }
          } else {
            _rawInput = '${_rawInput}00';
          }
        }
      } else {
        // Digits 0-9
        if (_rawInput == '0') {
          _rawInput = key;
        } else if (_rawInput.contains('.')) {
          final parts = _rawInput.split('.');
          if (parts[1].length < 2) {
            _rawInput = '$_rawInput$key';
          }
        } else {
          _rawInput = '$_rawInput$key';
        }
      }
    });
  }

  void _recalculatePendingItemsTotal() {
    double total = 0.0;
    final List<String> concepts = [];
    for (final item in _pendingOrderItems) {
      final sub = (item['subtotal'] as num?)?.toDouble() ?? 0.0;
      total += sub;
      final name = item['name']?.toString() ?? 'Producto';
      final qty = (item['quantity'] as num?)?.toInt() ?? 1;
      final isTakeaway = item['is_takeaway'] == true;
      final notes = item['notes']?.toString() ?? '';

      final qtyPrefix = qty > 1 ? '${qty}x ' : '';
      final takeawayTag = isTakeaway ? ' [Para llevar]' : '';
      final notesTag = notes.isNotEmpty ? ' ($notes)' : '';
      concepts.add('$qtyPrefix$name$takeawayTag$notesTag');
    }

    setState(() {
      _rawInput = total > 0 ? total.toStringAsFixed(2) : '0';
      if (concepts.isNotEmpty) {
        _conceptController.text = concepts.join(' + ');
      } else {
        _conceptController.clear();
      }
    });
  }

  Future<void> _editPendingItem(int index) async {
    final item = _pendingOrderItems[index];
    final menuItem = MenuItemModel(
      id: item['item_id']?.toString() ?? 'm-temp',
      name: item['name']?.toString() ?? 'Producto',
      price: (item['price'] as num?)?.toDouble() ?? 0.0,
    );
    final updated = await ItemPreAddDialog.show(context, menuItem: menuItem);
    if (updated != null && mounted) {
      setState(() {
        _pendingOrderItems[index] = updated;
      });
      _recalculatePendingItemsTotal();
    }
  }

  void _removePendingItem(int index) {
    setState(() {
      _pendingOrderItems.removeAt(index);
    });
    _recalculatePendingItemsTotal();
  }

  Future<void> _onMenuItemSelected(MenuItemModel item) async {
    final resultItem = await ItemPreAddDialog.show(context, menuItem: item);
    if (resultItem == null || !mounted) return;

    final String itemName = resultItem['name']?.toString() ?? item.name;
    final int itemQty = (resultItem['quantity'] as num?)?.toInt() ?? 1;
    final double subtotal = (resultItem['subtotal'] as num?)?.toDouble() ?? 0.0;

    setState(() {
      _pendingOrderItems.add(resultItem);
    });
    _recalculatePendingItemsTotal();

    // Auto-clear autocomplete search bar and unfocus keyboard
    _menuSearchController?.clear();
    FocusScope.of(context).unfocus();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('➕ ${itemQty}x $itemName (+\$${subtotal.toStringAsFixed(2)}) agregado a la orden'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _navigateToTableOrderDetail() async {
    final zones = _tableService.getZones();
    ZoneModel targetZone;
    RestaurantTableModel targetTable;

    if (_selectedTableLabel == 'Barra / Mostrador') {
      targetZone = zones.firstWhere((z) => z.id == 'zone-barra', orElse: () => zones.first);
      final barraTables = _tableService.getTablesByZone(targetZone.id);
      targetTable = barraTables.firstWhere(
        (t) => t.status == 'occupied',
        orElse: () => barraTables.firstWhere((t) => t.status == 'free', orElse: () => _tableService.getTablesByZone(zones.first.id).first),
      );
    } else {
      final tableNum = int.tryParse(_selectedTableLabel.replaceAll(RegExp(r'[^0-9]'), '')) ?? 1;
      targetZone = zones.first;
      RestaurantTableModel? found;
      for (final z in zones) {
        final tables = _tableService.getTablesByZone(z.id);
        for (final t in tables) {
          if (t.tableNumber == tableNum) {
            targetZone = z;
            found = t;
            break;
          }
        }
        if (found != null) break;
      }
      targetTable = found ?? _tableService.getTablesByZone(zones.first.id).first;
    }

    if (_pendingOrderItems.isNotEmpty) {
      _tableService.saveTableDraft(targetTable.id, _pendingOrderItems);
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TableOrderDetailScreen(
          zone: targetZone,
          table: targetTable,
          tableService: _tableService,
          onTableUpdated: () {
            if (mounted) setState(() {});
          },
        ),
      ),
    );

    if (mounted) {
      final remainingDraft = _tableService.getTableDraft(targetTable.id);
      if (remainingDraft.isEmpty) {
        setState(() {
          _pendingOrderItems.clear();
          _rawInput = '0';
          _conceptController.clear();
        });
      } else {
        setState(() {
          _pendingOrderItems.clear();
          _pendingOrderItems.addAll(remainingDraft);
        });
      }
    }
  }

  Future<void> _onWaiterChanged(String newName, String newId) async {
    final activeUserId = Supabase.instance.client.auth.currentUser?.id ?? '';
    final activeUserEmail = Supabase.instance.client.auth.currentUser?.email?.split('@').first ?? 'Mesero';

    if (newId == (_selectedWaiterId ?? activeUserId)) {
      setState(() {
        _selectedWaiterName = newName;
        _selectedWaiterId = newId;
      });
      return;
    }

    final pinCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final bool? valid = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.person_pin, color: Colors.indigo),
            const SizedBox(width: 8),
            Flexible(child: Text('PIN de $newName', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
          ],
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Ingrese el PIN para transferir la venta de $activeUserEmail a $newName.'),
              const SizedBox(height: 12),
              TextFormField(
                controller: pinCtrl,
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 4,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'PIN de Mesero',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => (v == null || v.trim().length < 4) ? '4 dígitos requeridos' : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              final isValid = await _rbacService.verifyWaiterPin(pinCtrl.text.trim());
              if (ctx.mounted) {
                Navigator.pop(ctx, isValid);
              }
            },
            child: const Text('Confirmar Transferencia'),
          ),
        ],
      ),
    );

    if (valid == true && mounted) {
      setState(() {
        _selectedWaiterName = newName;
        _selectedWaiterId = newId;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✅ Venta transferida a $newName'), backgroundColor: Colors.green[700]),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ Transferencia cancelada: PIN incorrecto'), backgroundColor: Colors.red),
      );
    }
  }

  void _resetKeypad() {
    setState(() {
      _rawInput = '0';
      _conceptController.clear();
      _notesController.clear();
      _pendingOrderItems.clear();
    });
  }

  Future<bool> _showMandatoryOpenShiftDialog(BuildContext ctx, String userId) {
    final initialCashController = TextEditingController(text: '500.00');
    final formKey = GlobalKey<FormState>();
    bool isOpening = false;

    return showDialog<bool>(
      context: ctx,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.lock_open, color: Colors.indigo),
              SizedBox(width: 8),
              Text('Apertura de Turno', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'No hay un turno de caja abierto. Inicie turno para comenzar a cobrar.',
                  style: TextStyle(fontSize: 13, color: Colors.black87),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: initialCashController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Fondo Inicial de Caja (Cambio)',
                    prefixText: '\$ ',
                    suffixText: 'MXN',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Requerido';
                    if (double.tryParse(v.trim()) == null) return 'Monto inválido';
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isOpening ? null : () => Navigator.pop(ctx, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: isOpening
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setModalState(() => isOpening = true);
                      final initialCash = double.tryParse(initialCashController.text.trim()) ?? 0.0;
                      try {
                        await _shiftService.openShift(userId: userId, initialCash: initialCash);
                        if (context.mounted) {
                          Navigator.pop(ctx, true);
                        }
                      } catch (e) {
                        setModalState(() => isOpening = false);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error al abrir turno: $e'), backgroundColor: Colors.red),
                          );
                        }
                      }
                    },
              child: isOpening
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('INICIAR TURNO'),
            ),
          ],
        ),
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

    final resultCharge = await PaymentMethodBottomSheet.show(
      context,
      amount: _amount,
      concept: conceptText,
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

      // Liberar mesa si fue originado de una mesa
      if (widget.tableId != null && widget.zoneId != null) {
        try {
          (widget.tableService ?? TableService()).clearAllTableTickets(widget.zoneId!, widget.tableId!);
          widget.onPaymentSuccess?.call();
        } catch (e) {
          debugPrint('⚠️ Error liberando mesa tras pago: $e');
        }
      }

      // Reset keypad back to $0.00 immediately
      _resetKeypad();
    }
  }

  String _formatAmount(double val) {
    return NumberFormat.currency(locale: 'es_MX', symbol: '\$', decimalDigits: 2).format(val);
  }

  String _formatCurrency(double val) {
    return NumberFormat.currency(locale: 'es_MX', symbol: '\$', decimalDigits: 2).format(val);
  }

  @override
  void dispose() {
    _conceptController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final menuItems = _menuService.getMenuItems(activeOnly: true);

    final activeUser = Supabase.instance.client.auth.currentUser;
    final activeUserName = activeUser?.email?.split('@').first ?? 'Mesero Activo';

    final waitersList = [
      {'id': activeUser?.id ?? 'waiter-1', 'name': activeUserName},
      {'id': 'waiter-2', 'name': 'Carlos (Mesero 1)'},
      {'id': 'waiter-3', 'name': 'Ana (Mesero 2)'},
      {'id': 'waiter-4', 'name': 'Sofía (Mesero 3)'},
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

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        titleSpacing: 8,
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
          constraints: const BoxConstraints(maxWidth: 135),
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
                      _isScientificMode ? Icons.bolt_rounded : Icons.calculate_outlined,
                      size: 14,
                      color: _isScientificMode ? const Color(0xFF38BDF8) : const Color(0xFFF97316),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _isScientificMode ? 'Cobro Rápido' : 'Calculadora',
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
          Row(
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
                padding: const EdgeInsets.fromLTRB(4, 0, 12, 0),
                visualDensity: VisualDensity.compact,
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen()));
                },
              ),
            ],
          ),
        ],
      ),
      resizeToAvoidBottomInset: false,
      body: OrientationBuilder(
        builder: (context, orientation) {
          final isLandscape = orientation == Orientation.landscape;

          return Stack(
            children: [
              // Base Layer: Pre-rendered Photorealistic 3D Faceplate Image (Radial Brushed Aluminium)
              Positioned.fill(
                child: Image.asset(
                  'assets/images/faceplates/Gemini_Generated_Image_cpngq2cpngq2cpng.jpg',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    debugPrint('🔴 ERROR CARGANDO ASSET RADIAL: $error');
                    return Container(
                      color: Colors.red,
                      child: Center(
                        child: Text('Error: $error', style: const TextStyle(color: Colors.white)),
                      ),
                    );
                  },
                ),
              ),

              // Foreground Interactive Widgets Floating Exactly Over 3D Sockets
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
          child: PosKeypad(
            onKeyTap: _handleKeyTap,
            isScientificMode: _isScientificMode,
          ),
        ),
        _buildCobrarButton(ThemeService.instance),
      ],
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
                flex: 6,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      AmountDisplay(
                        amount: _amount,
                        rawInput: _rawInput,
                        expression: _calculatorExpression,
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
                child: PosKeypad(
                  onKeyTap: _handleKeyTap,
                  isScientificMode: _isScientificMode,
                ),
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
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: Container(
        width: double.infinity,
        height: 44,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFD97706), Color(0xFFC2410C), Color(0xFF9A3412)],
            stops: [0.0, 0.5, 1.0],
          ),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFFDBA74), width: 1.0),
          boxShadow: const [
            BoxShadow(color: Color(0x40000000), offset: Offset(0, 2.5), blurRadius: 3),
            BoxShadow(color: Color(0x66FFFFFF), offset: Offset(0, -1), blurRadius: 1),
          ],
        ),
        child: ElevatedButton.icon(
          onPressed: _amount > 0
              ? () {
                  if (_pendingOrderItems.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Para mandar a preparación selecciona al menos un platillo o bebida del menú.'),
                        backgroundColor: Colors.orange,
                        duration: Duration(seconds: 3),
                      ),
                    );
                    return;
                  }
                  _sendOrderToKitchen();
                }
              : null,
          icon: const Icon(Icons.send_rounded, size: 18, color: Colors.white),
          label: const FittedBox(
            child: Text(
              'MANDAR A PREPARACIÓN',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.5, color: Colors.white),
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            disabledBackgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ),
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
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 2.0),
      child: Card(
        elevation: 0,
        color: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0x1AFFFFFF),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF64748B), width: 1.1),
                        boxShadow: const [
                          BoxShadow(color: Color(0x22000000), offset: Offset(0, 1.5), blurRadius: 1.5),
                          BoxShadow(color: Color(0x66FFFFFF), offset: Offset(0, -1), blurRadius: 0.5),
                        ],
                      ),
                      child: DropdownButtonFormField<String>(
                        initialValue: _selectedTableLabel,
                        isExpanded: true,
                        dropdownColor: const Color(0xFFF8FAFC),
                        iconEnabledColor: const Color(0xFF0F172A),
                        style: const TextStyle(color: Color(0xFF0F172A), fontSize: 13, fontWeight: FontWeight.w800),
                        decoration: InputDecoration(
                          labelText: tr('table_location'),
                          labelStyle: const TextStyle(color: Color(0xFF0F172A), fontSize: 11, fontWeight: FontWeight.bold),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          filled: false,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        ),
                        items: availableTables.map((t) => DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(color: Color(0xFF0F172A), fontSize: 13, fontWeight: FontWeight.w800)))).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedTableLabel = val);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0x1AFFFFFF),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF64748B), width: 1.1),
                        boxShadow: const [
                          BoxShadow(color: Color(0x22000000), offset: Offset(0, 1.5), blurRadius: 1.5),
                          BoxShadow(color: Color(0x66FFFFFF), offset: Offset(0, -1), blurRadius: 0.5),
                        ],
                      ),
                      child: DropdownButtonFormField<String>(
                        initialValue: _selectedWaiterName ?? activeUserName,
                        isExpanded: true,
                        dropdownColor: const Color(0xFFF8FAFC),
                        iconEnabledColor: const Color(0xFF0F172A),
                        style: const TextStyle(color: Color(0xFF0F172A), fontSize: 13, fontWeight: FontWeight.w800),
                        decoration: InputDecoration(
                          labelText: tr('waiter_service'),
                          labelStyle: const TextStyle(color: Color(0xFF0F172A), fontSize: 11, fontWeight: FontWeight.bold),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          filled: false,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        ),
                        items: waitersList.map((w) {
                          return DropdownMenuItem<String>(
                            value: w['name'],
                            child: Text(w['name']!, style: const TextStyle(color: Color(0xFF0F172A), fontSize: 13, fontWeight: FontWeight.w800), overflow: TextOverflow.ellipsis),
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
                  ),
                ],
              ),
              const SizedBox(height: 6),

              SizedBox(
                width: double.infinity,
                height: 40,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFF2563EB), Color(0xFF1D4ED8), Color(0xFF1E3A8A)],
                      stops: [0.0, 0.5, 1.0],
                    ),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF93C5FD), width: 1.0),
                    boxShadow: const [
                      BoxShadow(color: Color(0x40000000), offset: Offset(0, 2.5), blurRadius: 3),
                      BoxShadow(color: Color(0x4DFFFFFF), offset: Offset(0, -1), blurRadius: 1),
                    ],
                  ),
                  child: ElevatedButton.icon(
                    onPressed: _navigateToTableOrderDetail,
                    icon: const Icon(Icons.assignment_outlined, size: 18, color: Colors.white),
                    label: Text(
                      '📋 ${tr('view_table')}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      disabledBackgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),

              Autocomplete<MenuItemModel>(
                optionsBuilder: (TextEditingValue textEditingValue) {
                  if (textEditingValue.text.isEmpty) {
                    return const Iterable<MenuItemModel>.empty();
                  }
                  return menuItems.where((item) {
                    return item.name.toLowerCase().contains(textEditingValue.text.toLowerCase());
                  });
                },
                displayStringForOption: (option) => option.name,
                onSelected: _onMenuItemSelected,
                fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
                  _menuSearchController = controller;
                  return TextField(
                    controller: controller,
                    focusNode: focusNode,
                    style: const TextStyle(color: TableTheme.textPrimary, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: '🔍 ${tr('search_menu')}',
                      hintStyle: const TextStyle(color: TableTheme.textMuted, fontSize: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      enabledBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(8)), borderSide: BorderSide(color: TableTheme.borderStrong)),
                      focusedBorder: OutlineInputBorder(borderRadius: const BorderRadius.all(Radius.circular(8)), borderSide: BorderSide(color: theme.accentAction, width: 1.5)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      filled: true,
                      fillColor: const Color(0xFFF1F5F9),
                    ),
                  );
                },
              ),

              if (_pendingOrderItems.isNotEmpty) ...[
                const SizedBox(height: 6),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 140),
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      children: _pendingOrderItems.asMap().entries.map((entry) {
                        final index = entry.key;
                        final item = entry.value;
                        final name = item['name']?.toString() ?? 'Producto';
                        final price = (item['price'] as num?)?.toDouble() ?? 0.0;
                        final qty = (item['quantity'] as num?)?.toInt() ?? 1;
                        final subtotal = (item['subtotal'] as num?)?.toDouble() ?? 0.0;
                        final isTakeaway = item['is_takeaway'] == true;
                        final notes = item['notes']?.toString() ?? '';

                        return Card(
                          margin: const EdgeInsets.only(top: 4),
                          elevation: 2,
                          color: const Color(0xFFF8FAFC),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: const BorderSide(color: Color(0xFFCBD5E1)),
                          ),
                          child: ListTile(
                            dense: true,
                            onTap: () => _editPendingItem(index),
                            leading: const Icon(Icons.edit_note, color: Color(0xFF2563EB), size: 22),
                            title: Text('${qty}x $name', style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 13)),
                            subtitle: Wrap(
                              spacing: 4,
                              runSpacing: 2,
                              children: [
                                Text('\$$price c/u', style: const TextStyle(color: Color(0xFF475569), fontSize: 11, fontWeight: FontWeight.w600)),
                                if (notes.isNotEmpty) Text('• $notes', style: const TextStyle(color: Color(0xFF475569), fontSize: 10)),
                                if (isTakeaway)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                    decoration: BoxDecoration(color: Colors.deepOrange[100], borderRadius: BorderRadius.circular(4)),
                                    child: const Text('Para llevar (+\$5)', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.deepOrange)),
                                  ),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(_formatCurrency(subtotal), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF2563EB))),
                                const SizedBox(width: 4),
                                IconButton(
                                  icon: const Icon(Icons.clear, size: 18, color: Color(0xFFDC2626)),
                                  onPressed: () => _removePendingItem(index),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCobrarButton(ThemeService theme) {
    final bool isReadyToCharge = _amount > 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
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
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xFF8CE680), Color(0xFF5BCE50)],
                      ),
                      borderRadius: BorderRadius.circular(13),
                      border: Border.all(color: const Color(0xFF2E8525), width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF4ADE80).withValues(alpha: animatedGlow),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                        const BoxShadow(color: Color(0x44000000), offset: Offset(0, 3), blurRadius: 3),
                      ],
                    ),
                    child: child,
                  );
                },
                child: ElevatedButton.icon(
                  onPressed: _openPaymentModal,
                  icon: const Icon(Icons.shopping_cart_checkout, size: 22, color: Color(0xFF092606)),
                  label: FittedBox(
                    child: Text(
                      '🛒 ${tr('charge')} ${_formatAmount(_amount)}',
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
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
              )
            : Container(
                width: double.infinity,
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFF9CB49A),
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(color: const Color(0xFF6B8A69), width: 1.5),
                ),
                child: ElevatedButton.icon(
                  onPressed: null,
                  icon: const Icon(Icons.shopping_cart_checkout, size: 22, color: Color(0xFF2D3E2C)),
                  label: FittedBox(
                    child: Text(
                      '${tr('charge')} ${_formatAmount(_amount)}',
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        letterSpacing: 1.2,
                        color: Color(0xFF2D3E2C),
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

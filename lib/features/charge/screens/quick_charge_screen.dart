import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:oktane_pos/providers/auth_provider.dart';
import 'package:oktane_pos/ui/screens/login_screen.dart';
import '../services/charge_service.dart';
import '../widgets/amount_display.dart';
import '../widgets/pos_keypad.dart';
import '../widgets/payment_method_bottom_sheet.dart';
import '../widgets/item_pre_add_dialog.dart';
import 'charges_history_screen.dart';
import '../../printer/screens/printer_settings_screen.dart';
import '../../cash_cut/screens/cash_cut_screen.dart';
import '../../cash_cut/screens/cash_calendar_screen.dart';
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

  double get _amount => double.tryParse(_rawInput) ?? 0.0;

  void _handleKeyTap(String key) {
    setState(() {
      if (key == 'CLEAR') {
        _rawInput = '0';
        _pendingOrderItems.clear();
        _conceptController.clear();
      } else if (key == 'BACKSPACE') {
        if (_rawInput.length > 1) {
          _rawInput = _rawInput.substring(0, _rawInput.length - 1);
        } else {
          _rawInput = '0';
        }
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

    final tableId = widget.tableId ?? 't-1';
    final zoneId = widget.zoneId ?? 'zone-salon';

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
            const Text('👨‍🍳 ', style: TextStyle(fontSize: 20)),
            Expanded(
              child: Text(
                'Comanda enviada a cocina (\$${_amount.toStringAsFixed(2)} MXN) en $_selectedTableLabel',
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

  Future<void> _checkManagerAccessAndNavigate(Widget destination) async {
    final auth = context.read<AuthProvider>();
    final isManager = _rbacService.isManagerOrAdmin(auth.rol);

    if (isManager) {
      Navigator.push(context, MaterialPageRoute(builder: (context) => destination));
      return;
    }

    final pinCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final bool? granted = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.security, color: Colors.indigo),
            SizedBox(width: 8),
            Text('PIN de Gerente Requerido', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('El acceso a este módulo administrativo requiere autorización de supervisor.'),
              const SizedBox(height: 12),
              TextFormField(
                controller: pinCtrl,
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 4,
                decoration: const InputDecoration(
                  labelText: 'PIN de Gerente',
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
              final isValid = await _rbacService.verifyManagerPin(pinCtrl.text.trim());
              if (ctx.mounted) {
                Navigator.pop(ctx, isValid);
              }
            },
            child: const Text('Desbloquear'),
          ),
        ],
      ),
    );

    if (granted == true && mounted) {
      Navigator.push(context, MaterialPageRoute(builder: (context) => destination));
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ Acceso denegado: PIN de gerente requerido'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
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
      appBar: AppBar(
        titleSpacing: 16,
        title: const Text('Cobro Rápido', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        actions: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
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
                          color: Colors.indigo[50],
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.indigo[200]!, width: 0.8),
                        ),
                        child: Text(
                          isEs ? '🇲🇽 ES' : '🇺🇸 EN',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.indigo),
                        ),
                      ),
                    );
                  },
                ),
              ),
              IconButton(
                icon: const Icon(Icons.settings_outlined),
                tooltip: 'Ajustes',
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.symmetric(horizontal: 4),
                visualDensity: VisualDensity.compact,
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen()));
                },
              ),
              IconButton(
                icon: const Icon(Icons.logout),
                tooltip: 'Cerrar Sesión',
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.fromLTRB(4, 0, 12, 0),
                visualDensity: VisualDensity.compact,
                onPressed: () async {
                  final navigator = Navigator.of(context);
                  await auth.logout();
                  navigator.pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                    (route) => false,
                  );
                },
              ),
            ],
          ),
        ],
      ),
      resizeToAvoidBottomInset: false,
      body: ListenableBuilder(
        listenable: Listenable.merge([AppLocale.instance, ThemeService.instance]),
        builder: (context, _) {
          final theme = ThemeService.instance;
          return Container(
            decoration: BoxDecoration(
              gradient: theme.currentChassisGradient,
            ),
            child: SafeArea(
              child: Column(
                children: [
                  // Amount Display Top Banner with Embedded Retro LCD Action Shortcuts
                  AmountDisplay(
                    amount: _amount,
                    rawInput: _rawInput,
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

                // Sub-strip: "MANDAR COCINA" on left, "Oktane POS" text branding on right
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 42,
                          child: OutlinedButton.icon(
                            onPressed: _amount > 0
                                ? () {
                                    if (_pendingOrderItems.isEmpty) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Para mandar a cocina selecciona al menos un platillo o bebida del menú.'),
                                          backgroundColor: Colors.orange,
                                          duration: Duration(seconds: 3),
                                        ),
                                      );
                                      return;
                                    }
                                    _sendOrderToKitchen();
                                  }
                                : null,
                            icon: const Icon(Icons.soup_kitchen, size: 20),
                            label: FittedBox(
                              child: Text(
                                '👨‍🍳 ${tr('send_kitchen')}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: _amount > 0 ? theme.accentAction : Colors.grey[600]!),
                              foregroundColor: theme.displayText,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Stylized "Oktane POS" brand header (matching LoginScreen)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0A1128),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFF00B0FF).withValues(alpha: 0.5), width: 1),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ShaderMask(
                              shaderCallback: (bounds) => const LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [
                                  Color(0xFF0D47A1),
                                  Color(0xFF00B0FF),
                                  Color(0xFF00E5FF),
                                ],
                              ).createShader(bounds),
                              child: const Icon(
                                Icons.local_fire_department_rounded,
                                size: 18,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 6),
                            RichText(
                              text: const TextSpan(
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.8,
                                ),
                                children: [
                                  TextSpan(text: 'Oktane', style: TextStyle(color: Colors.white)),
                                  TextSpan(text: ' POS', style: TextStyle(color: Color(0xFF00E5FF))),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Responsive Controls Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 2.0),
                  child: Card(
                    elevation: 0,
                    color: theme.cardSurface,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Table & Waiter Selectors
                          Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  initialValue: _selectedTableLabel,
                                  isExpanded: true,
                                  dropdownColor: theme.cardSurface,
                                  iconEnabledColor: const Color(0xFFFFFFFF),
                                  style: const TextStyle(color: Color(0xFFFFFFFF), fontSize: 12, fontWeight: FontWeight.w600),
                                  decoration: InputDecoration(
                                    labelText: tr('table_location'),
                                    labelStyle: const TextStyle(color: Color(0xFFE2E8F0), fontSize: 12),
                                    border: const OutlineInputBorder(),
                                    enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: TableTheme.borderStrong)),
                                    focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: theme.accentAction, width: 1.5)),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  ),
                                  items: availableTables.map((t) => DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(color: Color(0xFFFFFFFF), fontSize: 12, fontWeight: FontWeight.w600)))).toList(),
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
                                  dropdownColor: theme.cardSurface,
                                  iconEnabledColor: const Color(0xFFFFFFFF),
                                  style: const TextStyle(color: Color(0xFFFFFFFF), fontSize: 12, fontWeight: FontWeight.w600),
                                  decoration: InputDecoration(
                                    labelText: tr('waiter_service'),
                                    labelStyle: const TextStyle(color: Color(0xFFE2E8F0), fontSize: 12),
                                    border: const OutlineInputBorder(),
                                    enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: TableTheme.borderStrong)),
                                    focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: theme.accentAction, width: 1.5)),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  ),
                                  items: waitersList.map((w) {
                                    return DropdownMenuItem<String>(
                                      value: w['name'],
                                      child: Text(w['name']!, style: const TextStyle(color: Color(0xFFFFFFFF), fontSize: 12, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
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

                          // Quick Order Navigation Button
                          SizedBox(
                            width: double.infinity,
                            height: 38,
                            child: ElevatedButton.icon(
                              onPressed: _navigateToTableOrderDetail,
                              icon: const Icon(Icons.assignment_outlined, size: 18),
                              label: Text('📋 ${tr('view_table')}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.indigo[800],
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),

                          // Menu Autocomplete Search Bar
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
                                ),
                              );
                            },
                          ),

                          // Pending Products Card ("En Corto")
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
                ),

                // POS Keypad
                Expanded(
                  child: PosKeypad(
                    onKeyTap: _handleKeyTap,
                  ),
                ),

                // Operational Action Button: Cobrar (Full-Width)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                  child: SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton.icon(
                      onPressed: _amount > 0 ? _openPaymentModal : null,
                      icon: const Icon(Icons.shopping_cart_checkout, size: 22),
                      label: FittedBox(
                        child: Text(
                          '${tr('charge')} ${_formatAmount(_amount)}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, letterSpacing: 0.5),
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.accentAction,
                        disabledBackgroundColor: Colors.grey[700],
                        foregroundColor: Colors.white,
                        elevation: _amount > 0 ? 4 : 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}
}

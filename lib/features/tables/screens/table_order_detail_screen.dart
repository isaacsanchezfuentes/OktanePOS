import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/zone_model.dart';
import '../models/table_model.dart';
import '../services/table_service.dart';
import '../../auth/services/rbac_service.dart';
import '../../menu/models/menu_item_model.dart';
import '../../menu/services/menu_service.dart';
import '../../charge/widgets/item_pre_add_dialog.dart';
import '../../charge/screens/quick_charge_screen.dart';
import '../../printer/services/thermal_printer_service.dart';

class TableOrderDetailScreen extends StatefulWidget {
  final ZoneModel zone;
  final RestaurantTableModel table;
  final TableService? tableService;
  final RbacService? rbacService;
  final MenuService? menuService;
  final VoidCallback? onTableUpdated;

  const TableOrderDetailScreen({
    super.key,
    required this.zone,
    required this.table,
    this.tableService,
    this.rbacService,
    this.menuService,
    this.onTableUpdated,
  });

  @override
  State<TableOrderDetailScreen> createState() => _TableOrderDetailScreenState();
}

class _TableOrderDetailScreenState extends State<TableOrderDetailScreen> {
  late final TableService _tableService;
  late final RbacService _rbacService;
  late final MenuService _menuService;

  late RestaurantTableModel _currentTable;
  late ZoneModel _currentZone;
  List<RestaurantTableModel> _allTables = [];
  final List<Map<String, dynamic>> _newRoundItems = [];
  TextEditingController? _searchFieldController;

  String? _selectedWaiterName;
  String? _selectedWaiterId;
  bool _isGlobalTakeaway = false;
  double _liveTotal = 0.0;
  String? _pendingChargeId;
  List<Map<String, dynamic>> _dispatchedItems = [];

  @override
  void initState() {
    super.initState();
    _tableService = widget.tableService ?? TableService();
    _rbacService = widget.rbacService ?? RbacService();
    _menuService = widget.menuService ?? MenuService();
    _currentTable = widget.table;
    _currentZone = widget.zone;
    _loadAllTables();
    _newRoundItems.addAll(_tableService.getTableDraft(_currentTable.id));
    _loadLiveTableCharge();
  }

  List<Map<String, dynamic>> _parseItemsFromConcept(String concept) {
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

  Future<void> _loadLiveTableCharge() async {
    try {
      final supa = Supabase.instance.client;
      final response = await supa
          .from('charges')
          .select()
          .eq('table_id', _currentTable.id)
          .eq('status', 'pending')
          .order('created_at', ascending: false)
          .maybeSingle();

      if (!mounted) return;

      if (response != null) {
        final String chargeId = response['id']?.toString() ?? '';
        final double amt = (response['amount'] as num?)?.toDouble() ?? 0.0;
        final String concept = response['concept']?.toString() ?? 'Consumo Mesa';
        final String waiterName = _selectedWaiterName ?? 'Mesero';

        final parsedItems = _parseItemsFromConcept(concept);

        final liveTicket = {
          'ticket_id': chargeId,
          'amount': amt,
          'concept': concept,
          'waiter_id': response['waiter_id']?.toString() ?? response['user_id']?.toString(),
          'waiter_name': waiterName,
          'is_peer_support': false,
          'created_at': response['created_at']?.toString(),
        };

        setState(() {
          _pendingChargeId = chargeId;
          _liveTotal = amt;
          _dispatchedItems = parsedItems;
          _currentTable = _currentTable.copyWith(
            status: 'occupied',
            activeTickets: [liveTicket],
          );
        });
      } else {
        setState(() {
          _pendingChargeId = null;
          _liveTotal = 0.0;
          _dispatchedItems.clear();
        });
      }
    } catch (e) {
      debugPrint('⚠️ Consulta de comanda viva por mesa en Supabase omitida: $e');
    }
  }

  Future<void> _confirmRemoveDispatchedItem(int index) async {
    if (index < 0 || index >= _dispatchedItems.length) return;

    final item = _dispatchedItems[index];
    final String name = item['name']?.toString() ?? 'Producto';

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text('¿Retirar producto?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text('¿Deseas eliminar "$name" de la cuenta de la mesa?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red[700], foregroundColor: Colors.white),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    // 1. Remove item from list
    setState(() {
      _dispatchedItems.removeAt(index);
    });

    // 2. Recalculate total
    final double newTotal = _dispatchedItems.fold(0.0, (sum, i) {
      final p = (i['price'] as num?)?.toDouble() ?? 0.0;
      final q = (i['quantity'] as num?)?.toInt() ?? 1;
      return sum + (p * q);
    });

    // 3. Reconstruct concept
    final List<String> itemStrs = _dispatchedItems.map((e) {
      final q = (e['quantity'] as num?)?.toInt() ?? 1;
      final qPrefix = q > 1 ? '${q}x ' : '';
      return '$qPrefix${e['name']} (\$' + (e['price'] as num).toDouble().toStringAsFixed(1) + ')';
    }).toList();

    final String tableLabel = 'Mesa #${_currentTable.tableNumber}';
    final String newConcept = '$tableLabel - Ronda: ${itemStrs.join(', ')}';

    try {
      final supa = Supabase.instance.client;

      if (newTotal > 0 && _pendingChargeId != null) {
        // Update charge in Supabase
        await supa.from('charges').update({
          'amount': newTotal,
          'concept': newConcept,
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', _pendingChargeId!);

        if (!mounted) return;

        setState(() {
          _liveTotal = newTotal;
        });

        _tableService.notifyListeners();
        widget.onTableUpdated?.call();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🗑️ "$name" retirado de la cuenta de Mesa #${_currentTable.tableNumber}'),
            backgroundColor: Colors.orange[800],
          ),
        );
      } else {
        // newTotal == 0: Cancel charge and liberate table in Supabase
        if (_pendingChargeId != null) {
          await supa.from('charges').update({
            'status': 'cancelled',
            'updated_at': DateTime.now().toIso8601String(),
          }).eq('id', _pendingChargeId!);
        }

        await supa.from('restaurant_tables').update({
          'status': 'available',
        }).eq('id', _currentTable.id);

        _tableService.clearAllTableTickets(_currentZone.id, _currentTable.id);

        if (!mounted) return;

        setState(() {
          _liveTotal = 0.0;
          _dispatchedItems.clear();
          _currentTable = _currentTable.copyWith(
            status: 'free',
            activeTickets: const [],
          );
        });

        _tableService.notifyListeners();
        widget.onTableUpdated?.call();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🧹 Todos los productos fueron retirados. Mesa #${_currentTable.tableNumber} liberada.'),
            backgroundColor: Colors.green[800],
          ),
        );

        // Pop back to map screen with table in green
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('⚠️ Error al eliminar ítem de comanda en Supabase: $e');
    }
  }

  void _loadAllTables() {
    final zones = _tableService.getZones();
    final List<RestaurantTableModel> list = [];
    for (final z in zones) {
      list.addAll(_tableService.getTablesByZone(z.id));
    }
    setState(() {
      _allTables = list;
    });
  }

  Future<void> _switchTable(RestaurantTableModel newTable, ZoneModel newZone) async {
    if (newTable.id == _currentTable.id) return;

    if (_newRoundItems.isNotEmpty) {
      final bool? confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange),
              SizedBox(width: 8),
              Text('Ítems sin enviar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          content: const Text('Tiene productos en la ronda actual sin enviar a cocina. ¿Desea descartarlos y cambiar de mesa?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange[800], foregroundColor: Colors.white),
              child: const Text('Descartar y Cambiar'),
            ),
          ],
        ),
      );

      if (confirm != true) return;
    }

    setState(() {
      _currentTable = newTable;
      _currentZone = newZone;
      _newRoundItems.clear();
      _isGlobalTakeaway = false;
    });

    _reloadTableData();
  }

  void _reloadTableData() {
    final updatedList = _tableService.getTablesByZone(_currentZone.id);
    final updatedTable = updatedList.firstWhere((t) => t.id == _currentTable.id, orElse: () => _currentTable);

    setState(() {
      _currentTable = updatedTable;
    });
    _loadLiveTableCharge();
  }

  String _formatCurrency(double amount) {
    return NumberFormat.currency(locale: 'es_MX', symbol: '\$', decimalDigits: 2).format(amount);
  }

  double get _newRoundTotal {
    return _newRoundItems.fold(0.0, (sum, item) {
      final sub = (item['subtotal'] as num?)?.toDouble() ?? 0.0;
      return sum + sub;
    });
  }

  double get _previousRoundsTotal {
    if (_liveTotal > 0) {
      return _liveTotal;
    }
    return _currentTable.activeTickets.fold(0.0, (sum, ticket) {
      final amt = (ticket['amount'] as num?)?.toDouble() ?? 0.0;
      return sum + amt;
    });
  }

  double get _grandTotal => _previousRoundsTotal + _newRoundTotal;

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
              Text('Ingrese el PIN para transferir la atención de $activeUserEmail a $newName.'),
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
        SnackBar(content: Text('✅ Atención de mesa transferida a $newName'), backgroundColor: Colors.green[700]),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ Transferencia cancelada: PIN incorrecto'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _onMenuItemSelected(MenuItemModel item) async {
    final resultItem = await ItemPreAddDialog.show(context, menuItem: item);
    if (resultItem == null || !mounted) return;

    // Auto-clear search field and unfocus keyboard
    _searchFieldController?.clear();
    FocusScope.of(context).unfocus();

    setState(() {
      _newRoundItems.add(resultItem);
      _tableService.saveTableDraft(_currentTable.id, _newRoundItems);
    });
  }

  Future<void> _sendNewRoundToKitchen() async {
    if (_newRoundItems.isEmpty) return;

    final activeUser = Supabase.instance.client.auth.currentUser;
    final currentUserId = _selectedWaiterId ?? (activeUser?.id ?? 'waiter-1');
    final currentWaiterName = _selectedWaiterName ?? (activeUser?.email?.split('@').first ?? 'Mesero');

    final List<String> itemDescriptions = [];
    for (final item in _newRoundItems) {
      final name = item['name']?.toString() ?? 'Producto';
      final qty = (item['quantity'] as num?)?.toInt() ?? 1;
      final price = (item['price'] as num?)?.toDouble() ?? 0.0;
      final isTakeaway = item['is_takeaway'] == true;
      final notes = item['notes']?.toString() ?? '';

      final qtyPrefix = qty > 1 ? '${qty}x ' : '';
      final takeawayTag = isTakeaway ? ' [Para llevar]' : '';
      final notesTag = notes.isNotEmpty ? ' ($notes)' : '';

      itemDescriptions.add('$qtyPrefix$name (\$$price)$takeawayTag$notesTag');
    }

    final conceptFinal = 'Ronda: ${itemDescriptions.join(', ')}';

    // 1. Await Supabase DB persistence
    await _tableService.addTicketToTable(
      _currentZone.id,
      _currentTable.id,
      amount: _newRoundTotal,
      concept: conceptFinal,
      waiterId: currentUserId,
      waiterName: currentWaiterName,
    );

    // 2. Clear local draft and capture tray
    _tableService.clearTableDraft(_currentTable.id);

    if (mounted) {
      setState(() {
        _newRoundItems.clear();
        _isGlobalTakeaway = false;
      });
    }

    // 3. Reload fresh live table charge from Supabase
    await _loadLiveTableCharge();

    widget.onTableUpdated?.call();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Text('👨‍🍳 ', style: TextStyle(fontSize: 20)),
              Expanded(
                child: Text(
                  'Comanda enviada a cocina exitosamente en Mesa #${_currentTable.tableNumber}',
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
    }
  }

  void _proceedToConsolidatedCharge() {
    // If there are pending new items, auto-save them first
    if (_newRoundItems.isNotEmpty) {
      _sendNewRoundToKitchen();
    }

    final List<String> waiterDetails = [];
    for (final t in _currentTable.activeTickets) {
      final name = t['waiter_name']?.toString() ?? 'Mesero';
      final isSupport = t['is_peer_support'] == true;
      final amt = (t['amount'] as num?)?.toDouble() ?? 0.0;
      final label = isSupport ? '$name (Apoyo)' : name;
      waiterDetails.add('$label: ${_formatCurrency(amt)}');
    }

    final conceptFinal = 'Mesa #${_currentTable.tableNumber} - Consumo Consolidado [${waiterDetails.join(', ')}]';

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QuickChargeScreen(
          initialAmount: _previousRoundsTotal,
          initialConcept: conceptFinal,
          tableId: _currentTable.id,
          zoneId: _currentZone.id,
          tableService: _tableService,
          onPaymentSuccess: () {
            widget.onTableUpdated?.call();
            if (mounted) Navigator.pop(context);
          },
        ),
      ),
    );
  }

  Future<void> _printPreCheckTicket() async {
    final printerService = ThermalPrinterService();
    final isConnected = await printerService.ensureConnected();

    if (!isConnected && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Impresora Bluetooth no conectada. Configure en Ajustes.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final activeUser = Supabase.instance.client.auth.currentUser;
    final waiterName = _selectedWaiterName ?? (activeUser?.email?.split('@').first ?? 'Mesero');

    final List<Map<String, dynamic>> allItems = [];
    for (final ticket in _currentTable.activeTickets) {
      allItems.add({
        'name': ticket['concept']?.toString() ?? 'Consumo',
        'quantity': 1,
        'price': (ticket['amount'] as num?)?.toDouble() ?? 0.0,
        'subtotal': (ticket['amount'] as num?)?.toDouble() ?? 0.0,
      });
    }
    allItems.addAll(_newRoundItems);

    final success = await printerService.printTablePreCheckTicket(
      tableName: 'Mesa #${_currentTable.tableNumber}',
      zoneName: _currentZone.name,
      waiterName: waiterName,
      items: allItems,
      totalAmount: _grandTotal,
    );

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🖨️ Pre-cuenta impresa para Mesa #${_currentTable.tableNumber}'),
            backgroundColor: Colors.green[700],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Error al despachar impresión a la impresora térmica'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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

    final zones = _tableService.getZones();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0D47A1),
        elevation: 1,
        titleSpacing: 0,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.table_restaurant, color: Color(0xFF0D47A1), size: 22),
            const SizedBox(width: 8),
            Flexible(
              child: Theme(
                data: Theme.of(context).copyWith(
                  canvasColor: Colors.white,
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _currentTable.id,
                    isExpanded: true,
                    dropdownColor: Colors.white,
                    elevation: 4,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0D47A1)),
                    icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF0D47A1)),
                    items: _allTables.map((t) {
                      final isSelected = t.id == _currentTable.id;
                      final zone = zones.firstWhere((z) => z.id == t.zoneId, orElse: () => _currentZone);
                      final label = 'Mesa #${t.tableNumber} (${zone.name})';
                      return DropdownMenuItem<String>(
                        value: t.id,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.blue.shade50 : Colors.transparent,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            label,
                            style: TextStyle(
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              fontSize: 14,
                              color: isSelected ? const Color(0xFF0D47A1) : Colors.black87,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (selectedId) {
                      if (selectedId != null) {
                        final selectedTable = _allTables.firstWhere((t) => t.id == selectedId);
                        final selectedZone = zones.firstWhere((z) => z.id == selectedTable.zoneId, orElse: () => _currentZone);
                        _switchTable(selectedTable, selectedZone);
                      }
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.print_outlined, color: Color(0xFF0D47A1)),
            tooltip: 'Imprimir Pre-cuenta',
            onPressed: _printPreCheckTicket,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Top Context Bar: Waiter Selector
            Container(
              color: Colors.grey[100],
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.person_pin, color: Colors.indigo, size: 20),
                  const SizedBox(width: 8),
                  const Text('Mesero a cargo:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedWaiterName ?? activeUserName,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        isDense: true,
                      ),
                      items: waitersList.map((w) {
                        return DropdownMenuItem<String>(
                          value: w['name'],
                          child: Text(w['name']!, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis),
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
            ),

            // Full-Width Menu Autocomplete Search Bar
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Autocomplete<MenuItemModel>(
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
                  _searchFieldController = controller;
                  return TextField(
                    controller: controller,
                    focusNode: focusNode,
                    decoration: InputDecoration(
                      hintText: '🔍 Buscar y agregar producto del menú...',
                      prefixIcon: const Icon(Icons.search, color: Colors.blue),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  );
                },
              ),
            ),

            // Independent Scrollable Order List
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Section 1: Por Enviar (Nueva Ronda) Header with Global Takeaway Toggle
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Flexible(
                          child: Text(
                            ' Por Enviar (Nueva Ronda)',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.indigo),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (_newRoundItems.isNotEmpty) ...[
                          FilterChip(
                            label: const Text('Todo +\$5 Llevar', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                            selected: _isGlobalTakeaway,
                            selectedColor: Colors.deepOrange[100],
                            onSelected: (val) {
                              setState(() {
                                _isGlobalTakeaway = val;
                                for (var i = 0; i < _newRoundItems.length; i++) {
                                  _newRoundItems[i]['is_takeaway'] = val;
                                  final price = (_newRoundItems[i]['price'] as num?)?.toDouble() ?? 0.0;
                                  final qty = (_newRoundItems[i]['quantity'] as num?)?.toInt() ?? 1;
                                  _newRoundItems[i]['subtotal'] = (price + (val ? 5.0 : 0.0)) * qty;
                                }
                              });
                            },
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _formatCurrency(_newRoundTotal),
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.indigo),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),

                    _newRoundItems.isEmpty
                        ? Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: Center(
                              child: Text(
                                'Busque productos arriba para agregar a esta nueva ronda',
                                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                              ),
                            ),
                          )
                        : Column(
                            children: _newRoundItems.asMap().entries.map((entry) {
                              final index = entry.key;
                              final item = entry.value;
                              final name = item['name']?.toString() ?? 'Producto';
                              final qty = (item['quantity'] as num?)?.toInt() ?? 1;
                              final price = (item['price'] as num?)?.toDouble() ?? 0.0;
                              final subtotal = (item['subtotal'] as num?)?.toDouble() ?? 0.0;
                              final isTakeaway = item['is_takeaway'] == true;
                              final notes = item['notes']?.toString() ?? '';

                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                elevation: 1,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(color: Colors.indigo[200]!),
                                ),
                                child: ListTile(
                                  dense: true,
                                  title: Text('${qty}x $name (\$$price c/u)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                  subtitle: Wrap(
                                    crossAxisAlignment: WrapCrossAlignment.center,
                                    spacing: 6,
                                    runSpacing: 2,
                                    children: [
                                      if (notes.isNotEmpty) Text('Notas: $notes', style: const TextStyle(fontSize: 11)),
                                      FilterChip(
                                        label: const Text('+\$5 Llevar', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
                                        selected: isTakeaway,
                                        selectedColor: Colors.deepOrange[100],
                                        visualDensity: VisualDensity.compact,
                                        onSelected: (val) {
                                          setState(() {
                                            item['is_takeaway'] = val;
                                            item['subtotal'] = (price + (val ? 5.0 : 0.0)) * qty;
                                          });
                                          _tableService.saveTableDraft(_currentTable.id, _newRoundItems);
                                        },
                                      ),
                                    ],
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(_formatCurrency(subtotal), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.indigo)),
                                      IconButton(
                                        icon: const Icon(Icons.edit, size: 18, color: Colors.blue),
                                        onPressed: () async {
                                          final menuItem = MenuItemModel(
                                            id: item['item_id']?.toString() ?? 'm-temp',
                                            name: name,
                                            price: price,
                                          );
                                          final updatedResult = await ItemPreAddDialog.show(context, menuItem: menuItem);
                                          if (updatedResult != null && mounted) {
                                            setState(() {
                                              _newRoundItems[index] = updatedResult;
                                            });
                                            _tableService.saveTableDraft(_currentTable.id, _newRoundItems);
                                          }
                                        },
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                                        onPressed: () {
                                          setState(() {
                                            _newRoundItems.removeAt(index);
                                          });
                                          _tableService.saveTableDraft(_currentTable.id, _newRoundItems);
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),

                    const Divider(height: 24),

                    // Section 2: Rondas Previas / Servidas
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          ' Rondas Previas / Servidas',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
                        ),
                        if (_previousRoundsTotal > 0)
                          Text(
                            _formatCurrency(_previousRoundsTotal),
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.green),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    _dispatchedItems.isNotEmpty
                        ? Column(
                            children: _dispatchedItems.asMap().entries.map((entry) {
                              final index = entry.key;
                              final item = entry.value;
                              final name = item['name']?.toString() ?? 'Producto';
                              final qty = (item['quantity'] as num?)?.toInt() ?? 1;
                              final price = (item['price'] as num?)?.toDouble() ?? 0.0;
                              final subtotal = (item['subtotal'] as num?)?.toDouble() ?? (price * qty);

                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                elevation: 1,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(color: Colors.green[200]!),
                                ),
                                child: ListTile(
                                  dense: true,
                                  leading: CircleAvatar(
                                    radius: 14,
                                    backgroundColor: Colors.green[50],
                                    child: const Icon(
                                      Icons.check_circle_outline,
                                      color: Colors.green,
                                      size: 16,
                                    ),
                                  ),
                                  title: Text(
                                    '${qty}x $name',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                  subtitle: Text(
                                    'Precio unitario: ${_formatCurrency(price)}',
                                    style: TextStyle(fontSize: 11, color: Colors.grey[700]),
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        _formatCurrency(subtotal),
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.green),
                                      ),
                                      const SizedBox(width: 4),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline, size: 20, color: Colors.redAccent),
                                        tooltip: 'Retirar producto de la cuenta',
                                        onPressed: () => _confirmRemoveDispatchedItem(index),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          )
                        : _currentTable.activeTickets.isEmpty
                            ? Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.grey[50],
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.grey[300]!),
                                ),
                                child: Center(
                                  child: Text(
                                    'No hay comandas previas servidas en esta mesa',
                                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                  ),
                                ),
                              )
                            : Column(
                                children: _currentTable.activeTickets.map((ticket) {
                                  final isPeerSupport = ticket['is_peer_support'] == true;
                                  final ticketWaiter = ticket['waiter_name']?.toString() ?? 'Mesero';
                                  final amt = (ticket['amount'] as num?)?.toDouble() ?? 0.0;

                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    elevation: 1,
                                    child: ListTile(
                                      dense: true,
                                      leading: CircleAvatar(
                                        radius: 14,
                                        backgroundColor: isPeerSupport ? Colors.purple[50] : Colors.blue[50],
                                        child: Icon(
                                          isPeerSupport ? Icons.handshake : Icons.receipt,
                                          color: isPeerSupport ? Colors.purple : Colors.blue,
                                          size: 14,
                                        ),
                                      ),
                                      title: Text(ticket['concept']?.toString() ?? 'Consumo Mesa', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                      subtitle: Wrap(
                                        spacing: 6,
                                        children: [
                                          Text('Atendido por: $ticketWaiter', style: const TextStyle(fontSize: 11)),
                                          if (isPeerSupport)
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                              decoration: BoxDecoration(color: Colors.purple[100], borderRadius: BorderRadius.circular(4)),
                                              child: const Text('APOYO', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.purple)),
                                            ),
                                        ],
                                      ),
                                      trailing: Text(_formatCurrency(amt), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.green)),
                                    ),
                                  );
                                }).toList(),
                              ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),

            // Fixed Bottom Action Bar
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('TOTAL ACUMULADO MESA:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey)),
                      Text(
                        _formatCurrency(_grandTotal),
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.green),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      // Mandar a Cocina / Guardar Button
                      Expanded(
                        child: SizedBox(
                          height: 50,
                          child: OutlinedButton.icon(
                            onPressed: _newRoundItems.isNotEmpty ? _sendNewRoundToKitchen : null,
                            icon: const Icon(Icons.soup_kitchen, size: 20),
                            label: const FittedBox(
                              child: Text(
                                '👨‍🍳 ENVIAR COCINA',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: _newRoundItems.isNotEmpty ? Colors.indigo : Colors.grey[300]!),
                              foregroundColor: Colors.indigo[900],
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Ir a Cobrar Button
                      Expanded(
                        child: SizedBox(
                          height: 50,
                          child: ElevatedButton.icon(
                            onPressed: _grandTotal > 0 ? _proceedToConsolidatedCharge : null,
                            icon: const Icon(Icons.point_of_sale, size: 20),
                            label: FittedBox(
                              child: Text(
                                '💳 IR A COBRAR (${_formatCurrency(_grandTotal)})',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green[700],
                              disabledBackgroundColor: Colors.grey[300],
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

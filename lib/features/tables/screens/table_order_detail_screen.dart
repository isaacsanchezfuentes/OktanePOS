import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/zone_model.dart';
import '../models/table_model.dart';
import '../services/table_service.dart';
import '../theme/table_theme.dart';
import 'tables_map_screen.dart';
import '../../auth/services/rbac_service.dart';
import '../../menu/models/menu_item_model.dart';
import '../../menu/services/menu_service.dart';
import '../../charge/widgets/item_pre_add_dialog.dart';
import '../../charge/screens/quick_charge_screen.dart';
import '../../printer/services/thermal_printer_service.dart';

enum OrderViewMode { split, fullCatalog, fullDetail }

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
  OrderViewMode _viewMode = OrderViewMode.split;
  String _selectedCategory = 'Todos';

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
    Future.microtask(() => _loadLiveTableCharge());
  }

  List<Map<String, dynamic>> _parseItemsFromConcept(String concept) {
    final List<Map<String, dynamic>> items = [];
    final regExp = RegExp(r'(?:(\d+)\s*x\s*)?([^($]+?)\s*\(\$([\d.]+)\)');
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
      return '$qPrefix${e['name']} (\$${(e['price'] as num).toDouble().toStringAsFixed(1)})';
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
        }).eq('id', _pendingChargeId!);

        if (!mounted) return;

        setState(() {
          _liveTotal = newTotal;
        });

        _tableService.notifyTableUpdate();
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

        _tableService.notifyTableUpdate();
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

  Future<void> _changeTable(RestaurantTableModel newTable, ZoneModel newZone) async {
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
    _loadAllTables();
    final updatedTable = _allTables.firstWhere(
      (t) => t.id == _currentTable.id,
      orElse: () => _currentTable,
    );

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

  Future<void> _openTableSwitcherModal() async {
    final zones = _tableService.getZones();
    _loadAllTables();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(ctx).size.height * 0.8,
        ),
        child: Container(
          decoration: const BoxDecoration(
            color: Color(0xFF0F172A),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '🪑 Seleccionar / Cambiar Mesa',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const Divider(color: Color(0xFF334155)),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: zones.map((z) {
                      final tablesInZone = _allTables.where((t) => t.zoneId == z.id).toList();
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Text(
                              '📍 ${z.name}',
                              style: const TextStyle(color: Color(0xFF00E5FF), fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          ),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: tablesInZone.map((t) {
                              final isSelected = t.id == _currentTable.id;
                              final isOccupied = t.status == 'occupied' || t.activeTickets.isNotEmpty;
                              return ChoiceChip(
                                label: Text('Mesa #${t.tableNumber}'),
                                labelStyle: TextStyle(
                                  color: isSelected ? Colors.white : (isOccupied ? Colors.orange[200] : Colors.green[200]),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                                selected: isSelected,
                                selectedColor: const Color(0xFF1D4ED8),
                                backgroundColor: isOccupied ? const Color(0xFF451A03) : const Color(0xFF064E3B),
                                onSelected: (val) {
                                  Navigator.pop(ctx);
                                  _changeTable(t, z);
                                },
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 12),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWaiterBar(String activeUserName, List<Map<String, String>> waitersList) {
    return Container(
      color: const Color(0xFF0F172A),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.person_pin, color: Color(0xFFF97316), size: 20),
          const SizedBox(width: 8),
          const Text(
            'Mesero a cargo:',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFFF97316)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFFFF),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF334155), width: 1.2),
                boxShadow: const [
                  BoxShadow(color: Color(0x22000000), blurRadius: 2, offset: Offset(0, 1)),
                ],
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedWaiterName ?? activeUserName,
                  isExpanded: true,
                  dropdownColor: const Color(0xFFFFFFFF),
                  iconEnabledColor: const Color(0xFF2563EB),
                  style: const TextStyle(
                    color: Color(0xFF2563EB),
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                  items: waitersList.map((w) {
                    return DropdownMenuItem<String>(
                      value: w['name'],
                      child: Text(
                        w['name']!,
                        style: const TextStyle(
                          color: Color(0xFF2563EB),
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
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
          ),
        ],
      ),
    );
  }

  Widget _buildOneTouchMenu(List<MenuItemModel> menuItems) {
    final List<String> categories = ['Todos', 'Bebidas', 'Alimentos', 'Postres', 'Otros'];
    final filteredItems = _selectedCategory == 'Todos'
        ? menuItems
        : menuItems.where((i) => i.category.toLowerCase() == _selectedCategory.toLowerCase() || i.name.toLowerCase().contains(_selectedCategory.toLowerCase())).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category Chips Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          color: const Color(0xFF1E293B),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: categories.map((cat) {
                final isSelected = _selectedCategory == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 6.0),
                  child: ChoiceChip(
                    label: Text(
                      cat,
                      style: TextStyle(
                        color: isSelected ? Colors.white : const Color(0xFFCBD5E1),
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: const Color(0xFF1D4ED8),
                    backgroundColor: const Color(0xFF334155),
                    onSelected: (val) {
                      if (val) setState(() => _selectedCategory = cat);
                    },
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        // Product Grid
        Expanded(
          child: Container(
            color: const Color(0xFFF1F5F9),
            child: filteredItems.isEmpty
                ? const Center(
                    child: Text('No hay productos en esta categoría', style: TextStyle(color: Color(0xFF475569), fontSize: 12)),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(6),
                    physics: const BouncingScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: _viewMode == OrderViewMode.fullCatalog ? 3 : 2,
                      childAspectRatio: _viewMode == OrderViewMode.fullCatalog ? 1.25 : 1.05,
                      crossAxisSpacing: 6,
                      mainAxisSpacing: 6,
                    ),
                    itemCount: filteredItems.length,
                    itemBuilder: (context, index) {
                      final item = filteredItems[index];
                      return Card(
                        elevation: 1.5,
                        color: const Color(0xFFFFFFFF),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.2),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () {
                            HapticFeedback.lightImpact();
                            setState(() {
                              _newRoundItems.add({
                                'item_id': item.id,
                                'name': item.name,
                                'price': item.price,
                                'quantity': 1,
                                'subtotal': item.price,
                                'is_takeaway': _isGlobalTakeaway,
                                'notes': '',
                              });
                              _tableService.saveTableDraft(_currentTable.id, _newRoundItems);
                            });
                          },
                          onLongPress: () => _onMenuItemSelected(item),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.name,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 12,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      _formatCurrency(item.price),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w900,
                                        fontSize: 12,
                                        color: Color(0xFF16A34A),
                                      ),
                                    ),
                                    const Icon(Icons.add_circle, color: Color(0xFF1D4ED8), size: 18),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildOrderListColumn(List<MenuItemModel> menuItems, bool isCompact) {
    return Column(
      children: [
        if (_viewMode == OrderViewMode.fullDetail)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            color: const Color(0xFF1E293B),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '📋 Detalle Completo de Comanda',
                  style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                ),
                ActionChip(
                  avatar: const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Colors.white),
                  label: const Text('Volver al catálogo', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                  backgroundColor: const Color(0xFF1D4ED8),
                  onPressed: () {
                    setState(() {
                      _viewMode = OrderViewMode.split;
                    });
                  },
                ),
              ],
            ),
          ),
        Padding(
          padding: const EdgeInsets.all(8.0),
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
                style: const TextStyle(fontSize: 12),
                decoration: InputDecoration(
                  hintText: '🔍 Buscar...',
                  prefixIcon: const Icon(Icons.search, color: Colors.blue, size: 18),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  isDense: true,
                ),
              );
            },
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Flexible(
                      child: Text(
                        'Por Enviar',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: TableTheme.textPrimary),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (_newRoundItems.isNotEmpty)
                      Text(
                        _formatCurrency(_newRoundTotal),
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.indigo),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                _newRoundItems.isEmpty
                    ? Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: const Center(
                          child: Text(
                            'Sin ítems por enviar',
                            style: TextStyle(fontSize: 11, color: Colors.grey),
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

                          return Card(
                            margin: const EdgeInsets.only(bottom: 4),
                            elevation: 1,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: BorderSide(color: Colors.indigo[200]!),
                            ),
                            child: ListTile(
                              dense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
                              title: Text(
                                '${qty}x $name',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(
                                '\$$price c/u',
                                style: const TextStyle(fontSize: 10, color: Colors.grey),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(_formatCurrency(subtotal), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.indigo)),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, size: 16, color: Colors.red),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
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
                const Divider(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Servidas',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: TableTheme.textPrimary),
                    ),
                    if (_previousRoundsTotal > 0)
                      Text(
                        _formatCurrency(_previousRoundsTotal),
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
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
                            margin: const EdgeInsets.only(bottom: 4),
                            elevation: 1,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: BorderSide(color: Colors.green[200]!),
                            ),
                            child: ListTile(
                              dense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
                              title: Text(
                                '${qty}x $name',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(_formatCurrency(subtotal), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.green)),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, size: 16, color: Colors.redAccent),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    onPressed: () => _confirmRemoveDispatchedItem(index),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      )
                    : Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: const Center(
                          child: Text(
                            'Sin rondas servidas',
                            style: TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                        ),
                      ),
              ],
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 6,
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
                  const Text('TOTAL:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                  Text(
                    _formatCurrency(_grandTotal),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 38,
                    child: OutlinedButton.icon(
                      onPressed: _newRoundItems.isNotEmpty ? _sendNewRoundToKitchen : null,
                      icon: const Icon(Icons.send_rounded, size: 16),
                      label: const FittedBox(
                        child: Text('MANDAR PREPARACIÓN', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10)),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: _newRoundItems.isNotEmpty ? Colors.indigo : Colors.grey[300]!),
                        foregroundColor: Colors.indigo[900],
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  SizedBox(
                    width: double.infinity,
                    height: 38,
                    child: ElevatedButton.icon(
                      onPressed: _grandTotal > 0 ? _proceedToConsolidatedCharge : null,
                      icon: const Icon(Icons.point_of_sale, size: 16),
                      label: FittedBox(
                        child: Text('COBRAR (${_formatCurrency(_grandTotal)})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10)),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[700],
                        disabledBackgroundColor: Colors.grey[300],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
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

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0D47A1),
        elevation: 1,
        titleSpacing: 8,
        title: InkWell(
          onTap: _openTableSwitcherModal,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.table_restaurant, color: Color(0xFF0D47A1), size: 20),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    'Mesa #${_currentTable.tableNumber} (${_currentZone.name})',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0D47A1)),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.swap_horiz, size: 18, color: Color(0xFF0D47A1)),
              ],
            ),
          ),
        ),
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: Icon(
                  Icons.receipt_long_rounded,
                  color: _viewMode == OrderViewMode.fullDetail ? const Color(0xFF1D4ED8) : const Color(0xFF0D47A1),
                ),
                tooltip: 'Ver Detalle Completo',
                onPressed: () {
                  setState(() {
                    _viewMode = OrderViewMode.fullDetail;
                  });
                },
              ),
              if (_newRoundItems.isNotEmpty)
                Positioned(
                  right: 6,
                  top: 6,
                  child: CircleAvatar(
                    radius: 8,
                    backgroundColor: Colors.red,
                    child: Text(
                      '${_newRoundItems.length}',
                      style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: Icon(
              _viewMode == OrderViewMode.fullCatalog ? Icons.vertical_split_rounded : Icons.grid_view_rounded,
              color: const Color(0xFF0D47A1),
            ),
            tooltip: _viewMode == OrderViewMode.fullCatalog ? 'Vista Compartida' : 'Catálogo Completo',
            onPressed: () {
              setState(() {
                _viewMode = (_viewMode == OrderViewMode.fullCatalog)
                    ? OrderViewMode.split
                    : OrderViewMode.fullCatalog;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.print_outlined, color: Color(0xFF0D47A1)),
            tooltip: 'Imprimir Pre-cuenta',
            onPressed: _printPreCheckTicket,
          ),
        ],
      ),
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Column(
          children: [
            _buildWaiterBar(activeUserName, waitersList),
            Expanded(
              child: _viewMode == OrderViewMode.fullCatalog
                  ? _buildOneTouchMenu(menuItems)
                  : _viewMode == OrderViewMode.fullDetail
                      ? _buildOrderListColumn(menuItems, false)
                      : Row(
                          children: [
                            Expanded(
                              flex: 5,
                              child: _buildOrderListColumn(menuItems, true),
                            ),
                            const VerticalDivider(width: 1, thickness: 1, color: Color(0xFFCBD5E1)),
                            Expanded(
                              flex: 7,
                              child: _buildOneTouchMenu(menuItems),
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

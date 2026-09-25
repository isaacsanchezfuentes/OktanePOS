import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/zone_model.dart';
import '../models/table_model.dart';
import '../services/table_service.dart';
import '../screens/table_order_detail_screen.dart';
import '../../charge/screens/quick_charge_screen.dart';
import '../../printer/services/thermal_printer_service.dart';

class TableTicketsBottomSheet extends StatefulWidget {
  final ZoneModel zone;
  final RestaurantTableModel table;
  final TableService tableService;
  final VoidCallback? onTableUpdated;

  const TableTicketsBottomSheet({
    super.key,
    required this.zone,
    required this.table,
    required this.tableService,
    this.onTableUpdated,
  });

  static Future<void> show(
    BuildContext context, {
    required ZoneModel zone,
    required RestaurantTableModel table,
    required TableService tableService,
    VoidCallback? onTableUpdated,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => TableTicketsBottomSheet(
        zone: zone,
        table: table,
        tableService: tableService,
        onTableUpdated: onTableUpdated,
      ),
    );
  }

  @override
  State<TableTicketsBottomSheet> createState() => _TableTicketsBottomSheetState();
}

class _TableTicketsBottomSheetState extends State<TableTicketsBottomSheet> {
  late RestaurantTableModel _currentTable;

  @override
  void initState() {
    super.initState();
    _currentTable = widget.table;
    _loadLiveTableCharge();
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

      if (response != null && mounted) {
        final double amt = (response['amount'] as num?)?.toDouble() ?? 0.0;
        final String concept = response['concept']?.toString() ?? 'Consumo Mesa';
        setState(() {
          _currentTable = _currentTable.copyWith(
            status: 'occupied',
            activeTickets: [
              {
                'ticket_id': response['id']?.toString() ?? 'tk-live',
                'amount': amt,
                'concept': concept,
                'waiter_name': 'Mesero',
              }
            ],
          );
        });
      }
    } catch (e) {
      debugPrint('⚠️ Consulta viva de charge en bottom sheet omitida: $e');
    }
  }

  String _formatCurrency(double amount) {
    return NumberFormat.currency(locale: 'es_MX', symbol: '\$', decimalDigits: 2).format(amount);
  }

  double get _totalTableAmount {
    return _currentTable.activeTickets.fold(0.0, (sum, ticket) {
      final amt = (ticket['amount'] as num?)?.toDouble() ?? 0.0;
      return sum + amt;
    });
  }

  String _buildConsolidatedConcept() {
    if (_currentTable.activeTickets.isEmpty) {
      return 'Mesa #${_currentTable.tableNumber} - Consumo';
    }

    final List<String> waiterDetails = [];
    for (final t in _currentTable.activeTickets) {
      final name = t['waiter_name']?.toString() ?? 'Mesero';
      final isSupport = t['is_peer_support'] == true;
      final amt = (t['amount'] as num?)?.toDouble() ?? 0.0;
      final label = isSupport ? '$name (Apoyo)' : name;
      waiterDetails.add('$label: ${_formatCurrency(amt)}');
    }

    return 'Mesa #${_currentTable.tableNumber} - Consumo Consolidado [${waiterDetails.join(', ')}]';
  }

  void _showAddTicketDialog() {
    final currentUser = Supabase.instance.client.auth.currentUser;
    final currentUserId = currentUser?.id ?? 'waiter-default';
    final currentWaiterName = currentUser?.userMetadata?['display_name'] ?? 
        currentUser?.email?.split('@').first ?? 'Mesero';

    final amountCtrl = TextEditingController(text: '150.00');
    final conceptCtrl = TextEditingController(text: 'Mesa #${_currentTable.tableNumber} - Ronda');

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text('+ Añadir Ticket a Mesa #${_currentTable.tableNumber}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: conceptCtrl,
              decoration: const InputDecoration(labelText: 'Concepto / Consumo', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: amountCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Monto Estimado', prefixText: '\$ ', border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              final amt = double.tryParse(amountCtrl.text.trim()) ?? 0.0;
              widget.tableService.addTicketToTable(
                widget.zone.id,
                _currentTable.id,
                amount: amt,
                concept: conceptCtrl.text.trim(),
                waiterId: currentUserId,
                waiterName: currentWaiterName,
              );

              // Update local state
              final updatedList = widget.tableService.getTablesByZone(widget.zone.id);
              final updatedTable = updatedList.firstWhere((t) => t.id == _currentTable.id, orElse: () => _currentTable);

              setState(() {
                _currentTable = updatedTable;
              });

              widget.onTableUpdated?.call();
              Navigator.pop(dialogCtx);
            },
            child: const Text('Añadir Ticket'),
          ),
        ],
      ),
    );
  }

  void _proceedToConsolidatedCharge() {
    Navigator.pop(context);

    final conceptFinal = _buildConsolidatedConcept();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QuickChargeScreen(
          initialAmount: _totalTableAmount,
          initialConcept: conceptFinal,
          tableId: _currentTable.id,
          zoneId: widget.zone.id,
          tableService: widget.tableService,
          onPaymentSuccess: () {
            widget.onTableUpdated?.call();
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
    final waiterName = activeUser?.email?.split('@').first ?? 'Mesero';

    final List<Map<String, dynamic>> items = _currentTable.activeTickets.map((t) {
      return {
        'name': t['concept']?.toString() ?? 'Consumo',
        'quantity': 1,
        'price': (t['amount'] as num?)?.toDouble() ?? 0.0,
        'subtotal': (t['amount'] as num?)?.toDouble() ?? 0.0,
      };
    }).toList();

    final success = await printerService.printTablePreCheckTicket(
      tableName: 'Mesa #${_currentTable.tableNumber}',
      zoneName: widget.zone.name,
      waiterName: waiterName,
      items: items,
      totalAmount: _totalTableAmount,
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
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 16),

          // Table Status Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mesa #${_currentTable.tableNumber} (${widget.zone.name})',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      _currentTable.assignedWaiter != null
                          ? 'Mesero Titular: ${_currentTable.assignedWaiter}'
                          : 'Mesa Disponible',
                      style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.print_outlined, color: Colors.indigo),
                    tooltip: 'Imprimir Pre-cuenta',
                    onPressed: _printPreCheckTicket,
                  ),
                  const SizedBox(width: 4),
                  _buildStatusBadge(_currentTable.status),
                ],
              ),
            ],
          ),
          const Divider(height: 24),

          // Active Tickets List Grouped/Detailed by Waiter
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Tickets / Consumos Abiertos', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              if (_currentTable.activeTickets.isNotEmpty)
                Text(
                  '${_currentTable.activeTickets.length} comanda(s)',
                  style: TextStyle(fontSize: 12, color: Colors.blue[900], fontWeight: FontWeight.bold),
                ),
            ],
          ),
          const SizedBox(height: 8),

          _currentTable.activeTickets.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Center(
                    child: Text('No hay tickets abiertos en esta mesa', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                  ),
                )
              : Column(
                  children: _currentTable.activeTickets.map((ticket) {
                    final isPeerSupport = ticket['is_peer_support'] == true;
                    final ticketWaiter = ticket['waiter_name']?.toString() ?? 'Mesero';

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      elevation: 1,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isPeerSupport ? Colors.purple[50] : Colors.blue[50],
                          child: Icon(
                            isPeerSupport ? Icons.handshake : Icons.receipt,
                            color: isPeerSupport ? Colors.purple : Colors.blue,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          ticket['concept']?.toString() ?? 'Consumo Mesa',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        subtitle: Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 6,
                          children: [
                            Text('Atendido por: $ticketWaiter', style: const TextStyle(fontSize: 12)),
                            if (isPeerSupport)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(color: Colors.purple[100], borderRadius: BorderRadius.circular(4)),
                                child: const Text('APOYO', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.purple)),
                              ),
                          ],
                        ),
                        trailing: Text(
                          _formatCurrency((ticket['amount'] as num?)?.toDouble() ?? 0.0),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.green),
                        ),
                      ),
                    );
                  }).toList(),
                ),
          const Divider(height: 24),

          // Total General Banner
          if (_currentTable.activeTickets.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green[300]!),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('TOTAL GENERAL MESA:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.green)),
                  Text(
                    _formatCurrency(_totalTableAmount),
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 22, color: Colors.green[900]),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TableOrderDetailScreen(
                            zone: widget.zone,
                            table: _currentTable,
                            tableService: widget.tableService,
                            onTableUpdated: widget.onTableUpdated,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.restaurant_menu),
                    label: const FittedBox(
                      child: Text('TOMAR PEDIDO / DETALLE MESA', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo[800],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ),
              if (_currentTable.activeTickets.isNotEmpty) ...[
                const SizedBox(width: 10),
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: _proceedToConsolidatedCharge,
                      icon: const Icon(Icons.point_of_sale),
                      label: FittedBox(
                        child: Text(
                          'COBRAR (${_formatCurrency(_totalTableAmount)})',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[700],
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg;
    Color text;
    String label;

    switch (status) {
      case 'occupied':
        bg = Colors.orange[100]!;
        text = Colors.orange[900]!;
        label = 'Ocupada';
        break;
      case 'bill_requested':
        bg = Colors.blue[100]!;
        text = Colors.blue[900]!;
        label = 'Cuenta Pedida';
        break;
      case 'free':
      default:
        bg = Colors.green[100]!;
        text = Colors.green[900]!;
        label = 'Disponible';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: text)),
    );
  }
}

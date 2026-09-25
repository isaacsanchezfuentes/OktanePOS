import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:oktane_pos/providers/auth_provider.dart';
import '../../auth/services/rbac_service.dart';
import '../models/zone_model.dart';
import '../models/table_model.dart';
import '../services/table_service.dart';
import '../../charge/screens/quick_charge_screen.dart';

class TablesMapScreen extends StatefulWidget {
  final TableService? tableService;
  final RbacService? rbacService;

  const TablesMapScreen({
    super.key,
    this.tableService,
    this.rbacService,
  });

  @override
  State<TablesMapScreen> createState() => _TablesMapScreenState();
}

class _TablesMapScreenState extends State<TablesMapScreen> with SingleTickerProviderStateMixin {
  late final TableService _tableService;
  late final RbacService _rbacService;
  late TabController _tabController;

  List<ZoneModel> _zones = [];
  bool _isEditMode = false;

  @override
  void initState() {
    super.initState();
    _tableService = widget.tableService ?? TableService();
    _rbacService = widget.rbacService ?? RbacService();
    _zones = _tableService.getZones();
    _tabController = TabController(length: _zones.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _formatCurrency(double amount) {
    return NumberFormat.currency(locale: 'es_MX', symbol: '\$', decimalDigits: 2).format(amount);
  }

  Future<void> _toggleEditMode() async {
    final auth = context.read<AuthProvider>();
    final isManager = _rbacService.isManagerOrAdmin(auth.rol);

    if (_isEditMode) {
      setState(() => _isEditMode = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Coordenadas de mapa guardadas exitosamente')),
      );
      return;
    }

    if (isManager) {
      setState(() => _isEditMode = true);
    } else {
      final pinCtrl = TextEditingController();
      final formKey = GlobalKey<FormState>();

      final bool? granted = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.lock, color: Colors.indigo),
              SizedBox(width: 8),
              Text('PIN de Gerente Requerido', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('El modo edición gerencial (mover posiciones) requiere autorización de supervisor.'),
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
        setState(() => _isEditMode = true);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('❌ Acceso denegado: PIN de gerente requerido'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showTableTicketsBottomSheet(ZoneModel zone, RestaurantTableModel table) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final currentUser = Supabase.instance.client.auth.currentUser;
            final currentUserId = currentUser?.id ?? 'waiter-default';
            final currentWaiterName = currentUser?.userMetadata?['display_name'] ?? 
                currentUser?.email?.split('@').first ?? 'Mesero';

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
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Mesa #${table.tableNumber} (${zone.name})',
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            table.assignedWaiter != null
                                ? 'Mesero Asignado: ${table.assignedWaiter}'
                                : 'Mesa Disponible',
                            style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                          ),
                        ],
                      ),
                      _buildStatusBadge(table.status),
                    ],
                  ),
                  const Divider(height: 24),

                  // Active Tickets List
                  const Text('Tickets / Consumos Abiertos', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),

                  table.activeTickets.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                          child: Center(
                            child: Text('No hay tickets abiertos en esta mesa', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                          ),
                        )
                      : Column(
                          children: table.activeTickets.map((ticket) {
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
                  const SizedBox(height: 16),

                  // Bottom Action Buttons
                  Row(
                    children: [
                      // + Añadir Ticket Button
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final amountCtrl = TextEditingController(text: '150.00');
                            final conceptCtrl = TextEditingController(text: 'Mesa #${table.tableNumber} - Ronda');

                            final bool? created = await showDialog<bool>(
                              context: context,
                              builder: (dialogCtx) => AlertDialog(
                                title: Text('+ Añadir Ticket a Mesa #${table.tableNumber}'),
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
                                  TextButton(onPressed: () => Navigator.pop(dialogCtx, false), child: const Text('Cancelar')),
                                  ElevatedButton(
                                    onPressed: () {
                                      final amt = double.tryParse(amountCtrl.text.trim()) ?? 0.0;
                                      _tableService.addTicketToTable(
                                        zone.id,
                                        table.id,
                                        amount: amt,
                                        concept: conceptCtrl.text.trim(),
                                        waiterId: currentUserId,
                                        waiterName: currentWaiterName,
                                      );
                                      Navigator.pop(dialogCtx, true);
                                    },
                                    child: const Text('Añadir Ticket'),
                                  ),
                                ],
                              ),
                            );

                            if (created == true && mounted) {
                              Navigator.pop(context);
                              setState(() {});
                            }
                          },
                          icon: const Icon(Icons.add_shopping_cart),
                          label: const Text('+ AÑADIR TICKET'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Ir a Cobro Button
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const QuickChargeScreen()),
                            );
                          },
                          icon: const Icon(Icons.point_of_sale),
                          label: const Text('IR A COBRO'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green[700],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            );
          },
        );
      },
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

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildZoneCanvas(ZoneModel zone, List<RestaurantTableModel> tables) {
    return Column(
      children: [
        // Responsive Scrollable Legend Bar
        Container(
          width: double.infinity,
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Wrap(
              alignment: WrapAlignment.spaceEvenly,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 16.0,
              runSpacing: 4.0,
              children: [
                _buildLegendItem('Disponible', Colors.green[700]!),
                _buildLegendItem('Ocupada', Colors.orange[800]!),
                _buildLegendItem('Cuenta Pedida', Colors.blue[800]!),
              ],
            ),
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final canvasWidth = constraints.maxWidth;
              final canvasHeight = constraints.maxHeight;

              return Container(
                color: Colors.grey[100],
                child: Stack(
                  children: tables.map((table) {
                    final xPos = table.posX * canvasWidth;
                    final yPos = table.posY * canvasHeight;

                    return Positioned(
                      left: xPos.clamp(0.0, canvasWidth - 80),
                      top: yPos.clamp(0.0, canvasHeight - 80),
                      child: GestureDetector(
                        onPanUpdate: _isEditMode
                            ? (details) {
                                setState(() {
                                  final newX = (xPos + details.delta.dx) / canvasWidth;
                                  final newY = (yPos + details.delta.dy) / canvasHeight;
                                  _tableService.updateTablePosition(zone.id, table.id, newX, newY);
                                });
                              }
                            : null,
                        onTap: () {
                          if (!_isEditMode) {
                            _showTableTicketsBottomSheet(zone, table);
                          }
                        },
                        child: _buildTableCard(table),
                      ),
                    );
                  }).toList(),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTableCard(RestaurantTableModel table) {
    Color cardColor;
    Color borderColor;

    switch (table.status) {
      case 'occupied':
        cardColor = Colors.orange[50]!;
        borderColor = Colors.orange[400]!;
        break;
      case 'bill_requested':
        cardColor = Colors.blue[50]!;
        borderColor = Colors.blue[400]!;
        break;
      case 'free':
      default:
        cardColor = Colors.green[50]!;
        borderColor = Colors.green[400]!;
        break;
    }

    final double width = table.seats > 6 ? 90.0 : 75.0;
    final double height = table.seats > 6 ? 90.0 : 75.0;

    return Material(
      elevation: _isEditMode ? 4 : 2,
      borderRadius: BorderRadius.circular(table.shape == 'circle' ? 45 : 12),
      color: cardColor,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(table.shape == 'circle' ? 45 : 12),
          border: Border.all(color: borderColor, width: 2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Mesa ${table.tableNumber}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 2),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.people_outline, size: 12, color: Colors.blueGrey),
                Text('${table.seats}', style: const TextStyle(fontSize: 10, color: Colors.blueGrey)),
              ],
            ),
            if (table.activeTickets.isNotEmpty) ...[
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(color: Colors.blue[800], borderRadius: BorderRadius.circular(4)),
                child: Text(
                  '${table.activeTickets.length} Tkt',
                  style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.table_restaurant, color: Colors.blue),
              const SizedBox(width: 8),
              Text(
                _isEditMode ? 'Edición de Plano' : 'Distribución de Mesas',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(_isEditMode ? Icons.check_circle : Icons.edit_location_alt, color: _isEditMode ? Colors.green : Colors.indigo),
            tooltip: _isEditMode ? 'Guardar Cambios' : 'Modo Edición',
            onPressed: _toggleEditMode,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: false,
          tabs: _zones.map((z) => Tab(text: z.name)).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _zones.map((zone) {
          final tables = _tableService.getTablesByZone(zone.id);
          return _buildZoneCanvas(zone, tables);
        }).toList(),
      ),
    );
  }
}

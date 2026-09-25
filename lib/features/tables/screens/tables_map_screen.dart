import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:oktane_pos/providers/auth_provider.dart';
import '../../auth/services/rbac_service.dart';
import '../models/zone_model.dart';
import '../models/table_model.dart';
import '../services/table_service.dart';
import '../widgets/table_tickets_bottom_sheet.dart';
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
    _syncTablesData();
  }

  Future<void> _syncTablesData() async {
    await _tableService.fetchOrSeedSupabaseTables();
    if (mounted) {
      setState(() {});
    }
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
    TableTicketsBottomSheet.show(
      context,
      zone: zone,
      table: table,
      tableService: _tableService,
      onTableUpdated: () {
        _syncTablesData();
      },
    ).then((_) => _syncTablesData());
  }

  Widget _buildStatusBadge(String status) {
    Color bg;
    Color text;
    String label;

    switch (status.toLowerCase()) {
      case 'occupied':
        bg = Colors.orange[100]!;
        text = Colors.orange[900]!;
        label = 'Ocupada';
        break;
      case 'bill_requested':
      case 'billed':
        bg = Colors.blue[100]!;
        text = Colors.blue[900]!;
        label = 'Cuenta Pedida';
        break;
      case 'free':
      case 'available':
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

    switch (table.status.toLowerCase()) {
      case 'occupied':
        cardColor = Colors.orange[50]!;
        borderColor = Colors.orange[500]!;
        break;
      case 'bill_requested':
      case 'billed':
        cardColor = Colors.blue[50]!;
        borderColor = Colors.blue[500]!;
        break;
      case 'free':
      case 'available':
      default:
        cardColor = Colors.green[50]!;
        borderColor = Colors.green[500]!;
        break;
    }

    final double tableTotal = table.activeTickets.fold(0.0, (sum, t) => sum + ((t['amount'] as num?)?.toDouble() ?? 0.0));
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
            if (tableTotal > 0) ...[
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(color: Colors.orange[800], borderRadius: BorderRadius.circular(4)),
                child: Text(
                  _formatCurrency(tableTotal),
                  style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                ),
              ),
            ] else if (table.activeTickets.isNotEmpty) ...[
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

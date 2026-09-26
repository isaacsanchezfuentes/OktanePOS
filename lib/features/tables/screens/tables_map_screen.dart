import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:oktane_pos/providers/auth_provider.dart';
import '../../auth/services/rbac_service.dart';
import '../models/zone_model.dart';
import '../models/table_model.dart';
import '../services/table_service.dart';
import '../theme/table_theme.dart';
import '../widgets/table_tickets_bottom_sheet.dart';

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

  String? _getElapsedTimeLabel(RestaurantTableModel table) {
    if (table.status.toLowerCase() != 'occupied' || table.activeTickets.isEmpty) {
      return null;
    }
    final firstTicket = table.activeTickets.first;
    final createdAtStr = firstTicket['created_at']?.toString() ?? '';
    final firstTicketTime = DateTime.tryParse(createdAtStr) ?? DateTime.now();
    final diff = DateTime.now().difference(firstTicketTime);

    final minutes = diff.inMinutes;
    if (minutes < 60) {
      return '⏱️ ${minutes}m';
    } else {
      final hours = diff.inHours;
      final remMinutes = minutes % 60;
      return '⏱️ ${hours}h ${remMinutes}m';
    }
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

  Widget _buildLegendItem(String label, Color color, Color textColor) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: textColor)),
      ],
    );
  }

  Widget _buildZoneCanvas(ZoneModel zone, List<RestaurantTableModel> tables) {
    return Column(
      children: [
        // Responsive Scrollable Legend Bar - Toast/Slate Industrial Style
        Container(
          width: double.infinity,
          color: TableTheme.zoneBarBackground,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Wrap(
              alignment: WrapAlignment.spaceEvenly,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 16.0,
              runSpacing: 4.0,
              children: [
                _buildLegendItem('Disponible', TableTheme.freeBorder, TableTheme.freeText),
                _buildLegendItem('Ocupada', TableTheme.occupiedBorder, TableTheme.occupiedText),
                _buildLegendItem('Cuenta Pedida', TableTheme.billedBorder, TableTheme.billedText),
              ],
            ),
          ),
        ),
        const Divider(height: 1, color: Colors.black26),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final canvasWidth = constraints.maxWidth;
              final canvasHeight = constraints.maxHeight;

              return Container(
                color: TableTheme.floorBackground,
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
    Color textColor;

    switch (table.status.toLowerCase()) {
      case 'occupied':
        cardColor = TableTheme.occupiedBg;
        borderColor = TableTheme.occupiedBorder;
        textColor = TableTheme.occupiedText;
        break;
      case 'bill_requested':
      case 'billed':
        cardColor = TableTheme.billedBg;
        borderColor = TableTheme.billedBorder;
        textColor = TableTheme.billedText;
        break;
      case 'free':
      case 'available':
      default:
        cardColor = TableTheme.freeBg;
        borderColor = TableTheme.freeBorder;
        textColor = TableTheme.freeText;
        break;
    }

    final double tableTotal = table.activeTickets.fold(0.0, (sum, t) => sum + ((t['amount'] as num?)?.toDouble() ?? 0.0));
    final isStool = table.shape == 'circle' || table.shape == 'bar' || table.tableNumber >= 20;

    final double width = isStool ? 72.0 : (table.seats > 6 ? 90.0 : 78.0);
    final double height = isStool ? 72.0 : (table.seats > 6 ? 90.0 : 78.0);
    final borderRadius = BorderRadius.circular(isStool ? 36 : 10);

    final elapsedLabel = _getElapsedTimeLabel(table);
    final firstTicketTime = table.activeTickets.isNotEmpty
        ? (DateTime.tryParse(table.activeTickets.first['created_at']?.toString() ?? '') ?? DateTime.now())
        : DateTime.now();
    final isLongStay = DateTime.now().difference(firstTicketTime).inMinutes > 75;

    return Material(
      elevation: _isEditMode ? 6 : 3,
      borderRadius: borderRadius,
      color: cardColor,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: borderRadius,
          border: Border.all(color: borderColor, width: 2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              isStool ? 'B${table.tableNumber}' : 'Mesa ${table.tableNumber}',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: isStool ? 12 : 13, color: textColor),
            ),
            const SizedBox(height: 1),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('👥 ${table.seats}', style: const TextStyle(fontSize: 10, color: TableTheme.textSecondary, fontWeight: FontWeight.w600)),
              ],
            ),
            if (elapsedLabel != null) ...[
              const SizedBox(height: 1),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: const Color(0x40000000),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  elapsedLabel,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: isLongStay ? TableTheme.occupiedText : TableTheme.textSecondary,
                  ),
                ),
              ),
            ],
            if (tableTotal > 0) ...[
              const SizedBox(height: 1),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(color: TableTheme.occupiedBorder, borderRadius: BorderRadius.circular(4)),
                child: Text(
                  _formatCurrency(tableTotal),
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ] else if (table.activeTickets.isNotEmpty) ...[
              const SizedBox(height: 1),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(color: TableTheme.billedBorder, borderRadius: BorderRadius.circular(4)),
                child: Text(
                  '${table.activeTickets.length} Tkt',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
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
      backgroundColor: TableTheme.floorBackground,
      appBar: AppBar(
        backgroundColor: TableTheme.zoneBarBackground,
        foregroundColor: Colors.white,
        title: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.table_restaurant, color: TableTheme.occupiedBorder),
              const SizedBox(width: 8),
              Text(
                _isEditMode ? 'Edición de Plano' : 'Distribución de Mesas',
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(_isEditMode ? Icons.check_circle : Icons.edit_location_alt, color: _isEditMode ? TableTheme.freeBorder : TableTheme.occupiedBorder),
            tooltip: _isEditMode ? 'Guardar Cambios' : 'Modo Edición',
            onPressed: _toggleEditMode,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: false,
          labelColor: TableTheme.occupiedText,
          unselectedLabelColor: TableTheme.textSecondary,
          indicatorColor: TableTheme.occupiedBorder,
          tabs: _zones.map((z) => Tab(text: z.name)).toList(),
        ),
      ),
      body: ListenableBuilder(
        listenable: _tableService,
        builder: (context, _) {
          return TabBarView(
            controller: _tabController,
            children: _zones.map((zone) {
              final tables = _tableService.getTablesByZone(zone.id);
              return _buildZoneCanvas(zone, tables);
            }).toList(),
          );
        },
      ),
    );
  }
}

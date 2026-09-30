import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:oktane_pos/core/localization/app_locale.dart';
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
  final bool isSelectionMode;

  const TablesMapScreen({
    super.key,
    this.tableService,
    this.rbacService,
    this.isSelectionMode = false,
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
    if (mounted) setState(() {});
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

  String _generateUuidV4() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
  }

  Future<void> _toggleEditMode() async {
    final auth = context.read<AuthProvider>();
    final isManager = _rbacService.isManagerOrAdmin(auth.rol);

    if (_isEditMode) {
      final currentZone = _zones[_tabController.index];
      await _tableService.saveAllPositionsToSupabase(currentZone.id);

      setState(() => _isEditMode = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Plano de mesas guardado y sincronizado con éxito'),
            backgroundColor: Color(0xFF059669),
            duration: Duration(seconds: 2),
          ),
        );
      }
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
                const Text('La reconfiguración arquitectónica de mesas y barras requiere PIN supervisor.'),
                const SizedBox(height: 12),
                TextFormField(
                  controller: pinCtrl,
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  maxLength: 4,
                  decoration: const InputDecoration(labelText: 'PIN de Gerente', border: OutlineInputBorder()),
                  validator: (v) => (v == null || v.trim().length < 4) ? '4 dígitos requeridos' : null,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(tr('cancel'))),
            ElevatedButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                final isValid = await _rbacService.verifyManagerPin(pinCtrl.text.trim());
                if (ctx.mounted) Navigator.pop(ctx, isValid);
              },
              child: const Text('Desbloquear'),
            ),
          ],
        ),
      );

      if (granted == true && mounted) {
        setState(() => _isEditMode = true);
      }
    }
  }

  void _showAddElementSheet(ZoneModel zone) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Agregar al Plano', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.crop_square_rounded, color: Colors.blueAccent, size: 28),
                  title: const Text('Mesa Cuadrada / Rectangular', style: TextStyle(color: Colors.white)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _createNewElement(zone, shape: 'square', seats: 4);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.circle_outlined, color: Colors.greenAccent, size: 28),
                  title: const Text('Mesa Redonda', style: TextStyle(color: Colors.white)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _createNewElement(zone, shape: 'round', seats: 4);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.chair_alt_rounded, color: Colors.amberAccent, size: 28),
                  title: const Text('Banquillo', style: TextStyle(color: Colors.white)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _createNewElement(zone, shape: 'stool', seats: 1);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.view_stream_rounded, color: Colors.purpleAccent, size: 28),
                  title: const Text('Barra / Muro Arquitectónico', style: TextStyle(color: Colors.white)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _createNewElement(zone, shape: 'counter', seats: 0, isStructural: true);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _createNewElement(ZoneModel zone, {required String shape, required int seats, bool isStructural = false}) {
    final existingTables = _tableService.getTablesByZone(zone.id);
    int nextNumber = 1;
    if (existingTables.isNotEmpty) {
      final numbers = existingTables.map((t) => t.tableNumber).toList()..sort();
      nextNumber = numbers.last + 1;
    }

    final newId = _generateUuidV4();
    final String defaultLabel = isStructural
        ? 'MURO'
        : (shape == 'stool' ? 'Banquillo $nextNumber' : 'Mesa $nextNumber');

    final element = RestaurantTableModel(
      id: newId,
      zoneId: zone.id,
      tableNumber: isStructural ? 0 : nextNumber,
      label: defaultLabel,
      seats: seats,
      shape: shape,
      isStructural: isStructural,
      posX: 0.15,
      posY: 0.30,
      width: isStructural ? 0.55 : 0.14,
      height: isStructural ? 0.10 : 0.10,
    );

    _tableService.addTable(element);
  }

  // DIÁLOGO CON TÍTULOS EXTERNOS: CERO EMPALMES VISUALES
  void _showEditElementDialog(ZoneModel zone, RestaurantTableModel table) {
    final labelCtrl = TextEditingController(
      text: table.label ?? (table.isStructural ? 'MURO' : (table.shape == 'stool' ? 'Banquillo ${table.tableNumber}' : 'Mesa ${table.tableNumber}')),
    );
    int currentSeats = table.seats;
    String currentShape = table.shape;
    double currentWidth = table.width;
    double currentHeight = table.height;
    bool isVertical = currentHeight > currentWidth;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          titlePadding: const EdgeInsets.fromLTRB(22, 22, 22, 10),
          contentPadding: const EdgeInsets.fromLTRB(22, 10, 22, 16),
          title: const Row(
            children: [
              Icon(Icons.tune_rounded, color: Colors.lightBlueAccent, size: 22),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Propiedades del Elemento',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Etiqueta del campo fuera del TextField para evitar empalmes
                const Text(
                  'Etiqueta / Nombre:',
                  style: TextStyle(
                    color: Color(0xFF94A3B8),
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: labelCtrl,
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontWeight: FontWeight.w800,
                    fontSize: 14.5,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Ej. Mesa 1, Banquillo 1, MURO...',
                    hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFF38BDF8), width: 1.5),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFCBD5E1), width: 1.2),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFF0284C7), width: 2.0),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Selector de Forma Visual con título externo
                const Text(
                  'Forma Visual:',
                  style: TextStyle(
                    color: Color(0xFF94A3B8),
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: currentShape,
                  dropdownColor: Colors.white,
                  icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF0F172A)),
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFF38BDF8), width: 1.5),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFCBD5E1), width: 1.2),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFF0284C7), width: 2.0),
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'square', child: Text('Cuadrada / Rectangular', style: TextStyle(color: Color(0xFF0F172A)))),
                    DropdownMenuItem(value: 'round', child: Text('Redonda', style: TextStyle(color: Color(0xFF0F172A)))),
                    DropdownMenuItem(value: 'stool', child: Text('Banquillo', style: TextStyle(color: Color(0xFF0F172A)))),
                    DropdownMenuItem(value: 'counter', child: Text('Barra / Muro', style: TextStyle(color: Color(0xFF0F172A)))),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setModalState(() {
                        currentShape = val;
                        if (val == 'counter') {
                          currentWidth = isVertical ? 0.10 : 0.55;
                          currentHeight = isVertical ? 0.45 : 0.10;
                        }
                      });
                    }
                  },
                ),

                if (currentShape != 'round' && currentShape != 'stool') ...[
                  const SizedBox(height: 16),
                  const Text('Orientación / Giro:', style: TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.bold, fontSize: 12)),
                  const SizedBox(height: 6),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF334155)),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => setModalState(() {
                              isVertical = false;
                              if (currentHeight > currentWidth) {
                                final temp = currentWidth;
                                currentWidth = currentHeight;
                                currentHeight = temp;
                              }
                            }),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: !isVertical ? const Color(0xFF2563EB) : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.swap_horiz, size: 18, color: Colors.white),
                                  SizedBox(width: 6),
                                  Text('Horizontal', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12.5)),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: InkWell(
                            onTap: () => setModalState(() {
                              isVertical = true;
                              if (currentWidth > currentHeight) {
                                final temp = currentWidth;
                                currentWidth = currentHeight;
                                currentHeight = temp;
                              }
                            }),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: isVertical ? const Color(0xFF2563EB) : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.swap_vert, size: 18, color: Colors.white),
                                  SizedBox(width: 6),
                                  Text('Vertical', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12.5)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                if (currentShape != 'counter' && !table.isStructural) ...[
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Sillas / Capacidad:', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline, color: Colors.white70),
                            onPressed: currentSeats > 1 ? () => setModalState(() => currentSeats--) : null,
                          ),
                          Text('$currentSeats', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline, color: Colors.white70),
                            onPressed: currentSeats < 16 ? () => setModalState(() => currentSeats++) : null,
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton.icon(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              label: const Text('Eliminar', style: TextStyle(color: Colors.redAccent)),
              onPressed: () async {
                final deleted = await _tableService.deleteTable(zone.id, table.id);
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  if (!deleted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('⚠️ No se puede eliminar: tiene consumos pendientes'), backgroundColor: Colors.red),
                    );
                  }
                }
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB)),
              onPressed: () {
                final isStructuralElement = currentShape == 'counter';
                final updated = table.copyWith(
                  label: labelCtrl.text.trim(),
                  seats: isStructuralElement ? 0 : currentSeats,
                  shape: currentShape,
                  width: currentWidth,
                  height: currentHeight,
                  isStructural: isStructuralElement,
                );
                _tableService.updateTableElement(updated);
                Navigator.pop(ctx);
              },
              child: const Text('Guardar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _showTableTicketsBottomSheet(ZoneModel zone, RestaurantTableModel table) {
    TableTicketsBottomSheet.show(
      context,
      zone: zone,
      table: table,
      tableService: _tableService,
      onTableUpdated: () => _syncTablesData(),
    ).then((_) => _syncTablesData());
  }

  Widget _buildZoneCanvas(ZoneModel zone, List<RestaurantTableModel> tables) {
    return Column(
      children: [
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
                      left: xPos.clamp(0.0, canvasWidth - 40),
                      top: yPos.clamp(0.0, canvasHeight - 40),
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onPanUpdate: _isEditMode
                            ? (details) {
                                final deltaX = details.delta.dx / canvasWidth;
                                final deltaY = details.delta.dy / canvasHeight;
                                _tableService.updateTablePosition(
                                  zone.id,
                                  table.id,
                                  table.posX + deltaX,
                                  table.posY + deltaY,
                                );
                              }
                            : null,
                        onTap: () {
                          if (_isEditMode) {
                            _showEditElementDialog(zone, table);
                            return;
                          }
                          if (table.isStructural) return;

                          if (widget.isSelectionMode) {
                            Navigator.pop(context, {'table': table, 'zone': zone});
                          } else {
                            _showTableTicketsBottomSheet(zone, table);
                          }
                        },
                        child: _buildTableCard(table, canvasWidth, canvasHeight),
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

  Widget _buildTableCard(RestaurantTableModel table, double canvasWidth, double canvasHeight) {
    if (table.isStructural || table.shape == 'counter') {
      final bool isVertical = table.height > table.width;
      final double rawWidth = table.width * canvasWidth;
      final double rawHeight = table.height * canvasHeight;

      final double width = isVertical ? rawWidth.clamp(32.0, 72.0) : rawWidth.clamp(80.0, canvasWidth * 0.95);
      final double height = isVertical ? rawHeight.clamp(80.0, canvasHeight * 0.85) : rawHeight.clamp(32.0, 72.0);

      return Material(
        elevation: _isEditMode ? 6 : 2,
        borderRadius: BorderRadius.circular(8),
        color: const Color(0xFF334155),
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _isEditMode ? Colors.amberAccent : const Color(0xFF64748B), width: _isEditMode ? 1.8 : 1.2),
          ),
          alignment: Alignment.center,
          child: isVertical
              ? RotatedBox(
                  quarterTurns: 3,
                  child: Text(
                    table.label ?? 'BARRA PRINCIPAL',
                    style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1.2),
                  ),
                )
              : Text(
                  table.label ?? 'BARRA PRINCIPAL',
                  style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1.2),
                ),
        ),
      );
    }

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
    final isStool = table.shape == 'stool';
    final isRound = table.shape == 'round' || table.shape == 'circle';
    final bool isVertical = table.height > table.width;

    double width;
    double height;

    if (isStool) {
      width = 62.0;
      height = 62.0;
    } else if (isRound) {
      final s = table.seats > 4 ? 86.0 : 76.0;
      width = s;
      height = s;
    } else {
      final longSide = table.seats > 6 ? 94.0 : (table.seats > 4 ? 86.0 : 80.0);
      final shortSide = table.seats > 4 ? 80.0 : 76.0;
      width = isVertical ? shortSide : longSide;
      height = isVertical ? longSide : shortSide;
    }

    final borderRadius = BorderRadius.circular(isStool || isRound ? 45 : 10);
    final elapsedLabel = _getElapsedTimeLabel(table);
    final displayName = table.label ?? (isStool ? 'Banquillo ${table.tableNumber}' : 'Mesa ${table.tableNumber}');

    return Material(
      elevation: _isEditMode ? 6 : 3,
      borderRadius: borderRadius,
      color: cardColor,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: borderRadius,
          border: Border.all(color: _isEditMode ? Colors.amberAccent : borderColor, width: _isEditMode ? 2.2 : 2.0),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2.0),
              child: Text(
                displayName,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: isStool ? 9.5 : 12.0, color: textColor),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (!isStool) ...[
              const SizedBox(height: 1),
              Text('👥 ${table.seats}', style: const TextStyle(fontSize: 10, color: TableTheme.textSecondary, fontWeight: FontWeight.w600)),
            ],
            if (elapsedLabel != null && !isStool) ...[
              const SizedBox(height: 1),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(color: const Color(0x40000000), borderRadius: BorderRadius.circular(4)),
                child: Text(elapsedLabel, style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: TableTheme.occupiedText)),
              ),
            ],
            if (tableTotal > 0) ...[
              const SizedBox(height: 1),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(color: TableTheme.occupiedBorder, borderRadius: BorderRadius.circular(4)),
                child: Text(
                  _formatCurrency(tableTotal),
                  style: const TextStyle(color: Colors.black, fontSize: 8.5, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color, Color textColor) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: textColor)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        _tableService,
        AppLocale.instance,
      ]),
      builder: (context, _) {
        final titleText = _isEditMode ? 'Editor de Plano' : 'Distribución de Mesas';

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
                  Text(titleText, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                ],
              ),
            ),
            actions: [
              if (!widget.isSelectionMode)
                IconButton(
                  icon: Icon(
                    _isEditMode ? Icons.check_circle : Icons.edit_location_alt,
                    color: _isEditMode ? TableTheme.freeBorder : TableTheme.occupiedBorder,
                  ),
                  tooltip: _isEditMode ? 'Guardar' : 'Modo Edición',
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
          floatingActionButton: _isEditMode
              ? FloatingActionButton.extended(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  icon: const Icon(Icons.add),
                  label: const Text('Nuevo Elemento'),
                  onPressed: () => _showAddElementSheet(_zones[_tabController.index]),
                )
              : null,
          body: TabBarView(
            controller: _tabController,
            physics: _isEditMode ? const NeverScrollableScrollPhysics() : const BouncingScrollPhysics(),
            children: _zones.map((zone) {
              final tables = _tableService.getTablesByZone(zone.id);
              return _buildZoneCanvas(zone, tables);
            }).toList(),
          ),
        );
      },
    );
  }
}
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'package:oktane_pos/providers/auth_provider.dart';
import 'package:oktane_pos/features/printer/services/thermal_printer_service.dart';
import '../models/charge_model.dart';
import '../services/charge_service.dart';
import '../widgets/payment_method_bottom_sheet.dart';
import '../../auth/services/rbac_service.dart';
import '../../auth/widgets/print_authorization_dialog.dart';
import '../../tables/services/table_service.dart';
import 'package:oktane_pos/features/tables/models/zone_model.dart';
import 'package:oktane_pos/features/tables/models/table_model.dart';
import 'package:oktane_pos/features/tables/screens/table_order_detail_screen.dart';

class ChargesHistoryScreen extends StatefulWidget {
  final ChargeService? chargeService;

  const ChargesHistoryScreen({
    super.key,
    this.chargeService,
  });

  @override
  State<ChargesHistoryScreen> createState() => _ChargesHistoryScreenState();
}

class _ChargesHistoryScreenState extends State<ChargesHistoryScreen> {
  late final ChargeService _chargeService;
  final RbacService _rbacService = RbacService();
  final TableService _tableService = TableService();
  late final DateTime _listeningSince;
  final Set<String> _knownPaidIds = {};
  bool _initialLoadCompleted = false;
  String _selectedStatusFilter = 'all'; // 'all', 'pending', 'paid'

  void _openTableOrderDetailForPendingCharge(ChargeModel charge) {
    final zones = _tableService.getZones();
    ZoneModel targetZone = zones.first;
    RestaurantTableModel targetTable = _tableService.getTablesByZone(targetZone.id).first;

    final concept = charge.concept;
    final match = RegExp(r'Mesa\s*#?(\d+)').firstMatch(concept);
    if (match != null) {
      final tableNum = int.tryParse(match.group(1) ?? '') ?? 1;
      for (final z in zones) {
        final tables = _tableService.getTablesByZone(z.id);
        for (final t in tables) {
          if (t.tableNumber == tableNum) {
            targetZone = z;
            targetTable = t;
            break;
          }
        }
      }
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TableOrderDetailScreen(
          zone: targetZone,
          table: targetTable,
          tableService: _tableService,
          onTableUpdated: () {
            setState(() {});
          },
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _listeningSince = DateTime.now().toUtc();
    _chargeService = widget.chargeService ?? ChargeService();
  }

  void _checkRealtimePaymentUpdates(List<ChargeModel> charges) {
    if (!_initialLoadCompleted) {
      for (final charge in charges) {
        if (charge.id != null && charge.status == 'paid') {
          _knownPaidIds.add(charge.id!);
        }
      }
      _initialLoadCompleted = true;
      return;
    }

    for (final charge in charges) {
      if (charge.id != null && charge.status == 'paid') {
        if (!_knownPaidIds.contains(charge.id)) {
          final eventTime = charge.effectiveTimestamp.toUtc();
          final isNewTransition = eventTime.isAfter(_listeningSince.subtract(const Duration(seconds: 3)));

          _knownPaidIds.add(charge.id!);

          if (isNewTransition && mounted) {
            final folio = charge.id!.length >= 4 
                ? charge.id!.substring(0, 4).toUpperCase() 
                : charge.id!;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Text('💰 ', style: TextStyle(fontSize: 20)),
                      Expanded(
                        child: Text(
                          '¡Cobro #$folio pagado exitosamente! \$${charge.amount.toStringAsFixed(2)} MXN',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  backgroundColor: Colors.green[800],
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 4),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              );
            });
          }
        }
      }
    }
  }

  String _formatCurrency(double amount) {
    return NumberFormat.currency(locale: 'es_MX', symbol: '\$', decimalDigits: 2).format(amount);
  }

  String _formatTime(DateTime? dt) {
    if (dt == null) return '--:--';
    return DateFormat('HH:mm').format(dt);
  }

  Future<void> _updateStatus(ChargeModel charge, String newStatus) async {
    if (charge.id == null) return;

    try {
      await _chargeService.updateChargeStatus(charge.id!, newStatus);
      if (mounted) {
        final statusLabel = newStatus == 'paid' ? 'Pagado' : 'Cancelado';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Cobro marcado como $statusLabel'),
            backgroundColor: newStatus == 'paid' ? Colors.green[700] : Colors.red[700],
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al actualizar estado: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _settlePendingCharge(ChargeModel charge) async {
    if (charge.id == null) return;

    final resultCharge = await PaymentMethodBottomSheet.show(
      context,
      amount: charge.amount,
      concept: charge.concept,
      chargeService: _chargeService,
    );

    if (resultCharge != null && mounted) {
      await _chargeService.updateChargeStatusAndMethod(
        charge.id!,
        'paid',
        paymentMethod: resultCharge.paymentMethod,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Ticket #${charge.id!.length >= 4 ? charge.id!.substring(0, 4).toUpperCase() : charge.id} cobrado exitosamente'),
            backgroundColor: Colors.green[700],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = Supabase.instance.client.auth.currentUser?.id ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de Cobros', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 1,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {});
        },
        child: StreamBuilder<List<ChargeModel>>(
          stream: _chargeService.getTodayChargesStream(userId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final charges = snapshot.data ?? [];
            _checkRealtimePaymentUpdates(charges);

            final totalPaid = charges
                .where((c) => c.status == 'paid')
                .fold(0.0, (sum, c) => sum + c.amount);

            final pendingCount = charges.where((c) => c.status == 'pending').length;

            final filteredCharges = charges.where((c) {
              if (_selectedStatusFilter == 'pending') return c.status == 'pending';
              if (_selectedStatusFilter == 'paid') return c.status == 'paid';
              return true;
            }).toList();

            return Column(
              children: [
                // Summary Header
                _buildSummaryHeader(totalPaid, pendingCount),

                // Status Filter Bar
                _buildFilterBar(),

                // List of Charges
                Expanded(
                  child: filteredCharges.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            SizedBox(height: MediaQuery.of(context).size.height * 0.15),
                            _buildEmptyState(),
                          ],
                        )
                      : ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          itemCount: filteredCharges.length,
                          itemBuilder: (context, index) {
                            final charge = filteredCharges[index];
                            final folio = filteredCharges.length - index;
                            return _buildChargeCard(charge, folio);
                          },
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildFilterBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 2.0),
      child: Row(
        children: [
          FilterChip(
            label: const Text('Todos', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            selected: _selectedStatusFilter == 'all',
            selectedColor: Colors.blue[100],
            onSelected: (val) {
              if (val) setState(() => _selectedStatusFilter = 'all');
            },
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: const Text('Pendientes', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            selected: _selectedStatusFilter == 'pending',
            selectedColor: Colors.orange[100],
            onSelected: (val) {
              if (val) setState(() => _selectedStatusFilter = 'pending');
            },
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: const Text('Pagados', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            selected: _selectedStatusFilter == 'paid',
            selectedColor: Colors.green[100],
            onSelected: (val) {
              if (val) setState(() => _selectedStatusFilter = 'paid');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryHeader(double totalPaid, int pendingCount) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total Cobrado Hoy',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatCurrency(totalPaid),
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[800],
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: 40,
            width: 1,
            color: Colors.grey[300],
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pendientes',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '$pendingCount',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: pendingCount > 0 ? Colors.orange[800] : Colors.grey[700],
                        ),
                      ),
                      const SizedBox(width: 6),
                      if (pendingCount > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.orange[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Por cobrar',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange[900],
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_outlined, size: 70, color: Colors.grey[400]),
          const SizedBox(height: 12),
          Text(
            'No hay cobros registrados hoy',
            style: TextStyle(fontSize: 16, color: Colors.grey[600], fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 4),
          Text(
            'Los cobros creados en el teclado aparecerán aquí',
            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildChargeCard(ChargeModel charge, int folio) {
    final isPending = charge.status == 'pending';

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: isPending ? () => _openTableOrderDetailForPendingCharge(charge) : null,
      child: Card(
        elevation: isPending ? 3 : 2,
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: isPending ? BorderSide(color: Colors.orange[300]!, width: 1.5) : BorderSide.none,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row: Folio, Time, Status Chip
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '#${charge.id != null && charge.id!.length >= 4 ? charge.id!.substring(0, 4).toUpperCase() : folio}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatTime(charge.createdAt),
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.print_outlined, size: 20),
                        tooltip: 'Reimprimir Ticket',
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        onPressed: () async {
                          final auth = context.read<AuthProvider>();
                          final userId = Supabase.instance.client.auth.currentUser?.id ?? '';
                          final isWaiter = _rbacService.isWaiter(auth.rol);

                          if (isWaiter) {
                            final authorized = await PrintAuthorizationDialog.show(
                              context,
                              waiterId: userId,
                              amount: charge.amount,
                              rbacService: _rbacService,
                            );
                            if (!authorized) return;
                          }

                          final success = await ThermalPrinterService().printChargeTicket(charge);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  success 
                                      ? '✅ Ticket enviado a impresora' 
                                      : '⚠️ No se pudo imprimir (verifique impresora)',
                                ),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          }
                        },
                      ),
                      const SizedBox(width: 4),
                      _buildStatusChip(charge.status),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Middle Row: Amount, Concept, Payment Method (Only show payment method if paid)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _formatCurrency(charge.amount),
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          charge.concept,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.blueGrey[800],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (!isPending) _buildMethodBadge(charge.paymentMethod),
                ],
              ),

              // Bottom Actions (if pending)
              if (isPending) ...[
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => _updateStatus(charge, 'cancelled'),
                      icon: const Icon(Icons.cancel_outlined, size: 16, color: Colors.red),
                      label: const Text('Cancelar', style: TextStyle(color: Colors.red, fontSize: 13)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () => _settlePendingCharge(charge),
                      icon: const Icon(Icons.point_of_sale, size: 16),
                      label: const Text('COBRAR CUENTA', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[700],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color backgroundColor;
    Color textColor;
    String label;

    switch (status.toLowerCase()) {
      case 'paid':
        backgroundColor = Colors.green[100]!;
        textColor = Colors.green[900]!;
        label = 'Pagado';
        break;
      case 'cancelled':
        backgroundColor = Colors.red[100]!;
        textColor = Colors.red[900]!;
        label = 'Cancelado';
        break;
      case 'pending':
      default:
        backgroundColor = Colors.orange[100]!;
        textColor = Colors.orange[900]!;
        label = 'Pendiente';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildMethodBadge(String method) {
    IconData icon;
    String label;

    switch (method.toLowerCase()) {
      case 'tarjeta':
        icon = Icons.contactless_outlined;
        label = 'Tarjeta';
        break;
      case 'qr':
        icon = Icons.qr_code_2_outlined;
        label = 'QR';
        break;
      case 'efectivo':
      default:
        icon = Icons.payments_outlined;
        label = 'Efectivo';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.blueGrey[700]),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.blueGrey[800],
            ),
          ),
        ],
      ),
    );
  }
}

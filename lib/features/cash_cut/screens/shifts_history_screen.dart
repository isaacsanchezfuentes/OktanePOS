import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/shift_model.dart';
import '../models/cash_cut_model.dart';
import '../services/shift_service.dart';
import '../../printer/services/thermal_printer_service.dart';

class ShiftsHistoryScreen extends StatefulWidget {
  final ShiftService? shiftService;
  final ThermalPrinterService? printerService;

  const ShiftsHistoryScreen({
    super.key,
    this.shiftService,
    this.printerService,
  });

  @override
  State<ShiftsHistoryScreen> createState() => _ShiftsHistoryScreenState();
}

class _ShiftsHistoryScreenState extends State<ShiftsHistoryScreen> {
  late final ShiftService _shiftService;
  late final ThermalPrinterService _printerService;

  List<ShiftModel> _shifts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _shiftService = widget.shiftService ?? ShiftService();
    _printerService = widget.printerService ?? ThermalPrinterService();
    _loadShiftsHistory();
  }

  Future<void> _loadShiftsHistory() async {
    setState(() => _isLoading = true);

    try {
      final userId = Supabase.instance.client.auth.currentUser?.id ?? '';
      final list = await _shiftService.getClosedShifts(userId);

      if (mounted) {
        setState(() {
          _shifts = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error cargando historial de turnos: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  String _formatCurrency(double val) {
    return NumberFormat.currency(locale: 'es_MX', symbol: '\$', decimalDigits: 2).format(val);
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return '--/--/---- --:--';
    return DateFormat('dd/MM/yyyy HH:mm').format(dt);
  }

  Future<void> _reprintShiftTicket(ShiftModel shift) async {
    final userEmail = Supabase.instance.client.auth.currentUser?.email ?? 'Cajero Default';

    final summary = CashCutSummaryModel(
      totalCollected: shift.totalSales,
      totalCash: shift.cashSales,
      totalCard: shift.cardSales,
      totalQr: shift.qrSales,
      totalTransactions: 0,
      pendingTransactions: 0,
      averageTicket: 0.0,
      userId: shift.userId,
    );

    bool success = false;
    try {
      success = await _printerService.printCashCutTicket(
        summary: summary,
        initialFloat: shift.initialCash,
        countedCash: shift.drawerCounted,
        difference: shift.difference,
        cashierName: userEmail,
      );
    } catch (e) {
      debugPrint('⚠️ Error en re-impresión de Corte Z: $e');
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success 
                ? '✅ Re-impresión de Corte Z enviada exitosamente' 
                : '⚠️ No se pudo enviar a la impresora (Verifique conexión)',
          ),
          backgroundColor: success ? Colors.green[700] : Colors.orange[800],
        ),
      );
    }
  }

  void _showShiftDetailModal(ShiftModel shift) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Detalle Turno #${shift.shiftNumber ?? '---'}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  if (shift.isModified)
                    Chip(
                      avatar: const Icon(Icons.verified, size: 14, color: Colors.purple),
                      label: const Text('AUDITADO / MODIFICADO', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.purple)),
                      backgroundColor: Colors.purple[50],
                      side: BorderSide(color: Colors.purple[200]!),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              _buildDetailRow('Apertura:', _formatDate(shift.openedAt)),
              _buildDetailRow('Cierre:', _formatDate(shift.closedAt)),
              const Divider(height: 20),
              _buildDetailRow('Fondo Inicial:', _formatCurrency(shift.initialCash)),
              _buildDetailRow('Ventas Efectivo:', _formatCurrency(shift.cashSales)),
              _buildDetailRow('Ventas Tarjeta:', _formatCurrency(shift.cardSales)),
              _buildDetailRow('Ventas QR:', _formatCurrency(shift.qrSales)),
              const Divider(height: 20),
              _buildDetailRow('Ventas Totales:', _formatCurrency(shift.totalSales), isBold: true),
              _buildDetailRow('Efectivo Contado:', _formatCurrency(shift.drawerCounted), isBold: true),
              _buildDetailRow('Diferencia:', _formatCurrency(shift.difference), isBold: true),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _reprintShiftTicket(shift);
                },
                icon: const Icon(Icons.print_outlined),
                label: const Text('REIMPRIMIR CORTE Z', style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo[800],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 13, color: Colors.grey[700])),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: isBold ? Colors.black87 : Colors.grey[900],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial y Auditoría de Turnos', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar',
            onPressed: _loadShiftsHistory,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _shifts.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _shifts.length,
                  itemBuilder: (context, index) {
                    final shift = _shifts[index];
                    return _buildShiftCard(shift);
                  },
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_toggle_off, size: 70, color: Colors.grey[400]),
          const SizedBox(height: 12),
          const Text(
            'No hay turnos cerrados registrados',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'Los cierres Z aparecerán aquí tras realizar corte de caja',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildShiftCard(ShiftModel shift) {
    Color diffColor = Colors.green[700]!;
    String diffText = 'Cuadre Exacto (\$0.00)';

    if (shift.difference > 0) {
      diffColor = Colors.blue[800]!;
      diffText = 'Sobrante +${_formatCurrency(shift.difference)}';
    } else if (shift.difference < 0) {
      diffColor = Colors.red[700]!;
      diffText = 'Faltante -${_formatCurrency(shift.difference.abs())}';
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => _showShiftDetailModal(shift),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row: Turno #, Dates & Audit Badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.indigo[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.indigo[200]!),
                        ),
                        child: Text(
                          'Turno #${shift.shiftNumber ?? '---'}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.indigo),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatDate(shift.closedAt),
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  if (shift.isModified)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.purple[50],
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.purple[200]!),
                      ),
                      child: const Text(
                        'AUDITADO',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.purple),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),

              // Total Sales
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatCurrency(shift.totalSales),
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: diffColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      diffText,
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: diffColor),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Compact Breakdown
              Row(
                children: [
                  _buildCompactChip('Efectivo', shift.cashSales, Colors.green),
                  const SizedBox(width: 6),
                  _buildCompactChip('Tarjeta', shift.cardSales, Colors.blue),
                  const SizedBox(width: 6),
                  _buildCompactChip('QR', shift.qrSales, Colors.purple),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompactChip(String label, double val, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.06),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Column(
          children: [
            Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[700])),
            const SizedBox(height: 2),
            FittedBox(
              child: Text(
                _formatCurrency(val),
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

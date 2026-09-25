import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/cash_cut_model.dart';
import '../models/shift_model.dart';
import '../services/shift_service.dart';
import '../services/shift_policy_service.dart';
import '../../printer/services/thermal_printer_service.dart';

class CashCalendarScreen extends StatefulWidget {
  final ShiftService? shiftService;
  final ShiftPolicyService? policyService;
  final ThermalPrinterService? printerService;

  const CashCalendarScreen({
    super.key,
    this.shiftService,
    this.policyService,
    this.printerService,
  });

  @override
  State<CashCalendarScreen> createState() => _CashCalendarScreenState();
}

class _CashCalendarScreenState extends State<CashCalendarScreen> {
  late final ShiftService _shiftService;
  late final ShiftPolicyService _policyService;
  late final ThermalPrinterService _printerService;

  DateTime _focusedMonth = DateTime.now();
  Map<int, CashCutSummaryModel> _dailySummaries = {};
  List<ShiftModel> _monthShifts = [];
  bool _isLoading = true;
  int _currentPolicyMode = 1;

  @override
  void initState() {
    super.initState();
    _shiftService = widget.shiftService ?? ShiftService();
    _policyService = widget.policyService ?? ShiftPolicyService();
    _printerService = widget.printerService ?? ThermalPrinterService();
    _loadCalendarData();
  }

  Future<void> _loadCalendarData() async {
    setState(() => _isLoading = true);

    try {
      final userId = Supabase.instance.client.auth.currentUser?.id ?? '';
      final mode = await _policyService.getPolicyMode();

      final startOfMonth = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
      final endOfMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0, 23, 59, 59);

      // 1. Fetch Month Charges
      final List<dynamic> rawCharges = await Supabase.instance.client
          .from('charges')
          .select()
          .eq('user_id', userId)
          .gte('created_at', startOfMonth.toIso8601String())
          .lte('created_at', endOfMonth.toIso8601String());

      final Map<int, List<dynamic>> groupedByDay = {};
      for (final item in rawCharges) {
        final dt = DateTime.tryParse(item['created_at']?.toString() ?? '');
        if (dt != null && dt.month == _focusedMonth.month) {
          groupedByDay.putIfAbsent(dt.day, () => []).add(item);
        }
      }

      final Map<int, CashCutSummaryModel> summaries = {};
      groupedByDay.forEach((day, list) {
        summaries[day] = CashCutSummaryModel.fromCharges(list, userId);
      });

      // 2. Fetch Month Closed Shifts
      final List<ShiftModel> closedShifts = await _shiftService.getClosedShifts(userId);
      final monthShifts = closedShifts.where((s) {
        final date = s.closedAt ?? s.openedAt;
        return date.year == _focusedMonth.year && date.month == _focusedMonth.month;
      }).toList();

      if (mounted) {
        setState(() {
          _dailySummaries = summaries;
          _monthShifts = monthShifts;
          _currentPolicyMode = mode;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error cargando datos del calendario: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  String _formatCompactCurrency(double amount) {
    if (amount <= 0) return '-';
    final formatter = NumberFormat.compactCurrency(locale: 'es_MX', symbol: '\$');
    return formatter.format(amount);
  }

  String _formatFullCurrency(double amount) {
    return NumberFormat.currency(locale: 'es_MX', symbol: '\$', decimalDigits: 2).format(amount);
  }

  void _changeMonth(int increment) {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + increment, 1);
    });
    _loadCalendarData();
  }

  void _showPolicySettingsDialog() {
    int tempMode = _currentPolicyMode;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.tune, color: Colors.blue),
              SizedBox(width: 8),
              Text('Política de Turnos Diarios', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RadioListTile<int>(
                title: const Text('Modo 1: 1 Turno por día (Default)'),
                subtitle: const Text('Máximo un cierre de caja diario'),
                value: 1,
                groupValue: tempMode,
                onChanged: (val) => setModalState(() => tempMode = val!),
              ),
              RadioListTile<int>(
                title: const Text('Modo 2: Hasta 3 Turnos por día'),
                subtitle: const Text('Para negocios con cambios de turno en mañana, tarde y noche'),
                value: 2,
                groupValue: tempMode,
                onChanged: (val) => setModalState(() => tempMode = val!),
              ),
              RadioListTile<int>(
                title: const Text('Modo 3: Turnos Libres / Manuales'),
                subtitle: const Text('Aperturas y cierres sin límite horario definido por el dueño'),
                value: 3,
                groupValue: tempMode,
                onChanged: (val) => setModalState(() => tempMode = val!),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                await _policyService.setPolicyMode(tempMode);
                if (mounted) {
                  setState(() => _currentPolicyMode = tempMode);
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('✅ ${_policyService.getModeDescription(tempMode)}'),
                      backgroundColor: Colors.green[700],
                    ),
                  );
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }

  String _formatMonthTitle(DateTime date) {
    try {
      return DateFormat('MMMM yyyy', 'es_MX').format(date);
    } catch (_) {
      try {
        return DateFormat('MMMM yyyy', 'es').format(date);
      } catch (_) {
        return DateFormat('MMMM yyyy').format(date);
      }
    }
  }

  String _formatDateHeader(DateTime date) {
    try {
      return DateFormat('EEEE d MMMM, yyyy', 'es_MX').format(date);
    } catch (_) {
      try {
        return DateFormat('EEEE d MMMM, yyyy', 'es').format(date);
      } catch (_) {
        return DateFormat('EEEE d MMMM, yyyy').format(date);
      }
    }
  }

  void _showDaySummaryBottomSheet(int day) {
    final selectedDate = DateTime(_focusedMonth.year, _focusedMonth.month, day);
    final summary = _dailySummaries[day];
    final dateFormatted = _formatDateHeader(selectedDate);

    final dayShifts = _monthShifts.where((s) {
      final date = s.closedAt ?? s.openedAt;
      return date.year == selectedDate.year && date.month == selectedDate.month && date.day == selectedDate.day;
    }).toList();

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
              Text(
                dateFormatted.toUpperCase(),
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.blue),
              ),
              const SizedBox(height: 8),

              // Total Sales Highlight Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Column(
                  children: [
                    const Text('Total Vendido del Día', style: TextStyle(fontSize: 12, color: Colors.blue)),
                    const SizedBox(height: 4),
                    Text(
                      _formatFullCurrency(summary?.totalCollected ?? 0.0),
                      style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.blue),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Breakdown Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildDayBreakdownItem('Efectivo', summary?.totalCash ?? 0.0, Colors.green),
                  _buildDayBreakdownItem('Tarjeta', summary?.totalCard ?? 0.0, Colors.blue),
                  _buildDayBreakdownItem('QR', summary?.totalQr ?? 0.0, Colors.purple),
                  _buildDayBreakdownItem('Cobros', (summary?.totalTransactions ?? 0).toDouble(), Colors.black87, isCount: true),
                ],
              ),
              const Divider(height: 24),

              // Shifts List for this day
              const Text('Cierres de Caja de la Fecha', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),

              dayShifts.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12.0),
                      child: Text('No hay cierres Z registrados en esta fecha', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                    )
                  : Column(
                      children: dayShifts.map((shift) {
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            dense: true,
                            title: Text('Turno #${shift.shiftNumber ?? '---'}', style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('Total: ${_formatFullCurrency(shift.totalSales)}'),
                            trailing: OutlinedButton.icon(
                              onPressed: () async {
                                final userEmail = Supabase.instance.client.auth.currentUser?.email ?? 'Cajero Default';
                                final shiftSummary = CashCutSummaryModel(
                                  totalCollected: shift.totalSales,
                                  totalCash: shift.cashSales,
                                  totalCard: shift.cardSales,
                                  totalQr: shift.qrSales,
                                  totalTransactions: 0,
                                  pendingTransactions: 0,
                                  averageTicket: 0.0,
                                  userId: shift.userId,
                                );
                                try {
                                  await _printerService.printCashCutTicket(
                                    summary: shiftSummary,
                                    initialFloat: shift.initialCash,
                                    countedCash: shift.drawerCounted,
                                    difference: shift.difference,
                                    cashierName: userEmail,
                                  );
                                } catch (_) {}
                              },
                              icon: const Icon(Icons.print_outlined, size: 14),
                              label: const Text('Reimprimir', style: TextStyle(fontSize: 11)),
                            ),
                          ),
                        );
                      }).toList(),
                    ),

              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDayBreakdownItem(String label, double val, Color color, {bool isCount = false}) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
        const SizedBox(height: 2),
        Text(
          isCount ? '${val.toInt()}' : _formatFullCurrency(val),
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final monthTitle = _formatMonthTitle(_focusedMonth);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendario de Ventas', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune),
            tooltip: 'Política de Turnos',
            onPressed: _showPolicySettingsDialog,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar',
            onPressed: _loadCalendarData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Month Header Selector
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  color: Colors.grey[100],
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left),
                        onPressed: () => _changeMonth(-1),
                      ),
                      Text(
                        monthTitle.toUpperCase(),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right),
                        onPressed: () => _changeMonth(1),
                      ),
                    ],
                  ),
                ),

                // Weekday Headers
                Container(
                  color: Colors.grey[200],
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: const Row(
                    children: [
                      Expanded(child: Center(child: Text('Dom', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)))),
                      Expanded(child: Center(child: Text('Lun', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)))),
                      Expanded(child: Center(child: Text('Mar', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)))),
                      Expanded(child: Center(child: Text('Mié', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)))),
                      Expanded(child: Center(child: Text('Jue', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)))),
                      Expanded(child: Center(child: Text('Vie', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)))),
                      Expanded(child: Center(child: Text('Sáb', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)))),
                    ],
                  ),
                ),

                // Airline Flight-Style Grid
                Expanded(
                  child: _buildAirlineCalendarGrid(),
                ),
              ],
            ),
    );
  }

  Widget _buildAirlineCalendarGrid() {
    final daysInMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0).day;
    final firstWeekday = DateTime(_focusedMonth.year, _focusedMonth.month, 1).weekday % 7; // 0 = Sunday

    final totalCells = firstWeekday + daysInMonth;

    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 0.85,
        crossAxisSpacing: 6,
        mainAxisSpacing: 6,
      ),
      itemCount: totalCells,
      itemBuilder: (context, index) {
        if (index < firstWeekday) {
          return const SizedBox.shrink();
        }

        final day = index - firstWeekday + 1;
        final summary = _dailySummaries[day];
        final totalAmount = summary?.totalCollected ?? 0.0;
        final hasSales = totalAmount > 0;

        final isToday = DateTime.now().year == _focusedMonth.year &&
            DateTime.now().month == _focusedMonth.month &&
            DateTime.now().day == day;

        return Material(
          color: hasSales ? Colors.blue[50] : Colors.grey[50],
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            onTap: () => _showDaySummaryBottomSheet(day),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isToday
                      ? Colors.blue[800]!
                      : hasSales
                          ? Colors.blue[200]!
                          : Colors.grey[300]!,
                  width: isToday ? 2 : 1,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Day Number
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '$day',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isToday || hasSales ? FontWeight.bold : FontWeight.normal,
                          color: isToday ? Colors.blue[900] : Colors.black87,
                        ),
                      ),
                      if (isToday)
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.circle),
                        ),
                    ],
                  ),

                  // Sales Amount
                  Center(
                    child: FittedBox(
                      child: Text(
                        _formatCompactCurrency(totalAmount),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: hasSales ? FontWeight.bold : FontWeight.normal,
                          color: hasSales ? Colors.blue[900] : Colors.grey[400],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

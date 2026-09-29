import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:oktane_pos/core/localization/app_locale.dart';
import '../models/cash_cut_model.dart';
import '../models/shift_model.dart';
import '../services/cash_cut_service.dart';
import '../services/shift_service.dart';
import '../../printer/services/thermal_printer_service.dart';
import 'shifts_history_screen.dart';
import 'cash_calendar_screen.dart';

class CashCutScreen extends StatefulWidget {
  final CashCutService? cashCutService;
  final ShiftService? shiftService;
  final ThermalPrinterService? printerService;

  const CashCutScreen({
    super.key,
    this.cashCutService,
    this.shiftService,
    this.printerService,
  });

  @override
  State<CashCutScreen> createState() => _CashCutScreenState();
}

class _CashCutScreenState extends State<CashCutScreen> {
  late final CashCutService _cashCutService;
  late final ShiftService _shiftService;
  late final ThermalPrinterService _printerService;

  final TextEditingController _initialFloatController = TextEditingController(text: '0.00');
  final TextEditingController _countedCashController = TextEditingController(text: '0.00');

  CashCutSummaryModel? _summary;
  ShiftModel? _activeShift;
  bool _isLoading = true;
  bool _isPrinting = false;

  @override
  void initState() {
    super.initState();
    _cashCutService = widget.cashCutService ?? CashCutService();
    _shiftService = widget.shiftService ?? ShiftService();
    _printerService = widget.printerService ?? ThermalPrinterService();
    _loadSummary();
  }

  Future<void> _loadSummary() async {
    setState(() => _isLoading = true);

    try {
      final userId = Supabase.instance.client.auth.currentUser?.id ?? '';
      final activeShift = await _shiftService.getActiveShift(userId);

      if (activeShift != null) {
        _activeShift = activeShift;
        _initialFloatController.text = activeShift.initialCash.toStringAsFixed(2);
      }

      final summary = await _cashCutService.getTodaySummary(userId, shiftId: activeShift?.id);

      if (mounted) {
        setState(() {
          _summary = summary;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  double get _initialFloat => double.tryParse(_initialFloatController.text) ?? 0.0;
  double get _countedCash => double.tryParse(_countedCashController.text) ?? 0.0;

  double get _expectedCash => (_summary?.totalCash ?? 0.0) + _initialFloat;
  double get _difference => _countedCash - _expectedCash;

  String _formatCurrency(double val) {
    return NumberFormat.currency(locale: 'es_MX', symbol: '\$', decimalDigits: 2).format(val);
  }

  Future<void> _printAndCloseShift() async {
    if (_summary == null) return;

    setState(() => _isPrinting = true);

    final userEmail = Supabase.instance.client.auth.currentUser?.email ?? 'Cajero Default';

    // 1. Cierre en Supabase
    bool shiftClosed = false;
    if (_activeShift?.id != null) {
      try {
        await _shiftService.closeShift(
          shiftId: _activeShift!.id!,
          summary: _summary!,
          initialCash: _initialFloat,
          countedCash: _countedCash,
          difference: _difference,
        );
        shiftClosed = true;
      } catch (e) {
        debugPrint('⚠️ Error registrando el cierre de turno en Supabase: $e');
      }
    }

    // 2. Impresión de ticket térmico
    bool printSuccess = false;
    try {
      printSuccess = await _printerService.printCashCutTicket(
        summary: _summary!,
        initialFloat: _initialFloat,
        countedCash: _countedCash,
        difference: _difference,
        cashierName: userEmail,
      );
    } catch (e) {
      debugPrint('⚠️ Error imprimiendo ticket de corte Z: $e');
    }

    if (mounted) {
      setState(() => _isPrinting = false);

      final String message = shiftClosed
          ? printSuccess
              ? tr('shift_closed_print_success')
              : tr('shift_closed_no_print')
          : printSuccess
              ? tr('z_cut_printed')
              : tr('z_cut_print_error');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: shiftClosed || printSuccess ? Colors.green[700] : Colors.orange[800],
          duration: const Duration(seconds: 4),
        ),
      );

      _loadSummary();
    }
  }

  Future<void> _openNewShift() async {
    final userId = Supabase.instance.client.auth.currentUser?.id ?? '';
    if (userId.isEmpty) return;

    try {
      await _shiftService.openShift(userId: userId, initialCash: _initialFloat);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr('new_shift_success')), backgroundColor: Colors.green),
        );
        _loadSummary();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  void dispose() {
    _initialFloatController.dispose();
    _countedCashController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppLocale.instance,
      builder: (context, _) {
        final titleText = _activeShift != null && _activeShift!.shiftNumber != null
            ? '${tr('cash_cut_shift')} #${_activeShift!.shiftNumber})'
            : tr('cash_cut_z');

        return Scaffold(
          appBar: AppBar(
            title: Text(
              titleText,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.calendar_month),
                tooltip: tr('sales_calendar'),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const CashCalendarScreen()),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.history),
                tooltip: tr('shifts_history'),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ShiftsHistoryScreen()),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: tr('reload_data'),
                onPressed: _loadSummary,
              ),
            ],
          ),
          body: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _summary == null
                  ? Center(child: Text(tr('could_not_load_data')))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildShiftHeaderBadge(),
                          const SizedBox(height: 12),

                          _buildTotalBanner(_summary!),
                          const SizedBox(height: 16),

                          Row(
                            children: [
                              Expanded(child: _buildMetricCard(tr('cash'), _summary!.totalCash, Icons.payments, Colors.green)),
                              const SizedBox(width: 8),
                              Expanded(child: _buildMetricCard(tr('card'), _summary!.totalCard, Icons.contactless, Colors.blue)),
                              const SizedBox(width: 8),
                              Expanded(child: _buildMetricCard(tr('dynamic_qr'), _summary!.totalQr, Icons.qr_code_2, Colors.purple)),
                            ],
                          ),
                          const SizedBox(height: 16),

                          _buildSecondaryMetricsCard(_summary!),
                          const SizedBox(height: 16),

                          buildWaiterTipsBreakdown(_summary!.waiterBreakdown),
                          const SizedBox(height: 20),

                          Text(
                            tr('drawer_balance'),
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),

                          Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                children: [
                                  TextField(
                                    controller: _initialFloatController,
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    decoration: InputDecoration(
                                      labelText: tr('initial_cash_label'),
                                      prefixText: '\$ ',
                                      suffixText: 'MXN',
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    onChanged: (_) => setState(() {}),
                                  ),
                                  const SizedBox(height: 12),
                                  TextField(
                                    controller: _countedCashController,
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    decoration: InputDecoration(
                                      labelText: tr('counted_cash_drawer'),
                                      prefixText: '\$ ',
                                      suffixText: 'MXN',
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    onChanged: (_) => setState(() {}),
                                  ),
                                  const SizedBox(height: 16),

                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(tr('expected_cash'), style: TextStyle(color: Colors.grey[700], fontSize: 14)),
                                      Text(
                                        _formatCurrency(_expectedCash),
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),

                                  _buildDifferenceBanner(),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          SizedBox(
                            height: 54,
                            child: ElevatedButton.icon(
                              onPressed: _isPrinting ? null : _printAndCloseShift,
                              icon: const Icon(Icons.print_outlined, size: 24),
                              label: _isPrinting
                                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                  : Text(
                                      tr('close_shift_and_print'),
                                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                                    ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.indigo[800],
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
        );
      },
    );
  }

  Widget _buildShiftHeaderBadge() {
    final isOpen = _activeShift != null && _activeShift!.status == 'open';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: isOpen ? Colors.green[50] : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isOpen ? Colors.green[300]! : Colors.grey[300]!),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                isOpen ? Icons.play_circle_fill : Icons.pause_circle_filled,
                color: isOpen ? Colors.green[700] : Colors.grey[600],
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                isOpen 
                    ? '${tr('active_shift_header')} #${_activeShift?.shiftNumber ?? '1'}' 
                    : tr('no_active_shift'),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isOpen ? Colors.green[900] : Colors.grey[800],
                ),
              ),
            ],
          ),
          if (!isOpen)
            TextButton.icon(
              onPressed: _openNewShift,
              icon: const Icon(Icons.add, size: 18),
              label: Text(tr('open_shift')),
            ),
        ],
      ),
    );
  }

  Widget _buildTotalBanner(CashCutSummaryModel summary) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            tr('total_collected_shift'),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          FittedBox(
            child: Text(
              _formatCurrency(summary.totalCollected),
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w800,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String label, double amount, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey[800]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          FittedBox(
            child: Text(
              _formatCurrency(amount),
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecondaryMetricsCard(CashCutSummaryModel summary) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Column(
              children: [
                Text(tr('transactions'), style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                const SizedBox(height: 4),
                Text('${summary.totalTransactions}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            Container(height: 30, width: 1, color: Colors.grey[300]),
            Column(
              children: [
                Text(tr('pending'), style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                const SizedBox(height: 4),
                Text(
                  '${summary.pendingTransactions}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: summary.pendingTransactions > 0 ? Colors.orange[800] : Colors.grey[800],
                  ),
                ),
              ],
            ),
            Container(height: 30, width: 1, color: Colors.grey[300]),
            Column(
              children: [
                Text(tr('avg_ticket'), style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                const SizedBox(height: 4),
                Text(_formatCurrency(summary.averageTicket), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget buildWaiterTipsBreakdown(List<Map<String, dynamic>> cashCutData) {
    if (cashCutData.isEmpty) {
      return Card(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(tr('no_tips_breakdown'), style: const TextStyle(color: Colors.grey)),
        ),
      );
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.volunteer_activism_rounded, color: Color(0xFF2563EB), size: 22),
                const SizedBox(width: 8),
                Text(
                  tr('waiter_tips_breakdown'),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: cashCutData.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final waiter = cashCutData[index];
                final waiterName = waiter['waiter_name']?.toString() ?? tr('waiter_service');
                final totalSales = (waiter['total_sales'] as num?)?.toDouble() ?? 0.0;
                final cashTips = (waiter['cash_tips'] as num?)?.toDouble() ?? 0.0;
                final cardTips = (waiter['card_tips'] as num?)?.toDouble() ?? 0.0;

                return ListTile(
                  dense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  title: Text(
                    waiterName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  subtitle: Text(
                    '${tr('sales_charged')}: \$${totalSales.toStringAsFixed(2)}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${tr('cash')}: \$${cashTips.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green),
                      ),
                      Text(
                        '${tr('card')}: \$${cardTips.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blue),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDifferenceBanner() {
    Color color;
    String title;
    IconData icon;

    if (_difference == 0) {
      color = Colors.green[700]!;
      title = tr('exact_balance');
      icon = Icons.check_circle;
    } else if (_difference > 0) {
      color = Colors.blue[800]!;
      title = '${tr('cash_overage')} +${_formatCurrency(_difference)}';
      icon = Icons.trending_up;
    } else {
      color = Colors.red[700]!;
      title = '${tr('cash_shortage')} -${_formatCurrency(_difference.abs())}';
      icon = Icons.warning_amber_rounded;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              title,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
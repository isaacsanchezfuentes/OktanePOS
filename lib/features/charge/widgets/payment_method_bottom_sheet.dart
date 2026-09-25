import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/charge_model.dart';
import '../services/charge_service.dart';
import '../../printer/services/thermal_printer_service.dart';

class PaymentMethodBottomSheet extends StatefulWidget {
  final double amount;
  final String concept;
  final ChargeService chargeService;

  const PaymentMethodBottomSheet({
    super.key,
    required this.amount,
    required this.concept,
    required this.chargeService,
  });

  static Future<ChargeModel?> show(
    BuildContext context, {
    required double amount,
    required String concept,
    required ChargeService chargeService,
  }) {
    return showModalBottomSheet<ChargeModel>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => PaymentMethodBottomSheet(
        amount: amount,
        concept: concept,
        chargeService: chargeService,
      ),
    );
  }

  @override
  State<PaymentMethodBottomSheet> createState() => _PaymentMethodBottomSheetState();
}

class _PaymentMethodBottomSheetState extends State<PaymentMethodBottomSheet> {
  String _selectedMethod = 'efectivo'; // 'efectivo', 'tarjeta', 'qr'
  final TextEditingController _cashReceivedController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _cashReceivedController.text = widget.amount.toStringAsFixed(2);
  }

  @override
  void dispose() {
    _cashReceivedController.dispose();
    super.dispose();
  }

  String _formatCurrency(double val) {
    return NumberFormat.currency(locale: 'es_MX', symbol: '\$', decimalDigits: 2).format(val);
  }

  double get _cashReceived {
    return double.tryParse(_cashReceivedController.text) ?? 0.0;
  }

  double get _change {
    final diff = _cashReceived - widget.amount;
    return diff > 0 ? diff : 0.0;
  }

  Future<void> _confirmCharge(String method) async {
    setState(() => _isLoading = true);

    try {
      final userId = Supabase.instance.client.auth.currentUser?.id ?? '';
      final conceptFinal = widget.concept.trim().isEmpty ? 'Consumo mostrador' : widget.concept.trim();

      final charge = await widget.chargeService.createPendingCharge(
        amount: widget.amount,
        userId: userId,
        concept: conceptFinal,
        paymentMethod: method,
      );

      // Immediately set status to 'paid' on the same record without duplicating
      if (charge.id != null) {
        await widget.chargeService.updateChargeStatusAndMethod(
          charge.id!,
          'paid',
          paymentMethod: method,
        );
      }

      if (method == 'qr') {
        try {
          await ThermalPrinterService().printChargeTicket(charge);
        } catch (e) {
          debugPrint('⚠️ Intento de impresión térmica finalizado con nota: $e');
        }
      }

      if (mounted) {
        Navigator.pop(context, charge);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error guardando el cobro: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewInsetsBottom = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(
        left: 20.0,
        right: 20.0,
        top: 20.0,
        bottom: 20.0 + viewInsetsBottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header with amount and concept
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Método de Cobro',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      widget.concept.trim().isEmpty ? 'Consumo mostrador' : widget.concept,
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _formatCurrency(widget.amount),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Payment Method Tabs
          Row(
            children: [
              _buildMethodTab('efectivo', Icons.payments_outlined, 'Efectivo'),
              const SizedBox(width: 8),
              _buildMethodTab('tarjeta', Icons.contactless_outlined, 'Tarjeta'),
              const SizedBox(width: 8),
              _buildMethodTab('qr', Icons.qr_code_2_outlined, 'QR Dinámico'),
            ],
          ),
          const SizedBox(height: 20),

          // Active Method Content
          if (_selectedMethod == 'efectivo') _buildEfectivoContent(),
          if (_selectedMethod == 'tarjeta') _buildTarjetaContent(),
          if (_selectedMethod == 'qr') _buildQrContent(),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildMethodTab(String id, IconData icon, String label) {
    final isSelected = _selectedMethod == id;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedMethod = id),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? primaryColor.withOpacity(0.12) : Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? primaryColor : Colors.grey[300]!,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: isSelected ? primaryColor : Colors.grey[700], size: 26),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? primaryColor : Colors.grey[800],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEfectivoContent() {
    final cashOptions = [
      widget.amount,
      20.0,
      50.0,
      100.0,
      200.0,
      500.0,
    ].where((val) => val >= widget.amount || val == widget.amount).toSet().toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _cashReceivedController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: 'Monto Recibido',
            prefixText: '\$ ',
            suffixText: 'MXN',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: cashOptions.map((val) {
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: ActionChip(
                  label: Text('\$${val.toStringAsFixed(val.truncateToDouble() == val ? 0 : 2)}'),
                  onPressed: () {
                    setState(() {
                      _cashReceivedController.text = val.toStringAsFixed(2);
                    });
                  },
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.green[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.green[200]!),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Cambio:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green),
              ),
              Text(
                _formatCurrency(_change),
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.green),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: _isLoading ? null : () => _confirmCharge('efectivo'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green[700],
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: _isLoading
              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text('CONFIRMAR COBRO EN EFECTIVO', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _buildTarjetaContent() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.blue[200]!),
          ),
          child: Column(
            children: [
              const Icon(Icons.contactless, size: 64, color: Colors.blue),
              const SizedBox(height: 12),
              const Text(
                'Aproxime la tarjeta o terminal POS',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue),
              ),
              const SizedBox(height: 4),
              Text(
                'Acepta Visa, Mastercard, American Express y Tap to Pay',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.blue[900]),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isLoading ? null : () => _confirmCharge('tarjeta'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[700],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: _isLoading
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('CONFIRMAR PAGO CON TARJETA', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  Widget _buildQrContent() {
    final tempId = DateTime.now().millisecondsSinceEpoch.toString();
    final folio = tempId.length >= 4 ? tempId.substring(tempId.length - 4) : tempId;
    final qrData = 'https://oktane-pos.web.app/pay?id=$tempId&folio=$folio&amount=${widget.amount}';

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey[300]!),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              QrImageView(
                data: qrData,
                version: QrVersions.auto,
                size: 180.0,
              ),
              const SizedBox(height: 8),
              Text(
                'Muestre o imprima el código QR para el cliente',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _isLoading ? null : () => _confirmCharge('qr'),
            icon: const Icon(Icons.print_outlined),
            label: _isLoading
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('IMPRIMIR TICKET QR', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple[700],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }
}

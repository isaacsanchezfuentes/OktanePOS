import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/charge_model.dart';
import '../services/charge_service.dart';
import '../../printer/services/thermal_printer_service.dart';

class PaymentMethodBottomSheet extends StatefulWidget {
  final double amount;
  final double tipAmount;
  final String concept;
  final String? waiterId;
  final String? waiterName;
  final ChargeService chargeService;
  final List<Map<String, dynamic>>? orderItems;
  final void Function(List<int> paidIndices)? onItemsPaid;

  const PaymentMethodBottomSheet({
    super.key,
    required this.amount,
    this.tipAmount = 0.0,
    required this.concept,
    this.waiterId,
    this.waiterName,
    required this.chargeService,
    this.orderItems,
    this.onItemsPaid,
  });

  static Future<ChargeModel?> show(
    BuildContext context, {
    required double amount,
    double tipAmount = 0.0,
    required String concept,
    String? waiterId,
    String? waiterName,
    required ChargeService chargeService,
    List<Map<String, dynamic>>? orderItems,
    void Function(List<int> paidIndices)? onItemsPaid,
  }) {
    return showModalBottomSheet<ChargeModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => PaymentMethodBottomSheet(
        amount: amount,
        tipAmount: tipAmount,
        concept: concept,
        waiterId: waiterId,
        waiterName: waiterName,
        chargeService: chargeService,
        orderItems: orderItems,
        onItemsPaid: onItemsPaid,
      ),
    );
  }

  @override
  State<PaymentMethodBottomSheet> createState() => _PaymentMethodBottomSheetState();
}

class _PaymentMethodBottomSheetState extends State<PaymentMethodBottomSheet> {
  String _selectedMethod = 'efectivo'; // 'efectivo', 'tarjeta', 'qr'
  final TextEditingController _cashReceivedController = TextEditingController();
  final TextEditingController _tipController = TextEditingController();
  final TextEditingController _customAmountController = TextEditingController();

  bool _isLoading = false;
  late double _effectiveChargeAmount;
  late Set<int> _selectedIndices;
  bool _isManualAbonoMode = false;

  @override
  void initState() {
    super.initState();
    _tipController.text = widget.tipAmount > 0 ? widget.tipAmount.toStringAsFixed(2) : '0.00';

    if (widget.orderItems != null && widget.orderItems!.isNotEmpty) {
      _selectedIndices = Set<int>.from(List.generate(widget.orderItems!.length, (i) => i));
      _effectiveChargeAmount = widget.amount;
    } else {
      _selectedIndices = <int>{};
      _effectiveChargeAmount = widget.amount;
    }

    _customAmountController.text = _effectiveChargeAmount.toStringAsFixed(2);
    _updateCashReceivedDefault();
  }

  void _recalculateAmountFromSelectedItems() {
    if (widget.orderItems != null && widget.orderItems!.isNotEmpty) {
      double sum = 0.0;
      for (final idx in _selectedIndices) {
        if (idx < widget.orderItems!.length) {
          final item = widget.orderItems![idx];
          sum += ((item['subtotal'] ?? item['price']) as num).toDouble();
        }
      }
      _effectiveChargeAmount = sum > 0 ? sum : 0.0;
      _customAmountController.text = _effectiveChargeAmount.toStringAsFixed(2);
      _updateCashReceivedDefault();
    }
  }

  void _updateCashReceivedDefault() {
    final tip = double.tryParse(_tipController.text) ?? 0.0;
    _cashReceivedController.text = (_effectiveChargeAmount + tip).toStringAsFixed(2);
  }

  @override
  void dispose() {
    _cashReceivedController.dispose();
    _tipController.dispose();
    _customAmountController.dispose();
    super.dispose();
  }

  String _formatCurrency(double val) {
    return NumberFormat.currency(locale: 'es_MX', symbol: '\$', decimalDigits: 2).format(val);
  }

  double get _currentTip => double.tryParse(_tipController.text) ?? 0.0;
  double get _totalWithTip => _effectiveChargeAmount + _currentTip;
  double get _cashReceived => double.tryParse(_cashReceivedController.text) ?? 0.0;
  double get _change {
    final diff = _cashReceived - _totalWithTip;
    return diff > 0 ? diff : 0.0;
  }

  Future<void> _confirmCharge(String method) async {
    if (_effectiveChargeAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Selecciona al menos un platillo o un monto válido a cobrar.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userId = Supabase.instance.client.auth.currentUser?.id ?? '';
      final conceptFinal = widget.concept.trim().isEmpty ? 'Consumo mostrador' : widget.concept.trim();

      final charge = await widget.chargeService.createPendingCharge(
        amount: _effectiveChargeAmount,
        tipAmount: _currentTip,
        userId: userId,
        concept: conceptFinal,
        paymentMethod: method,
        waiterId: widget.waiterId,
        waiterName: widget.waiterName,
      );

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
          debugPrint('⚠️ Impresión térmica con nota: $e');
        }
      }

      if (widget.orderItems != null && widget.orderItems!.isNotEmpty) {
        widget.onItemsPaid?.call(_selectedIndices.toList());
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
    final hasItems = widget.orderItems != null && widget.orderItems!.isNotEmpty;

    return SafeArea(
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: EdgeInsets.only(bottom: viewInsetsBottom),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20.0, 16.0, 20.0, 24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4.5,
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(2.5),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Encabezado
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Método de Cobro',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.concept.trim().isEmpty ? 'Consumo mostrador' : widget.concept,
                          style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFBFDBFE), width: 1.2),
                    ),
                    child: Text(
                      _formatCurrency(_totalWithTip),
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF1D4ED8),
                      ),
                    ),
                  ),
                ],
              ),

              // DESGLOSE POR PLATILLOS A COBRAR
              if (hasItems) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Platillos a pagar en este cobro:',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                          ),
                          InkWell(
                            onTap: () {
                              setState(() {
                                if (_selectedIndices.length == widget.orderItems!.length) {
                                  _selectedIndices.clear();
                                } else {
                                  _selectedIndices = Set<int>.from(List.generate(widget.orderItems!.length, (i) => i));
                                }
                                _recalculateAmountFromSelectedItems();
                              });
                            },
                            child: Text(
                              _selectedIndices.length == widget.orderItems!.length ? 'Desmarcar todos' : 'Marcar todos',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF2563EB)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: List.generate(widget.orderItems!.length, (index) {
                          final item = widget.orderItems![index];
                          final isSelected = _selectedIndices.contains(index);
                          final subtotal = ((item['subtotal'] ?? item['price']) as num).toDouble();
                          final qty = (item['quantity'] as num?)?.toInt() ?? 1;

                          return FilterChip(
                            selected: isSelected,
                            checkmarkColor: Colors.white,
                            selectedColor: const Color(0xFF2563EB),
                            backgroundColor: Colors.white,
                            label: Text(
                              '${qty}x ${item['name']} (${_formatCurrency(subtotal)})',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                                color: isSelected ? Colors.white : const Color(0xFF1E293B),
                              ),
                            ),
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  _selectedIndices.add(index);
                                } else {
                                  _selectedIndices.remove(index);
                                }
                                _recalculateAmountFromSelectedItems();
                              });
                            },
                          );
                        }),
                      ),
                    ],
                  ),
                ),
              ] else if (widget.amount > 0) ...[
                // ABONO PARCIAL POR MONTO DIRECTO
                const SizedBox(height: 10),
                Row(
                  children: [
                    InkWell(
                      onTap: () {
                        setState(() {
                          _isManualAbonoMode = !_isManualAbonoMode;
                          if (!_isManualAbonoMode) {
                            _effectiveChargeAmount = widget.amount;
                            _customAmountController.text = widget.amount.toStringAsFixed(2);
                            _updateCashReceivedDefault();
                          }
                        });
                      },
                      child: Text(
                        _isManualAbonoMode ? '↩️ Cobrar saldo completo' : '✂️ ¿Abono parcial / Dividir cuenta?',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF2563EB)),
                      ),
                    ),
                  ],
                ),
                if (_isManualAbonoMode) ...[
                  const SizedBox(height: 8),
                  TextField(
                    controller: _customAmountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                    decoration: InputDecoration(
                      labelText: 'Monto de este abono parcial',
                      prefixText: '\$ ',
                      suffixText: 'MXN',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      isDense: true,
                    ),
                    onChanged: (val) {
                      final parsed = double.tryParse(val) ?? 0.0;
                      setState(() {
                        _effectiveChargeAmount = parsed.clamp(0.0, widget.amount);
                        _updateCashReceivedDefault();
                      });
                    },
                  ),
                ],
              ],

              const SizedBox(height: 14),

              // Campo de Propina
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _tipController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                    decoration: InputDecoration(
                      labelText: 'Propina opcional',
                      labelStyle: const TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold),
                      prefixText: '\$ ',
                      prefixStyle: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                      suffixText: 'MXN',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      isDense: true,
                    ),
                    onChanged: (val) {
                      setState(() {
                        _updateCashReceivedDefault();
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        ActionChip(
                          label: const Text('Sin propina'),
                          onPressed: () {
                            setState(() {
                              _tipController.text = '0.00';
                              _updateCashReceivedDefault();
                            });
                          },
                        ),
                        const SizedBox(width: 6),
                        ActionChip(
                          label: Text('10% (\$' + (_effectiveChargeAmount * 0.10).toStringAsFixed(2) + ')'),
                          onPressed: () {
                            setState(() {
                              _tipController.text = (_effectiveChargeAmount * 0.10).toStringAsFixed(2);
                              _updateCashReceivedDefault();
                            });
                          },
                        ),
                        const SizedBox(width: 6),
                        ActionChip(
                          label: Text('15% (\$' + (_effectiveChargeAmount * 0.15).toStringAsFixed(2) + ')'),
                          onPressed: () {
                            setState(() {
                              _tipController.text = (_effectiveChargeAmount * 0.15).toStringAsFixed(2);
                              _updateCashReceivedDefault();
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Pestañas
              Row(
                children: [
                  _buildMethodTab('efectivo', Icons.payments_outlined, 'Efectivo'),
                  const SizedBox(width: 8),
                  _buildMethodTab('tarjeta', Icons.contactless_outlined, 'Tarjeta'),
                  const SizedBox(width: 8),
                  _buildMethodTab('qr', Icons.qr_code_2_outlined, 'QR Dinámico'),
                ],
              ),
              const SizedBox(height: 16),

              if (_selectedMethod == 'efectivo') _buildEfectivoContent(),
              if (_selectedMethod == 'tarjeta') _buildTarjetaContent(),
              if (_selectedMethod == 'qr') _buildQrContent(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMethodTab(String id, IconData icon, String label) {
    final isSelected = _selectedMethod == id;
    const primaryColor = Color(0xFF2563EB);

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => setState(() => _selectedMethod = id),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? primaryColor.withValues(alpha: 0.12) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? primaryColor : const Color(0xFFCBD5E1),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: isSelected ? primaryColor : const Color(0xFF475569), size: 24),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                    color: isSelected ? primaryColor : const Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEfectivoContent() {
    final totalPay = _totalWithTip;
    final cashOptions = [
      totalPay,
      20.0,
      50.0,
      100.0,
      200.0,
      500.0,
    ].where((val) => val >= totalPay || val == totalPay).toSet().toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _cashReceivedController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A)),
          decoration: InputDecoration(
            labelText: 'Monto Recibido',
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
            prefixText: '\$ ',
            prefixStyle: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
            suffixText: 'MXN',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: cashOptions.map((val) {
              return Padding(
                padding: const EdgeInsets.only(right: 6.0),
                child: ActionChip(
                  label: Text(
                    '\$${val.toStringAsFixed(val.truncateToDouble() == val ? 0 : 2)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
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
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFF0FDF4),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFBBF7D0)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Cambio:',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF16A34A)),
              ),
              Text(
                _formatCurrency(_change),
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF16A34A)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _isLoading ? null : () => _confirmCharge('efectivo'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF16A34A),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 2,
          ),
          child: _isLoading
              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : Text('CONFIRMAR COBRO ${_formatCurrency(_totalWithTip)}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
        ),
      ],
    );
  }

  Widget _buildTarjetaContent() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFBFDBFE)),
          ),
          child: Column(
            children: const [
              Icon(Icons.contactless, size: 54, color: Color(0xFF2563EB)),
              SizedBox(height: 10),
              Text(
                'Aproxime tarjeta o terminal Clip',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E40AF)),
              ),
              SizedBox(height: 4),
              Text(
                'Visa, Mastercard, AMEX y Contactless / Apple Pay',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Color(0xFF3B82F6), fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isLoading ? null : () => _confirmCharge('tarjeta'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 2,
            ),
            child: _isLoading
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Text('CONFIRMAR PAGO ${_formatCurrency(_totalWithTip)}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
          ),
        ),
      ],
    );
  }

  Widget _buildQrContent() {
    final tempId = DateTime.now().millisecondsSinceEpoch.toString();
    final folio = tempId.length >= 4 ? tempId.substring(tempId.length - 4) : tempId;
    final totalPay = _totalWithTip;
    final qrData = 'https://oktane-pos.web.app/pay?id=$tempId&folio=$folio&amount=$totalPay';

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            children: [
              QrImageView(
                data: qrData,
                version: QrVersions.auto,
                size: 160.0,
              ),
              const SizedBox(height: 6),
              const Text(
                'Escanee con CoDi, Mercado Pago o banca móvil',
                style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _isLoading ? null : () => _confirmCharge('qr'),
            icon: const Icon(Icons.print_outlined),
            label: _isLoading
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Text('IMPRIMIR TICKET QR ${_formatCurrency(_totalWithTip)}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7C3AED),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 2,
            ),
          ),
        ),
      ],
    );
  }
}
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:oktane_pos/providers/auth_provider.dart';
import 'package:oktane_pos/ui/screens/login_screen.dart';
import '../models/charge_model.dart';
import '../services/charge_service.dart';
import '../widgets/amount_display.dart';
import '../widgets/pos_keypad.dart';
import '../widgets/payment_method_bottom_sheet.dart';
import 'charges_history_screen.dart';
import '../../printer/screens/printer_settings_screen.dart';
import '../../cash_cut/screens/cash_cut_screen.dart';
import '../../cash_cut/screens/cash_calendar_screen.dart';
import '../../cash_cut/services/shift_service.dart';
import '../../cash_cut/services/shift_policy_service.dart';
import '../../tables/screens/tables_map_screen.dart';
import '../../auth/services/rbac_service.dart';

class QuickChargeScreen extends StatefulWidget {
  const QuickChargeScreen({super.key});

  @override
  State<QuickChargeScreen> createState() => _QuickChargeScreenState();
}

class _QuickChargeScreenState extends State<QuickChargeScreen> {
  final ChargeService _chargeService = ChargeService();
  final ShiftService _shiftService = ShiftService();
  final ShiftPolicyService _policyService = ShiftPolicyService();
  final RbacService _rbacService = RbacService();
  final TextEditingController _conceptController = TextEditingController();
  
  String _rawInput = '0';
  bool _isConceptExpanded = false;

  double get _amount => double.tryParse(_rawInput) ?? 0.0;

  void _handleKeyTap(String key) {
    setState(() {
      if (key == 'CLEAR') {
        _rawInput = '0';
      } else if (key == 'BACKSPACE') {
        if (_rawInput.length > 1) {
          _rawInput = _rawInput.substring(0, _rawInput.length - 1);
        } else {
          _rawInput = '0';
        }
      } else if (key == '.') {
        if (!_rawInput.contains('.')) {
          _rawInput = '$_rawInput.';
        }
      } else if (key == '00') {
        if (_rawInput != '0') {
          if (_rawInput.contains('.')) {
            final parts = _rawInput.split('.');
            if (parts[1].isEmpty) {
              _rawInput = '${_rawInput}00';
            } else if (parts[1].length == 1) {
              _rawInput = '${_rawInput}0';
            }
          } else {
            _rawInput = '${_rawInput}00';
          }
        }
      } else {
        // Digits 0-9
        if (_rawInput == '0') {
          _rawInput = key;
        } else if (_rawInput.contains('.')) {
          final parts = _rawInput.split('.');
          if (parts[1].length < 2) {
            _rawInput = '$_rawInput$key';
          }
        } else {
          _rawInput = '$_rawInput$key';
        }
      }
    });
  }

  void _resetKeypad() {
    setState(() {
      _rawInput = '0';
      _conceptController.clear();
      _isConceptExpanded = false;
    });
  }

  Future<bool> _showMandatoryOpenShiftDialog(String userId) async {
    final closedShiftsToday = await _shiftService.getClosedShifts(userId);
    final todayClosedCount = closedShiftsToday.where((s) {
      final date = s.closedAt ?? s.openedAt;
      final now = DateTime.now();
      return date.year == now.year && date.month == now.month && date.day == now.day;
    }).length;

    final canOpen = await _policyService.canOpenNewShiftToday(todayClosedCount);
    if (!canOpen && mounted) {
      final mode = await _policyService.getPolicyMode();
      final modeDesc = _policyService.getModeDescription(mode);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('⚠️ $modeDesc. Límite diario alcanzado.'),
          backgroundColor: Colors.orange[800],
          duration: const Duration(seconds: 4),
        ),
      );
      return false;
    }

    final initialCashController = TextEditingController(text: '500.00');
    final formKey = GlobalKey<FormState>();
    bool isOpening = false;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.lock_open, color: Colors.indigo),
              SizedBox(width: 8),
              Text('Apertura de Turno', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'No hay un turno de caja abierto. Inicie turno para comenzar a cobrar.',
                  style: TextStyle(fontSize: 13, color: Colors.black87),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: initialCashController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Fondo Inicial de Caja (Cambio)',
                    prefixText: '\$ ',
                    suffixText: 'MXN',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Requerido';
                    if (double.tryParse(v.trim()) == null) return 'Monto inválido';
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isOpening ? null : () => Navigator.pop(ctx, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: isOpening
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setModalState(() => isOpening = true);
                      final initialCash = double.tryParse(initialCashController.text.trim()) ?? 0.0;
                      try {
                        await _shiftService.openShift(userId: userId, initialCash: initialCash);
                        if (context.mounted) {
                          Navigator.pop(ctx, true);
                        }
                      } catch (e) {
                        setModalState(() => isOpening = false);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error al abrir turno: $e'), backgroundColor: Colors.red),
                          );
                        }
                      }
                    },
              child: isOpening
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('INICIAR TURNO'),
            ),
          ],
        ),
      ),
    );

    return result == true;
  }

  Future<void> _openPaymentModal() async {
    if (_amount <= 0) return;

    final userId = Supabase.instance.client.auth.currentUser?.id ?? '';
    final activeShift = await _shiftService.getActiveShift(userId);

    if (activeShift == null && mounted) {
      final bool opened = await _showMandatoryOpenShiftDialog(userId);
      if (!opened) return;
    }

    final conceptText = _conceptController.text.trim().isEmpty 
        ? 'Consumo mostrador' 
        : _conceptController.text.trim();

    final resultCharge = await PaymentMethodBottomSheet.show(
      context,
      amount: _amount,
      concept: conceptText,
      chargeService: _chargeService,
    );

    if (resultCharge != null && mounted) {
      final methodDisplay = resultCharge.paymentMethod == 'qr'
          ? 'Ticket QR impreso'
          : resultCharge.paymentMethod == 'tarjeta'
              ? 'Pago con tarjeta registrado'
              : 'Pago en efectivo registrado';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Text('✅ $methodDisplay (\$${resultCharge.amount.toStringAsFixed(2)} MXN)'),
              ),
            ],
          ),
          backgroundColor: Colors.green[700],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );

      // Reset keypad back to $0.00 immediately
      _resetKeypad();
    }
  }

  String _formatAmount(double val) {
    return NumberFormat.currency(locale: 'es_MX', symbol: '\$', decimalDigits: 2).format(val);
  }

  @override
  void dispose() {
    _conceptController.dispose();
    super.dispose();
  }

  Future<void> _checkManagerAccessAndNavigate(Widget destination) async {
    final auth = context.read<AuthProvider>();
    final isManager = _rbacService.isManagerOrAdmin(auth.rol);

    if (isManager) {
      Navigator.push(context, MaterialPageRoute(builder: (context) => destination));
      return;
    }

    final pinCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final bool? granted = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.security, color: Colors.indigo),
            SizedBox(width: 8),
            Text('PIN de Gerente Requerido', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('El acceso a este módulo administrativo requiere autorización de supervisor.'),
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
      Navigator.push(context, MaterialPageRoute(builder: (context) => destination));
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ Acceso denegado: PIN de gerente requerido'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 12,
        title: const FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.point_of_sale, color: Colors.blue),
              SizedBox(width: 6),
              Text('Cobro Rápido', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.table_restaurant),
            tooltip: 'Plano de Mesas',
            constraints: const BoxConstraints(),
            padding: const EdgeInsets.symmetric(horizontal: 6),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const TablesMapScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.print_outlined),
            tooltip: 'Impresora',
            constraints: const BoxConstraints(),
            padding: const EdgeInsets.symmetric(horizontal: 6),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PrinterSettingsScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.receipt_long),
            tooltip: 'Historial',
            constraints: const BoxConstraints(),
            padding: const EdgeInsets.symmetric(horizontal: 6),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ChargesHistoryScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.calendar_month),
            tooltip: 'Calendario',
            constraints: const BoxConstraints(),
            padding: const EdgeInsets.symmetric(horizontal: 6),
            onPressed: () {
              _checkManagerAccessAndNavigate(const CashCalendarScreen());
            },
          ),
          IconButton(
            icon: const Icon(Icons.account_balance_wallet_outlined),
            tooltip: 'Corte de Caja',
            constraints: const BoxConstraints(),
            padding: const EdgeInsets.symmetric(horizontal: 6),
            onPressed: () {
              _checkManagerAccessAndNavigate(const CashCutScreen());
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar Sesión',
            constraints: const BoxConstraints(),
            padding: const EdgeInsets.fromLTRB(6, 0, 12, 0),
            onPressed: () async {
              await auth.logout();
              if (mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Upper Viewer / Amount Display
            AmountDisplay(
              amount: _amount,
              rawInput: _rawInput,
            ),

            // Concept / Note expandable field
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
              child: Card(
                elevation: 0,
                color: Colors.grey[100],
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ExpansionTile(
                  key: ValueKey(_isConceptExpanded),
                  initiallyExpanded: _isConceptExpanded,
                  onExpansionChanged: (val) => setState(() => _isConceptExpanded = val),
                  leading: const Icon(Icons.note_add_outlined, color: Colors.blueGrey),
                  title: Text(
                    _conceptController.text.trim().isEmpty
                        ? 'Concepto / Nota (Opcional)'
                        : 'Nota: ${_conceptController.text.trim()}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: _conceptController.text.trim().isEmpty 
                          ? FontWeight.normal 
                          : FontWeight.bold,
                      color: _conceptController.text.trim().isEmpty 
                          ? Colors.grey[700] 
                          : Colors.blueGrey[900],
                    ),
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: TextField(
                        controller: _conceptController,
                        decoration: InputDecoration(
                          hintText: 'Ej. Mesa 4, Barra, Consumo',
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () => setState(() => _conceptController.clear()),
                          ),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // POS Keypad
            Expanded(
              child: PosKeypad(
                onKeyTap: _handleKeyTap,
              ),
            ),

            // Main Cobrar Action Button
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                height: 58,
                child: ElevatedButton(
                  onPressed: _amount > 0 ? _openPaymentModal : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[600],
                    disabledBackgroundColor: Colors.grey[300],
                    foregroundColor: Colors.white,
                    elevation: _amount > 0 ? 4 : 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.shopping_cart_checkout, size: 26),
                      const SizedBox(width: 10),
                      Text(
                        'COBRAR ${_formatAmount(_amount)}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

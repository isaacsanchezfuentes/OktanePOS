import 'package:flutter/material.dart';
import '../services/rbac_service.dart';

class PrintAuthorizationDialog extends StatefulWidget {
  final String waiterId;
  final double amount;
  final RbacService? rbacService;

  const PrintAuthorizationDialog({
    super.key,
    required this.waiterId,
    required this.amount,
    this.rbacService,
  });

  static Future<bool> show(
    BuildContext context, {
    required String waiterId,
    required double amount,
    RbacService? rbacService,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => PrintAuthorizationDialog(
        waiterId: waiterId,
        amount: amount,
        rbacService: rbacService,
      ),
    );
    return result == true;
  }

  @override
  State<PrintAuthorizationDialog> createState() => _PrintAuthorizationDialogState();
}

class _PrintAuthorizationDialogState extends State<PrintAuthorizationDialog> {
  late final RbacService _rbacService;
  final TextEditingController _pinController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool _isFallbackMode = false;
  bool _isVerifying = false;

  @override
  void initState() {
    super.initState();
    _rbacService = widget.rbacService ?? RbacService();
  }

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _verifyAndProceed() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isVerifying = true);

    final inputPin = _pinController.text.trim();

    if (_isFallbackMode) {
      // Waiter fallback PIN verification
      final isValid = await _rbacService.verifyWaiterPin(inputPin);
      if (isValid) {
        await _rbacService.logPrintAuditOverride(
          waiterId: widget.waiterId,
          reason: 'Autorizado por ausencia de superior (PIN Mesero)',
          amount: widget.amount,
        );
        if (mounted) {
          Navigator.pop(context, true);
        }
      } else {
        if (mounted) {
          setState(() => _isVerifying = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('❌ PIN de Mesero incorrecto (Default: 0000)'), backgroundColor: Colors.red),
          );
        }
      }
    } else {
      // Manager PIN verification
      final isValid = await _rbacService.verifyManagerPin(inputPin);
      if (isValid) {
        if (mounted) {
          Navigator.pop(context, true);
        }
      } else {
        if (mounted) {
          setState(() => _isVerifying = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('❌ PIN de Gerente incorrecto (Default: 1234)'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final titleText = _isFallbackMode 
        ? 'Autorización por Contingencia' 
        : 'Autorización de Impresión';

    final labelText = _isFallbackMode 
        ? 'PIN de Mesero (Contingencia)' 
        : 'PIN de Gerente / Supervisor';

    return AlertDialog(
      title: Row(
        children: [
          Icon(_isFallbackMode ? Icons.warning_amber_rounded : Icons.lock_outlined, color: Colors.indigo),
          const SizedBox(width: 8),
          Flexible(child: Text(titleText, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
        ],
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _isFallbackMode
                  ? 'Si el supervisor no está en piso, ingrese su PIN propio para emitir el ticket. Esta acción quedará auditada.'
                  : 'Ingrese el PIN de autorización de gerente para enviar el ticket a la impresora.',
              style: const TextStyle(fontSize: 13, color: Colors.black87),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _pinController,
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 4,
              autofocus: true,
              decoration: InputDecoration(
                labelText: labelText,
                prefixIcon: const Icon(Icons.pin),
                border: const OutlineInputBorder(),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Ingrese el PIN';
                if (v.trim().length < 4) return '4 dígitos requeridos';
                return null;
              },
            ),
            const SizedBox(height: 8),
            if (!_isFallbackMode)
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _isFallbackMode = true;
                    _pinController.clear();
                  });
                },
                icon: const Icon(Icons.person_pin, size: 18, color: Colors.orange),
                label: const Text(
                  'Autorizar por ausencia de superior',
                  style: TextStyle(fontSize: 12, color: Colors.orange, fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isVerifying ? null : () => Navigator.pop(context, false),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _isVerifying ? null : _verifyAndProceed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.indigo[800],
            foregroundColor: Colors.white,
          ),
          child: _isVerifying
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('AUTORIZAR'),
        ),
      ],
    );
  }
}

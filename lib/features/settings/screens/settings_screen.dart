import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:oktane_pos/providers/auth_provider.dart';
import '../../auth/services/rbac_service.dart';
import '../../printer/screens/printer_settings_screen.dart';
import '../../cash_cut/screens/shifts_history_screen.dart';
import '../../cash_cut/services/shift_policy_service.dart';
import 'menu_management_screen.dart';

class SettingsScreen extends StatefulWidget {
  final RbacService? rbacService;
  final ShiftPolicyService? policyService;

  const SettingsScreen({
    super.key,
    this.rbacService,
    this.policyService,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final RbacService _rbacService;
  late final ShiftPolicyService _policyService;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  int _currentPolicyMode = 1;
  String _paymentBaseUrl = 'https://pay.oktane.io/o/';

  @override
  void initState() {
    super.initState();
    _rbacService = widget.rbacService ?? RbacService();
    _policyService = widget.policyService ?? ShiftPolicyService();
    _loadPolicyAndSettings();
  }

  Future<void> _loadPolicyAndSettings() async {
    final mode = await _policyService.getPolicyMode();
    final url = await _storage.read(key: 'payment_base_url');
    if (mounted) {
      setState(() {
        _currentPolicyMode = mode;
        if (url != null && url.isNotEmpty) {
          _paymentBaseUrl = url;
        }
      });
    }
  }

  Future<bool> _ensureManagerAccess() async {
    final auth = context.read<AuthProvider>();
    if (_rbacService.isManagerOrAdmin(auth.rol)) {
      return true;
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
              const Text('El acceso a la configuración requiere autorización de supervisor.'),
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

    return granted == true;
  }

  void _showPolicyDialog() async {
    if (!await _ensureManagerAccess()) return;

    int tempMode = _currentPolicyMode;

    if (!mounted) return;

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
            children: [
              RadioListTile<int>(
                title: const Text('Modo 1: 1 Turno por día (Default)'),
                value: 1,
                groupValue: tempMode,
                onChanged: (val) => setModalState(() => tempMode = val!),
              ),
              RadioListTile<int>(
                title: const Text('Modo 2: Hasta 3 Turnos por día'),
                value: 2,
                groupValue: tempMode,
                onChanged: (val) => setModalState(() => tempMode = val!),
              ),
              RadioListTile<int>(
                title: const Text('Modo 3: Turnos Libres / Manuales'),
                value: 3,
                groupValue: tempMode,
                onChanged: (val) => setModalState(() => tempMode = val!),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () async {
                await _policyService.setPolicyMode(tempMode);
                if (mounted) {
                  setState(() => _currentPolicyMode = tempMode);
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('✅ ${_policyService.getModeDescription(tempMode)}')),
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

  void _showPaymentGatewayDialog() async {
    if (!await _ensureManagerAccess()) return;

    final urlCtrl = TextEditingController(text: _paymentBaseUrl);
    final formKey = GlobalKey<FormState>();

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.qr_code_2, color: Colors.teal),
            SizedBox(width: 8),
            Text('Pasarela y QR de Cobro', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'URL Base de la Pasarela de Pago para Tickets Térmicos y Pre-cuentas.',
                style: TextStyle(fontSize: 12, color: Colors.black87),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: urlCtrl,
                keyboardType: TextInputType.url,
                decoration: const InputDecoration(
                  labelText: 'URL Base de Pago',
                  hintText: 'https://pay.oktane.io/o/',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Requerido';
                  if (!v.startsWith('http://') && !v.startsWith('https://')) {
                    return 'Debe iniciar con http:// o https://';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              final newUrl = urlCtrl.text.trim();
              await _storage.write(key: 'payment_base_url', value: newUrl);
              if (mounted) {
                setState(() => _paymentBaseUrl = newUrl);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('✅ URL Base de cobro actualizada: $newUrl'), backgroundColor: Colors.teal[800]),
                );
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = Supabase.instance.client.auth.currentUser;
    final userEmail = currentUser?.email ?? 'Usuario POS';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración del Sistema', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // User Card Header
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: Colors.blue,
                child: Icon(Icons.person, color: Colors.white),
              ),
              title: Text(userEmail, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Oktane POS Terminal'),
            ),
          ),
          const SizedBox(height: 16),

          // Menu Catalog Management
          ListTile(
            leading: const Icon(Icons.restaurant_menu, color: Colors.deepOrange),
            title: const Text('Catálogo de Menú y Precios', style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: const Text('Administrar productos, precios y categorías'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              if (await _ensureManagerAccess()) {
                if (context.mounted) {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const MenuManagementScreen()));
                }
              }
            },
          ),
          const Divider(),

          // Thermal Printer Settings
          ListTile(
            leading: const Icon(Icons.print, color: Colors.indigo),
            title: const Text('Impresora Térmica Bluetooth', style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: const Text('Escanear y conectar impresoras de recibos'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const PrinterSettingsScreen()));
            },
          ),
          const Divider(),

          // Payment Gateway Settings
          ListTile(
            leading: const Icon(Icons.qr_code_2, color: Colors.teal),
            title: const Text('Pasarela de Pago y URL QR', style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(_paymentBaseUrl),
            trailing: const Icon(Icons.chevron_right),
            onTap: _showPaymentGatewayDialog,
          ),
          const Divider(),

          // Shift Policy Settings
          ListTile(
            leading: const Icon(Icons.tune, color: Colors.blue),
            title: const Text('Política de Turnos y Cierres', style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(_policyService.getModeDescription(_currentPolicyMode)),
            trailing: const Icon(Icons.chevron_right),
            onTap: _showPolicyDialog,
          ),
          const Divider(),

          // Shift Audit History
          ListTile(
            leading: const Icon(Icons.history, color: Colors.purple),
            title: const Text('Historial y Auditoría de Turnos', style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: const Text('Ver cierres Z pasados y re-imprimir recibos'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const ShiftsHistoryScreen()));
            },
          ),
        ],
      ),
    );
  }
}

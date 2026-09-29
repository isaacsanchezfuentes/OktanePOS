import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:oktane_pos/providers/auth_provider.dart';
import '../../auth/services/rbac_service.dart';
import '../../printer/screens/printer_settings_screen.dart';
import '../../cash_cut/screens/shifts_history_screen.dart';
import '../../cash_cut/services/shift_policy_service.dart';
import 'package:oktane_pos/core/theme/theme_service.dart';
import 'package:oktane_pos/core/localization/app_locale.dart';
import 'package:oktane_pos/ui/screens/login_screen.dart';
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
                if (context.mounted) {
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

  String _getThemeName(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.slateIndustrial:
        return tr('finish_industrial');
      case AppThemeMode.classicBlue:
        return 'Azul Clásico (Aluminio Anodizado)';
      case AppThemeMode.classicPink:
        return tr('finish_rose_gold');
    }
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          color: Color(0xFF94A3B8),
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  void _showThemeSelectionDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.palette, color: Colors.amber),
            SizedBox(width: 8),
            Text('Personalización / Apariencia', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<AppThemeMode>(
              title: Text(tr('finish_industrial')),
              value: AppThemeMode.slateIndustrial,
              groupValue: ThemeService.instance.currentTheme,
              onChanged: (val) {
                if (val != null) {
                  ThemeService.instance.setTheme(val);
                  Navigator.pop(ctx);
                  setState(() {});
                }
              },
            ),
            RadioListTile<AppThemeMode>(
              title: const Text('Azul Clásico (Aluminio Anodizado)'),
              value: AppThemeMode.classicBlue,
              groupValue: ThemeService.instance.currentTheme,
              onChanged: (val) {
                if (val != null) {
                  ThemeService.instance.setTheme(val);
                  Navigator.pop(ctx);
                  setState(() {});
                }
              },
            ),
            RadioListTile<AppThemeMode>(
              title: Text(tr('finish_rose_gold')),
              value: AppThemeMode.classicPink,
              groupValue: ThemeService.instance.currentTheme,
              onChanged: (val) {
                if (val != null) {
                  ThemeService.instance.setTheme(val);
                  Navigator.pop(ctx);
                  setState(() {});
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(tr('cancel'))),
        ],
      ),
    );
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.logout, color: Colors.red),
            SizedBox(width: 8),
            Text('Cerrar Sesión', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text('¿Estás seguro de que deseas salir de la aplicación?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(tr('cancel'))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              final auth = context.read<AuthProvider>();
              await auth.logout();
              if (mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
            child: const Text('Cerrar Sesión'),
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
        title: Text(tr('general_settings'), style: const TextStyle(fontWeight: FontWeight.bold)),
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

          // Theme Customization Section
          ListTile(
            leading: const Icon(Icons.palette, color: Colors.amber),
            title: Text(tr('lcd_display_settings'), style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(_getThemeName(ThemeService.instance.currentTheme)),
            trailing: const Icon(Icons.chevron_right),
            onTap: _showThemeSelectionDialog,
          ),
          const Divider(),

          // Selector de Acabado Faceplate
          _buildSectionHeader(tr('faceplate_finish')),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF334155)),
            ),
            child: Column(
              children: [
                RadioListTile<AppThemeMode>(
                  title: Text(
                    tr('finish_industrial'),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  secondary: const Icon(Icons.shield_outlined, color: Color(0xFF94A3B8)),
                  activeColor: const Color(0xFF38BDF8),
                  value: AppThemeMode.slateIndustrial,
                  groupValue: ThemeService.instance.currentTheme,
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        ThemeService.instance.setTheme(val);
                      });
                    }
                  },
                ),
                const Divider(color: Color(0xFF334155), height: 1),
                RadioListTile<AppThemeMode>(
                  title: Text(
                    tr('finish_rose_gold'),
                    style: const TextStyle(color: Color(0xFFF7B1A5), fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  secondary: const Icon(Icons.circle, color: Color(0xFFE89E90)),
                  activeColor: const Color(0xFFE89E90),
                  value: AppThemeMode.classicPink,
                  groupValue: ThemeService.instance.currentTheme,
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        ThemeService.instance.setTheme(val);
                      });
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

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
            title: Text(tr('printer_settings'), style: const TextStyle(fontWeight: FontWeight.bold)),
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
            title: Text(tr('shift_policy'), style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(_policyService.getModeDescription(_currentPolicyMode)),
            trailing: const Icon(Icons.chevron_right),
            onTap: _showPolicyDialog,
          ),
          const Divider(),

          // Shift Audit History
          ListTile(
            leading: const Icon(Icons.history, color: Colors.purple),
            title: Text(tr('shifts_audit_history'), style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: const Text('Ver cierres Z pasados y re-imprimir recibos'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const ShiftsHistoryScreen()));
            },
          ),
          const Divider(),
          const SizedBox(height: 16),

          // Logout Action Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[700],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.logout, size: 20),
              label: const Text('CERRAR SESIÓN', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              onPressed: _confirmLogout,
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

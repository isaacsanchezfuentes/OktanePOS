import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../providers/paquetes_provider.dart';
import '../../../providers/auth_provider.dart';
import '../login_screen.dart';
import 'lista_ruta_screen.dart';
import '../admin/carga_camioneta_screen.dart';
import '../admin/dashboard_web_screen.dart';

class SeleccionarRutaScreen extends StatefulWidget {
  const SeleccionarRutaScreen({super.key});

  @override
  State<SeleccionarRutaScreen> createState() => _SeleccionarRutaScreenState();
}

class _SeleccionarRutaScreenState extends State<SeleccionarRutaScreen> {
  bool _isLoading = true;
  List<dynamic> _rutas = [];

  @override
  void initState() {
    super.initState();
    _fetchRutas();
  }

  Future<void> _fetchRutas() async {
    final auth = context.read<AuthProvider>();
    final provider = context.read<PaquetesProvider>();

    if (auth.rol == 'CHOFER') {
      try {
        final viaje = await Supabase.instance.client
            .from('viajes')
            .select()
            .eq('chofer_id', auth.userId ?? '')
            .eq('estado', 'EN_RUTA')
            .maybeSingle();

        if (viaje != null && mounted) {
          provider.setViajeActivo(viaje['id'].toString());
          provider.setRutaActiva(viaje['ruta_id'].toString(), '');
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const ListaRutaScreen()),
          );
          return;
        }
      } catch (e) {
        debugPrint('Error comprobando viaje activo: $e');
      }
    }

    try {
      debugPrint('📡 Intentando cargar rutas desde Supabase...');
      final response = await Supabase.instance.client
          .from('rutas')
          .select()
          .eq('activa', true)
          .order('nombre');
      
      setState(() {
        _rutas = response;
        _isLoading = false;
      });
      debugPrint('✅ Rutas cargadas: ${_rutas.length}');
    } catch (e) {
      debugPrint("❌ Error cargando rutas: $e");
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // 🛠️ ALTA DE RUTA CON ID GENERADO EXPLICITAMENTE
  Future<void> _mostrarDialogoCrearRuta() async {
    final nombreCtrl = TextEditingController();
    final zonaCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool guardando = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.add_road, color: Colors.blue),
              SizedBox(width: 8),
              Text('Nueva Ruta', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nombreCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nombre de Ruta',
                    hintText: 'Ej: Huatulco - Puerto',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: zonaCtrl,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    labelText: 'Código Zona (Prefijo)',
                    hintText: 'Ej: HUA',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: guardando ? null : () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: guardando
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setModalState(() => guardando = true);

                      try {
                        // 🛠️ Generar ID único para evitar violación de NOT NULL
                        final String nuevaRutaId = DateTime.now().millisecondsSinceEpoch.toString();

                        await Supabase.instance.client.from('rutas').insert({
                          'id': nuevaRutaId,
                          'nombre': nombreCtrl.text.trim(),
                          'codigo_zona': zonaCtrl.text.trim().toUpperCase(),
                          'activa': true,
                        });

                        if (context.mounted) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('✅ Ruta registrada'), backgroundColor: Colors.green),
                          );
                          _fetchRutas();
                        }
                      } catch (e) {
                        setModalState(() => guardando = false);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                          );
                        }
                      }
                    },
              child: guardando
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Crear'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final bool isAdmin = auth.rol == 'ADMIN';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rutas', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          if (isAdmin) ...[
            IconButton(
              icon: const Icon(Icons.analytics_outlined, color: Colors.indigo),
              tooltip: 'Dashboard Ejecutivo',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const DashboardWebScreen()),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add_road, color: Colors.green),
              tooltip: 'Dar de Alta Ruta',
              onPressed: _mostrarDialogoCrearRuta,
            ),
            IconButton(
              icon: const Icon(Icons.local_shipping, color: Colors.blue),
              tooltip: 'Cargar Camioneta',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CargaCamionetaScreen()),
              ),
            ),
          ],
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() => _isLoading = true);
              _fetchRutas();
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await Supabase.instance.client.auth.signOut();
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _rutas.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.map_outlined, size: 80, color: Colors.grey),
                      const SizedBox(height: 10),
                      const Text('No hay rutas activas disponibles'),
                      if (isAdmin) ...[
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _mostrarDialogoCrearRuta,
                          icon: const Icon(Icons.add),
                          label: const Text('Crear Primera Ruta'),
                        ),
                      ],
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _rutas.length,
                  itemBuilder: (context, index) {
                    final ruta = _rutas[index];
                    return Card(
                      elevation: 3,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue.withOpacity(0.1),
                          child: const Icon(Icons.alt_route, color: Colors.blue),
                        ),
                        title: Text(ruta['nombre'] ?? 'Ruta sin nombre', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('Zona: ${ruta['codigo_zona']}'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          context.read<PaquetesProvider>().setRutaActiva(
                            ruta['id'].toString(),
                            ruta['codigo_zona'].toString(),
                          );

                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const ListaRutaScreen()),
                          );
                        },
                      ),
                    );
                  },
                ),
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
              onPressed: _mostrarDialogoCrearRuta,
              icon: const Icon(Icons.add_road),
              label: const Text('NUEVA RUTA'),
            )
          : null,
    );
  }
}

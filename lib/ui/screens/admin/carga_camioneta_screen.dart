import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../providers/paquetes_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../data/models/paquete_model.dart';
import '../chofer/scanner_qr_screen.dart';
import 'recepcion_paquete_screen.dart';

class CargaCamionetaScreen extends StatefulWidget {
  const CargaCamionetaScreen({super.key});

  @override
  State<CargaCamionetaScreen> createState() => _CargaCamionetaScreenState();
}

class _CargaCamionetaScreenState extends State<CargaCamionetaScreen> {
  bool _isLoading = false;
  List<dynamic> _rutas = [];
  List<dynamic> _choferes = [];
  
  String? _selectedRutaId;
  String? _selectedChoferId;

  @override
  void initState() {
    super.initState();
    _fetchSetupData();
  }

  Future<void> _fetchSetupData() async {
    setState(() => _isLoading = true);
    try {
      final rutasRes = await Supabase.instance.client.from('rutas').select().eq('activa', true);
      final choferesRes = await Supabase.instance.client.from('perfiles').select().eq('rol', 'CHOFER');
      
      setState(() {
        _rutas = rutasRes;
        _choferes = choferesRes;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading setup data: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _iniciarCarga() async {
    if (_selectedRutaId == null || _selectedChoferId == null) return;
    
    setState(() => _isLoading = true);
    try {
      final codigoViaje = 'VJ-${DateTime.now().millisecondsSinceEpoch}';
      final res = await Supabase.instance.client.from('viajes').insert({
        'ruta_id': _selectedRutaId,
        'chofer_id': _selectedChoferId,
        'estado': 'EN_CARGA',
        'codigo_viaje': codigoViaje,
      }).select().single();

      if (mounted) {
        context.read<PaquetesProvider>().setViajeActivo(res['id'].toString());
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Error iniciando carga: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pistolearQR() async {
    final provider = context.read<PaquetesProvider>();
    final scannedCode = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (context) => const ScannerQrScreen(tituloAccion: 'Cargar a Camioneta')),
    );

    if (scannedCode != null && scannedCode.startsWith('PKG-')) {
      try {
        await Supabase.instance.client.from('paquetes').update({
          'viaje_id': provider.viajeIdActivo,
          'estado': 'A_BORDO',
        }).eq('tracking_number', scannedCode);
        
        setState(() {}); // Refrescar lista
      } catch (e) {
        debugPrint('Error al vincular paquete: $e');
      }
    }
  }

  Future<void> _despachar() async {
    final provider = context.read<PaquetesProvider>();
    if (provider.viajeIdActivo == null) return;

    try {
      await Supabase.instance.client.from('viajes').update({
        'estado': 'EN_RUTA',
      }).eq('id', provider.viajeIdActivo!);

      if (mounted) {
        provider.setViajeActivo(null);
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('Error al despachar: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PaquetesProvider>();
    final viajeId = provider.viajeIdActivo;

    return Scaffold(
      appBar: AppBar(title: const Text('Manifiesto de Carga')),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : viajeId == null ? _buildSelector() : _buildAnden(viajeId),
    );
  }

  Widget _buildSelector() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Configurar Nuevo Viaje', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(labelText: 'Seleccionar Ruta', border: OutlineInputBorder()),
            items: _rutas.map((r) => DropdownMenuItem(
              value: r['id'].toString(), 
              child: Text('${r['nombre'] ?? 'Ruta'} (${r['codigo_zona'] ?? ''})'),
            )).toList(),
            onChanged: (val) => setState(() => _selectedRutaId = val),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(labelText: 'Seleccionar Chofer', border: OutlineInputBorder()),
            items: _choferes.map((c) => DropdownMenuItem(
              value: c['id'].toString(), 
              child: Text(
                (c['email'] ?? c['id'])
                    .toString()
                    .split('@')
                    .first
                    .toUpperCase(),
              ),
            )).toList(),
            onChanged: (val) => setState(() => _selectedChoferId = val),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _selectedRutaId != null && _selectedChoferId != null ? _iniciarCarga : null,
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)),
            child: const Text('INICIAR CARGA'),
          )
        ],
      ),
    );
  }

  Widget _buildAnden(String id) {
    return Column(
      children: [
        _buildAndenHeader(),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const RecepcionPaqueteScreen())).then((_) => setState((){})),
                  icon: const Icon(Icons.add_box),
                  label: const Text('NUEVO'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _pistolearQR,
                  icon: const Icon(Icons.qr_code_scanner),
                  label: const Text('PISTOLEAR'),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: FutureBuilder<List<dynamic>>(
            future: Supabase.instance.client.from('paquetes').select().eq('viaje_id', id),
            builder: (context, snapshot) {
              final list = snapshot.data ?? [];
              return ListView.builder(
                itemCount: list.length,
                itemBuilder: (context, i) {
                  final p = PaqueteModel.fromJson(list[i]);
                  return ListTile(
                    leading: const Icon(Icons.inventory_2, color: Colors.blue),
                    title: Text(p.trackingNumber),
                    subtitle: Text(p.destinatarioNombre),
                    trailing: const Icon(Icons.check_circle, color: Colors.green),
                  );
                },
              );
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _despachar,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, padding: const EdgeInsets.all(16)),
            child: const Text('DESPACHAR CAMIONETA', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        )
      ],
    );
  }

  Widget _buildAndenHeader() {
    return Container(
      color: Colors.blue[50],
      padding: const EdgeInsets.all(16),
      child: const Row(
        children: [
          Icon(Icons.local_shipping, size: 40, color: Colors.blue),
          SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('CARGA EN PROGRESO', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('Andén: 01 | Escaneando paquetes...'),
            ],
          )
        ],
      ),
    );
  }
}

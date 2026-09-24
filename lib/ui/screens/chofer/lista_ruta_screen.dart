import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../providers/paquetes_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../data/models/paquete_model.dart';
import 'scanner_qr_screen.dart';
import '../admin/recepcion_paquete_screen.dart';
import '../admin/detalle_paquete_screen.dart';
import 'confirmar_entrega_screen.dart';
import '../login_screen.dart';

class ListaRutaScreen extends StatefulWidget {
  const ListaRutaScreen({super.key});
  @override
  State<ListaRutaScreen> createState() => _ListaRutaScreenState();
}

class _ListaRutaScreenState extends State<ListaRutaScreen> {
  Future<List<dynamic>>? _paquetesFuture;

  @override
  void initState() {
    super.initState();
    _fetchPaquetes();
  }

  void _fetchPaquetes() {
    final provider = context.read<PaquetesProvider>();
    setState(() {
      _paquetesFuture = Supabase.instance.client
          .from('paquetes')
          .select()
          .eq('ruta_id', provider.rutaIdActiva ?? '')
          .order('created_at', ascending: false);
    });
  }

  String _estadoToString(EstadoPaquete estado) {
    switch (estado) {
      case EstadoPaquete.recibido: return 'RECIBIDO';
      case EstadoPaquete.aBordo: return 'A_BORDO';
      case EstadoPaquete.bodegaDestino: return 'BODEGA_DESTINO';
      case EstadoPaquete.enReparto: return 'EN_REPARTO';
      case EstadoPaquete.entregado: return 'ENTREGADO';
      case EstadoPaquete.incidencia: return 'INCIDENCIA';
      case EstadoPaquete.cancelado: return 'CANCELADO';
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final provider = context.watch<PaquetesProvider>();

    final user = Supabase.instance.client.auth.currentUser;
    final bool isAdmin = (auth.rol == 'ADMIN') ||
        (user?.email?.toLowerCase().contains('admin') ?? false) ||
        (user?.userMetadata?['rol']?.toString().toUpperCase() == 'ADMIN');

    return Scaffold(
      appBar: AppBar(
        title: Text(isAdmin ? 'Monitoreo: ${provider.codigoZonaActiva}' : 'Mi Ruta: ${provider.codigoZonaActiva}'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchPaquetes),
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
      body: _paquetesFuture == null
          ? const Center(child: CircularProgressIndicator())
          : FutureBuilder<List<dynamic>>(
        future: _paquetesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));

          final data = snapshot.data ?? [];
          if (data.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.inventory_2_outlined, size: 80, color: Colors.grey),
                  const SizedBox(height: 10),
                  const Text('No hay paquetes en esta ruta', style: TextStyle(color: Colors.grey)),
                  if (isAdmin) ...[
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const RecepcionPaqueteScreen())).then((_) => _fetchPaquetes()),
                      icon: const Icon(Icons.add_box),
                      label: const Text('REGISTRAR PAQUETE / GENERAR QR'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                    ),
                  ],
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(10),
            itemCount: data.length,
            itemBuilder: (context, index) {
              final p = PaqueteModel.fromJson(data[index]);
              return _buildPaqueteCard(p);
            },
          );
        },
      ),
      floatingActionButton: isAdmin ? _buildAdminFAB() : null,
    );
  }

  Widget _buildAdminFAB() {
    return FloatingActionButton.extended(
      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const RecepcionPaqueteScreen())).then((_) => _fetchPaquetes()),
      label: const Text('RECEPCIÓN'),
      icon: const Icon(Icons.add_box),
    );
  }

  Widget _buildPaqueteCard(PaqueteModel p) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: Text(p.trackingNumber, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('Dest: ${p.destinatarioNombre}'),
            trailing: _buildStatusChip(p.estado),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: SizedBox(
              width: double.infinity,
              child: _buildActionButtons(p),
            ),
          ),
          const Divider(height: 1),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              TextButton.icon(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => DetallePaqueteScreen(paquete: p))),
                icon: const Icon(Icons.info_outline, size: 18),
                label: const Text('Detalle', style: TextStyle(fontSize: 12)),
              ),
              // 🛠️ Botón de Cancelar QR integrado limpiamente
              TextButton.icon(
                onPressed: () => _cancelarOAnularPaquete(p),
                icon: const Icon(Icons.cancel_outlined, color: Colors.red, size: 18),
                label: const Text('Cancelar QR', style: TextStyle(color: Colors.red, fontSize: 12)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _subirABordoConValidacion(PaqueteModel p) async {
    final scanned = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => ScannerQrScreen(
          expectedTrackingNumber: p.trackingNumber,
          tituloAccion: 'Validar Carga: ${p.trackingNumber}',
        ),
      ),
    );

    if (scanned == p.trackingNumber && mounted) {
      await _cambiarEstadoSimple(p, EstadoPaquete.aBordo);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Paquete ${p.trackingNumber} subido A BORDO'),
            backgroundColor: Colors.indigo,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _recibirEnBodegaConScan(PaqueteModel p) async {
    final scanned = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => ScannerQrScreen(
          expectedTrackingNumber: p.trackingNumber,
          tituloAccion: 'Recibir en Bodega: ${p.trackingNumber}',
        ),
      ),
    );

    if (scanned == p.trackingNumber && mounted) {
      await _cambiarEstadoSimple(p, EstadoPaquete.bodegaDestino);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('📦 Paquete ${p.trackingNumber} recibido en BODEGA'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _iniciarEntregaFinal(PaqueteModel p) async {
    final scanned = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => ScannerQrScreen(
          expectedTrackingNumber: p.trackingNumber,
          tituloAccion: 'Validar Entrega: ${p.trackingNumber}',
        ),
      ),
    );

    if (scanned == p.trackingNumber && mounted) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ConfirmarEntregaScreen(
            trackingNumber: p.trackingNumber,
            paqueteId: p.id,
          ),
        ),
      );
      if (mounted) {
        _fetchPaquetes();
      }
    }
  }

  Widget _buildActionButtons(PaqueteModel p) {
    final String estadoStr = p.estado.name.toUpperCase();

    if (p.estado == EstadoPaquete.recibido || estadoStr == 'RECIBIDO') {
      return ElevatedButton.icon(
        onPressed: () => _subirABordoConValidacion(p),
        icon: const Icon(Icons.local_shipping),
        label: const Text('SUBIR A BORDO'),
        style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
      );
    }

    if (p.estado == EstadoPaquete.aBordo || estadoStr == 'A_BORDO' || estadoStr == 'ABORDO') {
      return ElevatedButton.icon(
        onPressed: () => _recibirEnBodegaConScan(p),
        icon: const Icon(Icons.warehouse),
        label: const Text('RECIBIR EN BODEGA'),
        style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
      );
    }

    if (p.estado == EstadoPaquete.bodegaDestino || estadoStr == 'BODEGA_DESTINO' || estadoStr == 'BODEGADESTINO') {
      return Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: () => _cambiarEstadoSimple(p, EstadoPaquete.enReparto),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.purple, foregroundColor: Colors.white),
              child: const Text('A REPARTO', style: TextStyle(fontSize: 12)),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ElevatedButton(
              onPressed: () => _iniciarEntregaFinal(p),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
              child: const Text('VENTANILLA', style: TextStyle(fontSize: 12)),
            ),
          ),
        ],
      );
    }

    if (p.estado == EstadoPaquete.enReparto || estadoStr == 'EN_REPARTO' || estadoStr == 'ENREPARTO') {
      return ElevatedButton.icon(
        onPressed: () => _iniciarEntregaFinal(p),
        icon: const Icon(Icons.home),
        label: const Text('ENTREGAR EN DOMICILIO'),
        style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
      );
    }

    if (p.estado == EstadoPaquete.entregado || estadoStr == 'ENTREGADO') {
      return OutlinedButton.icon(
        onPressed: null,
        icon: const Icon(Icons.check_circle, color: Colors.green),
        label: const Text('ENTREGA CONCLUIDA', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
        style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.green)),
      );
    }

    if (p.estado == EstadoPaquete.cancelado || estadoStr == 'CANCELADO') {
      return OutlinedButton.icon(
        onPressed: null,
        icon: const Icon(Icons.cancel, color: Colors.grey),
        label: const Text('GUÍA ANULADA', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
        style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.grey)),
      );
    }

    return const SizedBox.shrink();
  }

  Future<void> _cambiarEstadoSimple(PaqueteModel p, EstadoPaquete nuevoEstado) async {
    try {
      final String estadoStr = _estadoToString(nuevoEstado);

      await Supabase.instance.client
          .from('paquetes')
          .update({'estado': estadoStr})
          .eq('id', p.id);

      final auth = context.read<AuthProvider>();
      final user = Supabase.instance.client.auth.currentUser;
      final String? choferId = auth.userId ?? user?.id;

      final Map<String, dynamic> eventoData = {
        'paquete_id': p.id,
        'estado_resultante': estadoStr,
      };

      if (choferId != null && choferId.isNotEmpty && !choferId.startsWith('00000000')) {
        eventoData['chofer_id'] = choferId;
      }

      await Supabase.instance.client.from('eventos_entrega').insert(eventoData);

      debugPrint('✅ Estado actualizado a $estadoStr');
      _fetchPaquetes();
    } catch (e) {
      debugPrint('❌ Error al cambiar estado: $e');
      _fetchPaquetes();
    }
  }

  // 🛠️ Función segura de anulación/cancelación de QR sin campos extraños
  Future<void> _cancelarOAnularPaquete(PaqueteModel p) async {
    final controller = TextEditingController();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Anular / Cancelar Guía'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('¿Estás seguro de cancelar este QR? Esta acción marcará el paquete como cancelado.'),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: 'Motivo de la cancelación',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Volver')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sí, Cancelar QR'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await Supabase.instance.client
            .from('paquetes')
            .update({'estado': 'CANCELADO'})
            .eq('id', p.id);

        if (controller.text.trim().isNotEmpty) {
          await Supabase.instance.client.from('paquetes_comentarios').insert({
            'paquete_id': p.id,
            'comentario': 'CANCELACIÓN DE QR: ${controller.text.trim()}',
          });
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('🚫 Guía / QR cancelado correctamente'), backgroundColor: Colors.red),
          );
          _fetchPaquetes();
        }
      } catch (e) {
        debugPrint('❌ Error al cancelar guía: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al cancelar: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Widget _buildStatusChip(EstadoPaquete estado) {
    Color color = Colors.grey;
    switch (estado) {
      case EstadoPaquete.recibido: color = Colors.blue; break;
      case EstadoPaquete.aBordo: color = Colors.indigo; break;
      case EstadoPaquete.bodegaDestino: color = Colors.orange; break;
      case EstadoPaquete.enReparto: color = Colors.purple; break;
      case EstadoPaquete.entregado: color = Colors.green; break;
      case EstadoPaquete.incidencia: color = Colors.red; break;
      case EstadoPaquete.cancelado: color = Colors.black54; break;
    }
    return Chip(
      label: Text(_estadoToString(estado), style: const TextStyle(fontSize: 10, color: Colors.white)),
      backgroundColor: color,
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
    );
  }
}

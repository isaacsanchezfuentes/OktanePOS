import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'recepcion_paquete_screen.dart';
import '../../../data/models/paquete_model.dart';
import '../../../core/services/etiqueta_service.dart';

class DashboardWebScreen extends StatefulWidget {
  const DashboardWebScreen({super.key});

  @override
  State<DashboardWebScreen> createState() => _DashboardWebScreenState();
}

class _DashboardWebScreenState extends State<DashboardWebScreen> {
  bool _isLoading = true;
  List<dynamic> _paquetesRecientes = [];
  int _conteoEnTransito = 0;
  int _conteoEntregadosHoy = 0;
  int _conteoRecibidos = 0;
  double _totalRecaudadoHoy = 0.0;

  @override
  void initState() {
    super.initState();
    _cargarMetricas();
  }

  Future<void> _cargarMetricas() async {
    setState(() => _isLoading = true);
    try {
      final List<dynamic> paquetesRes = await Supabase.instance.client
          .from('paquetes')
          .select()
          .order('created_at', ascending: false)
          .limit(50);

      final List<dynamic> rutasRes = await Supabase.instance.client
          .from('rutas')
          .select('id, nombre, codigo_zona');

      final Map<String, dynamic> rutasMap = {
        for (var r in rutasRes) r['id'].toString(): r
      };

      int transito = 0;
      int entregadosHoy = 0;
      int recibidos = 0;
      double recaudadoHoy = 0.0;

      final now = DateTime.now();

      for (var p in paquetesRes) {
        final estado = p['estado']?.toString().toUpperCase() ?? '';
        final double monto = (p['monto_envio'] as num?)?.toDouble() ?? 
            double.tryParse(p['monto_envio']?.toString() ?? '0') ?? 0.0;
        
        final createdLocal = DateTime.tryParse(p['created_at']?.toString() ?? '')?.toLocal();
        final bool isToday = createdLocal != null &&
            createdLocal.year == now.year &&
            createdLocal.month == now.month &&
            createdLocal.day == now.day;

        final rutaId = p['ruta_id']?.toString();
        if (rutaId != null && rutasMap.containsKey(rutaId)) {
          p['ruta_info'] = rutasMap[rutaId];
        }

        if (estado == 'ENTREGADO') {
          entregadosHoy++;
          if (isToday) recaudadoHoy += monto;
        } else if (estado == 'A_BORDO' || estado == 'BODEGA_DESTINO' || estado == 'EN_REPARTO') {
          transito++;
        } else if (estado == 'RECIBIDO') {
          recibidos++;
          if (isToday) recaudadoHoy += monto;
        }
      }

      setState(() {
        _paquetesRecientes = paquetesRes;
        _conteoEnTransito = transito;
        _conteoEntregadosHoy = entregadosHoy;
        _conteoRecibidos = recibidos;
        _totalRecaudadoHoy = recaudadoHoy;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error cargando métricas del dashboard: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _mostrarDetallePaquete(Map<String, dynamic> rawData) {
    final paquete = PaqueteModel.fromJson(rawData);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.qr_code, color: Colors.blue),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                paquete.trackingNumber,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 320,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: QrImageView(
                    data: paquete.trackingNumber,
                    version: QrVersions.auto,
                    size: 180.0,
                  ),
                ),
                const SizedBox(height: 14),
                const Divider(),
                _infoRow('Remitente:', paquete.remitenteNombre),
                _infoRow('Destinatario:', paquete.destinatarioNombre),
                _infoRow('Dirección:', paquete.destinatarioDireccion),
                _infoRow('Teléfono:', paquete.destinatarioTelefono),
                _infoRow('Monto:', '\$${paquete.montoEnvio.toStringAsFixed(2)}'),
                _infoRow('Estado:', paquete.estado.name.toUpperCase()),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cerrar'),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.print, size: 16),
            label: const Text('Reimprimir'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
            onPressed: () async {
              await EtiquetaService.imprimirEtiqueta(
                trackingNumber: paquete.trackingNumber,
                destinatario: paquete.destinatarioNombre,
                direccion: paquete.destinatarioDireccion,
                telefono: paquete.destinatarioTelefono,
                monto: paquete.montoEnvio,
                esSpei: false,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label ', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 13, color: Colors.black87), textAlign: TextAlign.right),
          ),
        ],
      ),
    );
  }

  Future<void> _mostrarDialogoNuevaRuta() async {
    final nombreCtrl = TextEditingController();
    final zonaCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool guardando = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.add_road, color: Colors.blue),
              SizedBox(width: 10),
              Text('Nueva Ruta de Entrega', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nombreCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Nombre de la Ruta',
                      hintText: 'Ej: Puerto Escondido - Pochutla',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Ingresa el nombre' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: zonaCtrl,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(
                      labelText: 'Código de Zona (Prefijo)',
                      hintText: 'Ej: POC, HUA, OAX',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Ingresa el código';
                      if (v.trim().length < 2) return 'Mínimo 2 letras';
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: guardando ? null : () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
              onPressed: guardando
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setModalState(() => guardando = true);

                      try {
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
                            SnackBar(
                              content: Text('✅ Ruta "${nombreCtrl.text.trim()}" creada con éxito'),
                              backgroundColor: Colors.green,
                            ),
                          );
                          _cargarMetricas();
                        }
                      } catch (e) {
                        setModalState(() => guardando = false);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error al crear ruta: $e'), backgroundColor: Colors.red),
                          );
                        }
                      }
                    },
              icon: guardando
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.check),
              label: const Text('Guardar Ruta'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        titleSpacing: 4,
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.analytics_outlined, color: Colors.blue, size: 20),
            SizedBox(width: 6),
            Text(
              'Dashboard', 
              style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
        actions: [
          // Botón de refrescar siempre accesible
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black87, size: 22),
            onPressed: _cargarMetricas,
            tooltip: 'Refrescar',
          ),
          // 🛠️ Menú desplegable autoajustable para evitar cualquier desbordamiento en pantallas pequeñas
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.black87),
            onSelected: (value) {
              if (value == 'ruta') {
                _mostrarDialogoNuevaRuta();
              } else if (value == 'recepcion') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const RecepcionPaqueteScreen()),
                ).then((_) => _cargarMetricas());
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem<String>(
                value: 'ruta',
                child: Row(
                  children: [
                    Icon(Icons.add_road, color: Colors.indigo, size: 20),
                    SizedBox(width: 10),
                    Text('Nueva Ruta'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'recepcion',
                child: Row(
                  children: [
                    Icon(Icons.add_box, color: Colors.blue, size: 20),
                    SizedBox(width: 10),
                    Text('Nueva Recepción'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _cargarMetricas,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildKPIHeader(),
                    const SizedBox(height: 24),
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 12,
                      runSpacing: 4,
                      children: [
                        const Text(
                          'Envíos Recientes',
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.black87),
                        ),
                        Text(
                          'Total registrados: ${_paquetesRecientes.length}',
                          style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w600, fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildMonitoringTable(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildKPIHeader() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 760;
        final double cardWidth = isWide ? (constraints.maxWidth - 32) / 3 : constraints.maxWidth;

        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _buildKPICard('En Tránsito', _conteoEnTransito.toString(), Icons.local_shipping, Colors.orange, cardWidth),
            _buildKPICard('Entregados', _conteoEntregadosHoy.toString(), Icons.check_circle_outline, Colors.green, cardWidth),
            _buildKPICard('En Bodega / Recepción', _conteoRecibidos.toString(), Icons.inventory_2_outlined, Colors.blue, cardWidth),
          ],
        );
      },
    );
  }

  Widget _buildKPICard(String title, String value, IconData icon, MaterialColor color, double width) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: color.withOpacity(0.12),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(value, style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: color[800] ?? color)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildMonitoringTable() {
    if (_paquetesRecientes.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: const Center(
          child: Column(
            children: [
              Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey),
              SizedBox(height: 10),
              Text('No hay envíos registrados en el sistema', style: TextStyle(color: Colors.grey, fontSize: 15)),
            ],
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: MaterialStateProperty.all(Colors.grey[100]),
            columns: const [
              DataColumn(label: Text('Guía / Folio', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Destinatario', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Ruta / Zona', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Monto', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Estado', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Fecha / Hora', style: TextStyle(fontWeight: FontWeight.bold))),
            ],
            rows: _paquetesRecientes.map((p) {
              final ruta = p['ruta_info'];
              final String tracking = p['tracking_number'] ?? p['id'] ?? 'S/N';
              final String dest = p['destinatario_nombre'] ?? 'N/A';
              final double monto = (p['monto_envio'] as num?)?.toDouble() ?? 0.0;
              final String estado = p['estado']?.toString() ?? 'RECIBIDO';
              
              final fecha = DateTime.tryParse(p['created_at'].toString())?.toLocal() ?? DateTime.now();
              final fechaStr = DateFormat('dd/MM HH:mm').format(fecha);

              return DataRow(cells: [
                DataCell(
                  InkWell(
                    onTap: () => _mostrarDetallePaquete(p),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Text(
                        tracking, 
                        style: const TextStyle(
                          fontWeight: FontWeight.bold, 
                          color: Colors.blue,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ),
                ),
                DataCell(Text(dest)),
                DataCell(Text(ruta != null ? '${ruta['nombre']} (${ruta['codigo_zona']})' : 'General')),
                DataCell(Text('\$${monto.toStringAsFixed(2)}')),
                DataCell(_buildStatusBadge(estado)),
                DataCell(Text(fechaStr, style: const TextStyle(color: Colors.grey, fontSize: 12))),
              ]);
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String estado) {
    MaterialColor color = Colors.blue;
    final norm = estado.toUpperCase();

    if (norm == 'ENTREGADO') {
      color = Colors.green;
    } else if (norm == 'A_BORDO' || norm == 'BODEGA_DESTINO' || norm == 'EN_REPARTO') {
      color = Colors.orange;
    } else if (norm == 'INCIDENCIA') {
      color = Colors.red;
    } else if (norm == 'CANCELADO') {
      color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        estado.replaceAll('_', ' '),
        style: TextStyle(color: color[800] ?? color, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }
}
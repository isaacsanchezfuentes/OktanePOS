import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../data/models/paquete_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../core/services/etiqueta_service.dart';

class DetallePaqueteScreen extends StatefulWidget {
  final PaqueteModel paquete;
  const DetallePaqueteScreen({super.key, required this.paquete});

  @override
  State<DetallePaqueteScreen> createState() => _DetallePaqueteScreenState();
}

class _DetallePaqueteScreenState extends State<DetallePaqueteScreen> {
  final TextEditingController _comentarioController = TextEditingController();
  bool _isAddingComment = false;
  bool _isPrinting = false;
  late Future<List<dynamic>> _comentariosFuture;

  @override
  void initState() {
    super.initState();
    _fetchComentarios();
  }

  void _fetchComentarios() {
    _comentariosFuture = Supabase.instance.client
        .from('paquetes_comentarios')
        .select()
        .eq('paquete_id', widget.paquete.id)
        .order('created_at', ascending: false);
  }

  Future<void> _reimprimirTicket() async {
    setState(() => _isPrinting = true);
    try {
      final p = widget.paquete;
      await EtiquetaService.imprimirEtiqueta(
        trackingNumber: p.trackingNumber,
        destinatario: p.destinatarioNombre,
        direccion: p.destinatarioDireccion,
        telefono: p.destinatarioTelefono,
        monto: p.montoEnvio,
        esSpei: false,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al imprimir: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isPrinting = false);
    }
  }

  Future<void> _agregarComentario() async {
    final text = _comentarioController.text.trim();
    if (text.isEmpty) return;

    setState(() => _isAddingComment = true);

    try {
      // 🛠️ Payload limpio y seguro: solo enviamos lo que la tabla tiene garantizado
      final Map<String, dynamic> payload = {
        'paquete_id': widget.paquete.id,
        'comentario': text,
      };

      await Supabase.instance.client.from('paquetes_comentarios').insert(payload);

      _comentarioController.clear();
      setState(() {
        _fetchComentarios();
      });
    } catch (e) {
      debugPrint('Error al agregar comentario: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al agregar nota: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isAddingComment = false);
    }
  }

  Future<void> _cancelarPaquete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Anular Paquete'),
        content: const Text('¿Está seguro de cancelar este paquete? Esta acción es irreversible.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('No')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sí, Cancelar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await Supabase.instance.client
            .from('paquetes')
            .update({'estado': 'CANCELADO'})
            .eq('id', widget.paquete.id);
        if (mounted) Navigator.pop(context);
      } catch (e) {
        debugPrint('Error al cancelar paquete: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.paquete;

    return Scaffold(
      appBar: AppBar(
        title: Text('Guía: ${p.trackingNumber}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.print),
            tooltip: 'Reimprimir Etiqueta',
            onPressed: _isPrinting ? null : _reimprimirTicket,
          ),
          if (p.estado != EstadoPaquete.entregado && p.estado != EstadoPaquete.incidencia)
            IconButton(
              icon: const Icon(Icons.cancel_outlined, color: Colors.red),
              onPressed: _cancelarPaquete,
              tooltip: 'Cancelar Paquete',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[300]!),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Column(
                  children: [
                    QrImageView(
                      data: p.trackingNumber,
                      version: QrVersions.auto,
                      size: 190.0,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      p.trackingNumber,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1.1),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _isPrinting ? null : _reimprimirTicket,
              icon: _isPrinting
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.print),
              label: const Text('REIMPRIMIR TICKET / GUÍA', style: TextStyle(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 12),

            _buildReadOnlyField('Tracking Number', p.trackingNumber),
            _buildReadOnlyField('Remitente', p.remitenteNombre),
            _buildReadOnlyField('Destinatario', p.destinatarioNombre),
            _buildReadOnlyField('Dirección', p.destinatarioDireccion),
            _buildReadOnlyField('Teléfono', p.destinatarioTelefono),
            _buildReadOnlyField('Monto Envio', '\$${p.montoEnvio.toStringAsFixed(2)}'),

            const Divider(height: 40),
            const Text('Bitácora de Comentarios', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            _buildComentariosList(),
            const SizedBox(height: 20),
            _buildAddCommentField(),
          ],
        ),
      ),
    );
  }

  Widget _buildReadOnlyField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildComentariosList() {
    return FutureBuilder<List<dynamic>>(
      future: _comentariosFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Text('Error al cargar comentarios');
        }
        final list = snapshot.data ?? [];
        if (list.isEmpty) {
          return const Text('No hay comentarios aún.', style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic));
        }
        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: list.length,
          separatorBuilder: (_, __) => const Divider(),
          itemBuilder: (context, index) {
            final comment = list[index];
            return ListTile(
              title: Text(comment['comentario']),
              subtitle: Text(comment['created_at'].toString().substring(0, 16)),
              dense: true,
            );
          },
        );
      },
    );
  }

  Widget _buildAddCommentField() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _comentarioController,
            decoration: const InputDecoration(
              hintText: 'Agregar una nota...',
              border: OutlineInputBorder(),
            ),
          ),
        ),
        const SizedBox(width: 10),
        ElevatedButton(
          onPressed: _isAddingComment ? null : _agregarComentario,
          child: _isAddingComment ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Agregar'),
        ),
      ],
    );
  }
}
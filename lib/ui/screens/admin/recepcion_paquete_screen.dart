import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../providers/paquetes_provider.dart';
import '../../../core/services/etiqueta_service.dart';

class RecepcionPaqueteScreen extends StatefulWidget {
  const RecepcionPaqueteScreen({super.key});

  @override
  State<RecepcionPaqueteScreen> createState() => _RecepcionPaqueteScreenState();
}

class _RecepcionPaqueteScreenState extends State<RecepcionPaqueteScreen> {
  final _formKey = GlobalKey<FormState>();
  final _remitenteController = TextEditingController();
  final _destinatarioController = TextEditingController();
  final _direccionController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _montoController = TextEditingController();

  File? _image;
  final _picker = ImagePicker();
  bool _isSaving = false;
  bool _isPickingImage = false;

  @override
  void initState() {
    super.initState();
    _retrieveLostData();
  }

  Future<void> _retrieveLostData() async {
    try {
      final LostDataResponse response = await _picker.retrieveLostData();
      if (response.isEmpty) return;
      if (response.file != null && mounted) {
        setState(() => _image = File(response.file!.path));
      }
    } catch (e) {
      debugPrint('Aviso recuperando imagen perdida: $e');
    }
  }

  String _limpiarNombreArchivo(String texto) {
    return texto
        .replaceAll(RegExp(r'[ÁÀÄÂ]'), 'A')
        .replaceAll(RegExp(r'[ÉÈËÊ]'), 'E')
        .replaceAll(RegExp(r'[ÍÌÏÎ]'), 'I')
        .replaceAll(RegExp(r'[ÓÒÖÔ]'), 'O')
        .replaceAll(RegExp(r'[ÚÙÜÛ]'), 'U')
        .replaceAll(RegExp(r'[áàäâ]'), 'a')
        .replaceAll(RegExp(r'[éèëê]'), 'e')
        .replaceAll(RegExp(r'[íìïî]'), 'i')
        .replaceAll(RegExp(r'[óòöô]'), 'o')
        .replaceAll(RegExp(r'[úùüû]'), 'u')
        .replaceAll(RegExp(r'[^a-zA-Z0-9_\-]'), '_');
  }

  Future<void> _mostrarSelectorOrigenFoto() async {
    if (_isPickingImage) return;

    // Se espera a que el modal termine de cerrarse antes de invocar la cámara nativa
    final ImageSource? selectedSource = await showModalBottomSheet<ImageSource>(
      context: context,
      useRootNavigator: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.blue),
              title: const Text('Tomar Foto con Cámara'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.green),
              title: const Text('Elegir de Galería (Bajo consumo de RAM)'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (selectedSource != null && mounted) {
      await _takePhoto(selectedSource);
    }
  }

  Future<void> _takePhoto(ImageSource source) async {
    if (_isPickingImage) return;
    setState(() => _isPickingImage = true);

    try {
      final XFile? photo = await _picker.pickImage(
        source: source,
        maxWidth: 600,
        maxHeight: 600,
        imageQuality: 40,
      );
      if (photo != null && mounted) {
        setState(() => _image = File(photo.path));
      }
    } catch (e) {
      debugPrint('Error Cámara: $e');
    } finally {
      if (mounted) {
        setState(() => _isPickingImage = false);
      }
    }
  }

  Future<void> _registrar() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSaving = true);

    try {
      final provider = context.read<PaquetesProvider>();

      final String tracking = await Supabase.instance.client.rpc(
        'generar_siguiente_tracking',
        params: {'zona': provider.codigoZonaActiva ?? 'GEN'},
      );

      String publicUrl = '';
      if (_image != null) {
        final String rawFileName = 'recibido_${tracking}_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final String fileName = _limpiarNombreArchivo(rawFileName);

        await Supabase.instance.client.storage
            .from('evidencias-entrega')
            .upload(fileName, _image!);

        publicUrl = Supabase.instance.client.storage
            .from('evidencias-entrega')
            .getPublicUrl(fileName);
      }

      final double monto = double.tryParse(_montoController.text.trim()) ?? 0.0;
      const double comisionFija = 4.00;
      const String tipoPago = "EFECTIVO";

      final String estadoInicial = provider.viajeIdActivo != null ? 'A_BORDO' : 'RECIBIDO';

      final id = DateTime.now().millisecondsSinceEpoch.toString();
      await Supabase.instance.client.from('paquetes').insert({
        'id': id,
        'tracking_number': tracking,
        'remitente_nombre': _remitenteController.text.trim(),
        'destinatario_nombre': _destinatarioController.text.trim(),
        'destinatario_direccion': _direccionController.text.trim(),
        'destinatario_telefono': _telefonoController.text.trim(),
        'monto_envio': monto,
        'metodo_pago': tipoPago,
        'comision_servicio': comisionFija,
        'estado': estadoInicial,
        'estado_pago': 'PAGADO',
        'ruta_id': provider.rutaIdActiva,
        'viaje_id': provider.viajeIdActivo,
        'foto_recepcion_url': publicUrl.isNotEmpty ? publicUrl : null,
      });

      if (mounted) {
        _mostrarVistaPrevia(tracking, monto);
      }
    } catch (e) {
      debugPrint('Error en recepción: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _mostrarVistaPrevia(String tracking, double monto) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Guía Generada'),
        content: SizedBox(
          width: 320,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                QrImageView(
                  data: tracking,
                  version: QrVersions.auto,
                  size: 200.0,
                ),
                const SizedBox(height: 10),
                Text(
                  tracking,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  'Monto: \$$monto',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                const Divider(),
                Text('Destinatario: ${_destinatarioController.text}', style: const TextStyle(fontSize: 12)),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text('Cerrar'),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.print),
            label: const Text('Imprimir'),
            onPressed: () async {
              await EtiquetaService.imprimirEtiqueta(
                trackingNumber: tracking,
                destinatario: _destinatarioController.text,
                direccion: _direccionController.text,
                telefono: _telefonoController.text,
                monto: monto,
                esSpei: false,
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _remitenteController.dispose();
    _destinatarioController.dispose();
    _direccionController.dispose();
    _telefonoController.dispose();
    _montoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recepción de Paquete')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              GestureDetector(
                onTap: _mostrarSelectorOrigenFoto,
                child: Container(
                  height: 170,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.blue),
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.blue.withOpacity(0.04),
                  ),
                  child: _image == null
                      ? const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.camera_alt, size: 44, color: Colors.blue),
                      SizedBox(height: 6),
                      Text('FOTO DEL PAQUETE', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                      Text('(Toca para cámara o galería)', style: TextStyle(fontSize: 11, color: Colors.grey)),
                    ],
                  )
                      : ClipRRect(
                    borderRadius: BorderRadius.circular(11),
                    child: Image.file(_image!, fit: BoxFit.cover),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _remitenteController,
                decoration: const InputDecoration(labelText: 'Remitente', border: OutlineInputBorder()),
                validator: (v) => (v == null || v.isEmpty) ? 'Requerido' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _destinatarioController,
                decoration: const InputDecoration(labelText: 'Destinatario', border: OutlineInputBorder()),
                validator: (v) => (v == null || v.isEmpty) ? 'Requerido' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _direccionController,
                decoration: const InputDecoration(labelText: 'Dirección Completa', border: OutlineInputBorder()),
                validator: (v) => (v == null || v.isEmpty) ? 'Requerido' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _telefonoController,
                decoration: const InputDecoration(labelText: 'Teléfono', border: OutlineInputBorder()),
                keyboardType: TextInputType.phone,
                validator: (v) => (v == null || v.isEmpty) ? 'Requerido' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _montoController,
                decoration: const InputDecoration(labelText: 'Monto de Envío \$', border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
                validator: (v) => (v == null || v.isEmpty) ? 'Requerido' : null,
              ),
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.confirmation_number_outlined, color: Colors.blue),
                    SizedBox(width: 10),
                    Text(
                      'Cuota por guía generada: \$4.00 MXN',
                      style: TextStyle(fontWeight: FontWeight.w600, color: Colors.blue),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _registrar,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                  child: _isSaving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('REGISTRAR E IMPRIMIR', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

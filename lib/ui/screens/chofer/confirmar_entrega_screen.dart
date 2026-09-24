import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../providers/paquetes_provider.dart';
import '../../../providers/auth_provider.dart';

class ConfirmarEntregaScreen extends StatefulWidget {
  final String trackingNumber;
  final String? paqueteId;

  const ConfirmarEntregaScreen({
    super.key,
    required this.trackingNumber,
    this.paqueteId,
  });

  @override
  State<ConfirmarEntregaScreen> createState() => _ConfirmarEntregaScreenState();
}

class _ConfirmarEntregaScreenState extends State<ConfirmarEntregaScreen> {
  File? _image;
  final _picker = ImagePicker();
  final _obsController = TextEditingController();
  bool _isSaving = false;

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
      debugPrint('Aviso recuperando imagen en segundo plano: $e');
    }
  }

  Future<void> _takePhoto() async {
    try {
      // 🛠️ Reducimos resolución y calidad para evitar que Android mate el proceso por falta de RAM
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera, 
        maxWidth: 600, 
        maxHeight: 600,
        imageQuality: 40,
      );
      if (photo != null && mounted) {
        setState(() => _image = File(photo.path));
      }
    } catch (e) {
      debugPrint('📷 Error Cámara: $e');
    }
  }

  Future<void> _confirmar() async {
    if (_isSaving || _image == null) return;
    setState(() => _isSaving = true);
    
    try {
      final provider = Provider.of<PaquetesProvider>(context, listen: false);
      final auth = Provider.of<AuthProvider>(context, listen: false);

      final String idPaquete = widget.paqueteId ?? widget.trackingNumber;
      final String idChofer = auth.userId ?? '00000000-0000-0000-0000-000000000000';

      await provider.confirmarEntregaLocal(
        trackingNumber: widget.trackingNumber,
        paqueteId: idPaquete,
        choferId: idChofer,
        fotoRuta: _image!.path,
        observaciones: _obsController.text,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Entrega registrada correctamente'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      debugPrint('❌ Error al confirmar: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Entrega: ${widget.trackingNumber}', style: const TextStyle(fontSize: 16))),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  return GestureDetector(
                    onTap: _takePhoto,
                    child: Container(
                      height: constraints.maxWidth > 500 ? 260 : 200, 
                      width: double.infinity,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.blueAccent, width: 2), 
                        borderRadius: BorderRadius.circular(14),
                        color: Colors.blue[50],
                      ),
                      child: _image == null 
                        ? const Column(
                            mainAxisAlignment: MainAxisAlignment.center, 
                            children: [
                              Icon(Icons.camera_alt, size: 48, color: Colors.blueAccent), 
                              SizedBox(height: 8),
                              Text('TOMAR FOTO DE EVIDENCIA', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            ],
                          ) 
                        : ClipRRect(
                            borderRadius: BorderRadius.circular(12), 
                            child: Image.file(_image!, fit: BoxFit.cover),
                          ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _obsController, 
                decoration: const InputDecoration(
                  labelText: 'Observaciones de la entrega', 
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity, 
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _confirmar,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green, 
                    foregroundColor: Colors.white,
                    elevation: 3,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isSaving 
                    ? const CircularProgressIndicator(color: Colors.white) 
                    : const Text('CONFIRMAR ENTREGA', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

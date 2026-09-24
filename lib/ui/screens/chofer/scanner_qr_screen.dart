import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class ScannerQrScreen extends StatefulWidget {
  final String? expectedTrackingNumber;
  final String? tituloAccion;

  const ScannerQrScreen({
    super.key,
    this.expectedTrackingNumber,
    this.tituloAccion,
  });

  @override
  State<ScannerQrScreen> createState() => _ScannerQrScreenState();
}

class _ScannerQrScreenState extends State<ScannerQrScreen> {
  MobileScannerController? _controller;
  bool _isProcessing = false;
  bool _isReloading = false;
  String? _lastErrorMsg;

  @override
  void initState() {
    super.initState();
    _iniciarNuevoControlador();
  }

  void _iniciarNuevoControlador() {
    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
      formats: const [BarcodeFormat.qrCode], // Parámetro explícito para evitar nulos en ML Kit
      returnImage: false,                    // Ahorro de memoria RAM en hardware de entrada
      torchEnabled: false,
    );
  }

  Future<void> _reiniciarSensorCompleto() async {
    if (_isReloading) return;
    setState(() {
      _isReloading = true;
      _lastErrorMsg = null;
    });

    try {
      await _controller?.dispose();
    } catch (_) {}

    await Future.delayed(const Duration(milliseconds: 250));

    if (mounted) {
      setState(() {
        _iniciarNuevoControlador();
        _isReloading = false;
      });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _mostrarDialogoManual() {
    final TextEditingController manualController =
    TextEditingController(text: widget.expectedTrackingNumber ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ingreso Manual de Guía'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Confirma o escribe el folio de la guía:'),
            const SizedBox(height: 12),
            TextField(
              controller: manualController,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Ej: PKG-2609-OAX-0007',
                labelText: 'Folio',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.characters,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCELAR')),
          ElevatedButton(
            onPressed: () {
              final String code = manualController.text.trim().toUpperCase();
              Navigator.pop(ctx);
              if (code.isNotEmpty) {
                _procesarCodigo(code);
              }
            },
            child: const Text('ACEPTAR'),
          ),
        ],
      ),
    );
  }

  Future<void> _procesarCodigo(String code) async {
    if (_isProcessing) return;
    if (code.isEmpty) return;

    _isProcessing = true;

    final String cleanedCode = code.trim().toUpperCase();

    if (!cleanedCode.startsWith('PKG-')) {
      await _mostrarErrorDialog(
        titulo: 'Código Inválido',
        mensaje: 'El folio "$cleanedCode" no tiene el formato institucional (PKG-...).',
      );
      _isProcessing = false;
      return;
    }

    if (widget.expectedTrackingNumber != null &&
        widget.expectedTrackingNumber!.isNotEmpty &&
        cleanedCode != widget.expectedTrackingNumber!.trim().toUpperCase()) {
      await _mostrarErrorDialog(
        titulo: 'Paquete Incorrecto',
        mensaje: 'Esperabas:\n${widget.expectedTrackingNumber}\n\nEscaneaste:\n$cleanedCode',
      );
      _isProcessing = false;
      return;
    }

    try {
      await _controller?.stop();
    } catch (_) {}

    if (mounted) {
      Navigator.pop(context, cleanedCode);
    }
  }

  Future<void> _mostrarErrorDialog({required String titulo, required String mensaje}) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.error_outline, color: Colors.red, size: 44),
        title: Text(titulo, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(mensaje, textAlign: TextAlign.center),
        actions: [
          Center(
            child: ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Reintentar'),
            ),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.sizeOf(context).width;
    final double focusBoxSize = screenWidth * 0.68;

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.black38,
        elevation: 0,
        title: Text(
          widget.tituloAccion ?? 'Escanear Guía',
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.keyboard, color: Colors.white, size: 26),
            tooltip: 'Ingresar Guía Manual',
            onPressed: _mostrarDialogoManual,
          ),
          if (_controller != null)
            IconButton(
              icon: ValueListenableBuilder(
                valueListenable: _controller!,
                builder: (context, state, child) {
                  return Icon(
                    state.torchState == TorchState.on ? Icons.flash_on : Icons.flash_off,
                    color: state.torchState == TorchState.on ? Colors.yellow : Colors.white,
                  );
                },
              ),
              onPressed: () => _controller?.toggleTorch(),
            ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (_isReloading || _controller == null)
            const Center(
              child: CircularProgressIndicator(color: Colors.white),
            )
          else
            MobileScanner(
              controller: _controller!,
              fit: BoxFit.cover,
              errorBuilder: (context, error, child) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.videocam_off_outlined, size: 56, color: Colors.orange),
                        const SizedBox(height: 12),
                        Text(
                          'Sensor no disponible (${error.errorCode.name})',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 18),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                          onPressed: _reiniciarSensorCompleto,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Reactivar Cámara'),
                        ),
                        const SizedBox(height: 12),
                        TextButton.icon(
                          onPressed: _mostrarDialogoManual,
                          icon: const Icon(Icons.keyboard, color: Colors.white70),
                          label: const Text('Ingresar guía con teclado', style: TextStyle(color: Colors.white70)),
                        ),
                      ],
                    ),
                  ),
                );
              },
              onDetect: (capture) {
                final barcodes = capture.barcodes;
                for (final barcode in barcodes) {
                  final valor = barcode.rawValue;
                  if (valor != null && valor.isNotEmpty) {
                    _procesarCodigo(valor);
                    break;
                  }
                }
              },
            ),

          // Cuadro visual de guía (IgnorePointer para no obstruir toques)
          IgnorePointer(
            child: Center(
              child: Container(
                width: focusBoxSize,
                height: focusBoxSize,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.blueAccent.withOpacity(0.85), width: 2.5),
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),

          if (widget.expectedTrackingNumber != null)
            Positioned(
              bottom: 30,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.85),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white24),
                ),
                child: Text(
                  'Buscando: ${widget.expectedTrackingNumber}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart';
import '../../charge/models/charge_model.dart';
import '../../cash_cut/models/cash_cut_model.dart';

class ThermalPrinterService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  static const String _keyMac = 'printer_mac';
  static const String _keyName = 'printer_name';

  Future<bool> requestBluetoothPermissions() async {
    try {
      Map<Permission, PermissionStatus> statuses = await [
        Permission.bluetoothConnect,
        Permission.bluetoothScan,
        Permission.location,
      ].request();
      return statuses[Permission.bluetoothConnect]?.isGranted ?? false;
    } catch (e) {
      debugPrint('⚠️ Error solicitando permisos Bluetooth: $e');
      return false;
    }
  }

  Future<List<BluetoothInfo>> getPairedDevices() async {
    try {
      await requestBluetoothPermissions();
      final List<BluetoothInfo> list = await PrintBluetoothThermal.pairedBluetooths;
      return list;
    } catch (e) {
      debugPrint('❌ Error obteniendo dispositivos Bluetooth: $e');
      return [];
    }
  }

  Future<bool> isConnected() async {
    try {
      return await PrintBluetoothThermal.connectionStatus;
    } catch (_) {
      return false;
    }
  }

  Future<bool> connect(String macAddress, {String? name}) async {
    try {
      await requestBluetoothPermissions();
      final bool connected = await PrintBluetoothThermal.connect(macPrinterAddress: macAddress);
      if (connected) {
        await _storage.write(key: _keyMac, value: macAddress);
        if (name != null) {
          await _storage.write(key: _keyName, value: name);
        }
      }
      return connected;
    } catch (e) {
      debugPrint('❌ Error conectando a impresora ($macAddress): $e');
      return false;
    }
  }

  Future<bool> disconnect() async {
    try {
      return await PrintBluetoothThermal.disconnect;
    } catch (_) {
      return false;
    }
  }

  Future<String?> getSavedPrinterMac() async {
    return await _storage.read(key: _keyMac);
  }

  Future<String?> getSavedPrinterName() async {
    return await _storage.read(key: _keyName);
  }

  Future<bool> ensureConnected() async {
    if (await isConnected()) return true;
    final mac = await getSavedPrinterMac();
    if (mac != null && mac.isNotEmpty) {
      return await connect(mac);
    }
    return false;
  }

  /// Sends a mini connection test ticket.
  Future<bool> printTestTicket() async {
    final bool ready = await ensureConnected();
    if (!ready) {
      debugPrint('❌ Impresora no conectada para ticket de prueba');
      return false;
    }

    try {
      final profile = await CapabilityProfile.load();
      final generator = Generator(PaperSize.mm58, profile);
      List<int> bytes = [];

      bytes += generator.setGlobalCodeTable('CP1252');
      bytes += generator.text(
        'OKTANE POS',
        styles: const PosStyles(
          align: PosAlign.center,
          bold: true,
          height: PosTextSize.size2,
          width: PosTextSize.size2,
        ),
      );
      bytes += generator.text(
        '--- CONEXION DE PRUEBA ---',
        styles: const PosStyles(align: PosAlign.center, bold: true),
      );
      bytes += generator.emptyLines(1);
      bytes += generator.text(
        'Impresora termica configurada con exito.',
        styles: const PosStyles(align: PosAlign.center),
      );
      bytes += generator.text(
        DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now()),
        styles: const PosStyles(align: PosAlign.center),
      );
      bytes += generator.emptyLines(2);
      bytes += generator.cut();

      return await PrintBluetoothThermal.writeBytes(bytes);
    } catch (e) {
      debugPrint('❌ Error imprimiendo ticket de prueba: $e');
      return false;
    }
  }

  /// Generates and sends a ESC/POS receipt for a ChargeModel with QR code.
  Future<bool> printChargeTicket(ChargeModel charge) async {
    final bool ready = await ensureConnected();
    if (!ready) {
      debugPrint('❌ Impresora no disponible para imprimir ticket de cobro');
      return false;
    }

    try {
      final profile = await CapabilityProfile.load();
      final generator = Generator(PaperSize.mm58, profile);
      List<int> bytes = [];

      final folioStr = charge.id != null && charge.id!.length >= 4 
          ? '#${charge.id!.substring(0, 4).toUpperCase()}'
          : '#${DateTime.now().millisecondsSinceEpoch % 10000}';
      final cleanFolio = charge.id != null && charge.id!.length >= 4 
          ? charge.id!.substring(0, 4).toUpperCase() 
          : '0001';

      final amountStr = '\$${charge.amount.toStringAsFixed(2)} MXN';
      final conceptStr = charge.concept.trim().isEmpty ? 'Consumo mostrador' : charge.concept.trim();
      final dateStr = DateFormat('dd/MM/yyyy HH:mm').format(charge.createdAt ?? DateTime.now());
      final qrData = 'https://oktane-pos.web.app/pay?id=${charge.id ?? ''}&folio=$cleanFolio&amount=${charge.amount}';

      bytes += generator.setGlobalCodeTable('CP1252');

      // Header
      bytes += generator.text(
        'OKTANE POS',
        styles: const PosStyles(
          align: PosAlign.center,
          bold: true,
          height: PosTextSize.size2,
          width: PosTextSize.size2,
        ),
      );
      bytes += generator.text(
        'TICKET DE COBRO',
        styles: const PosStyles(align: PosAlign.center, bold: true),
      );
      bytes += generator.text(
        '--------------------------------',
        styles: const PosStyles(align: PosAlign.center),
      );

      // Folio
      bytes += generator.text(
        'FOLIO: $folioStr',
        styles: const PosStyles(
          align: PosAlign.center,
          bold: true,
          height: PosTextSize.size2,
          width: PosTextSize.size1,
        ),
      );
      bytes += generator.text(
        'Fecha: $dateStr',
        styles: const PosStyles(align: PosAlign.center),
      );
      bytes += generator.text(
        '--------------------------------',
        styles: const PosStyles(align: PosAlign.center),
      );

      // Concept & Amount
      bytes += generator.text(
        'Concepto: $conceptStr',
        styles: const PosStyles(align: PosAlign.left, bold: true),
      );
      bytes += generator.text(
        'Metodo: ${charge.paymentMethod.toUpperCase()}',
        styles: const PosStyles(align: PosAlign.left),
      );
      bytes += generator.emptyLines(1);

      bytes += generator.text(
        'TOTAL: $amountStr',
        styles: const PosStyles(
          align: PosAlign.center,
          bold: true,
          height: PosTextSize.size2,
          width: PosTextSize.size2,
        ),
      );
      bytes += generator.emptyLines(1);

      // QR Code
      bytes += generator.qrcode(qrData, size: QRSize.size4);
      bytes += generator.emptyLines(1);

      // Footer
      bytes += generator.text(
        'Escanea y paga desde tu mesa',
        styles: const PosStyles(align: PosAlign.center, bold: true),
      );
      bytes += generator.text(
        '¡Gracias por su preferencia!',
        styles: const PosStyles(align: PosAlign.center),
      );

      bytes += generator.emptyLines(3);
      bytes += generator.cut();

      return await PrintBluetoothThermal.writeBytes(bytes);
    } catch (e) {
      debugPrint('❌ Error imprimiendo ticket de cobro: $e');
      return false;
    }
  }

  /// Generates and prints an ESC/POS Cash Cut (Corte Z) summary ticket.
  Future<bool> printCashCutTicket({
    required CashCutSummaryModel summary,
    required double initialFloat,
    required double countedCash,
    required double difference,
    String? cashierName,
  }) async {
    final bool ready = await ensureConnected();
    if (!ready) {
      debugPrint('❌ Impresora no disponible para imprimir corte de caja');
      return false;
    }

    try {
      final profile = await CapabilityProfile.load();
      final generator = Generator(PaperSize.mm58, profile);
      List<int> bytes = [];

      final now = DateTime.now();
      final dateStr = DateFormat('dd/MM/yyyy HH:mm').format(now);
      final cashier = cashierName ?? 'Cajero Default';

      bytes += generator.setGlobalCodeTable('CP1252');

      // Header
      bytes += generator.text(
        'OKTANE POS',
        styles: const PosStyles(
          align: PosAlign.center,
          bold: true,
          height: PosTextSize.size2,
          width: PosTextSize.size2,
        ),
      );
      bytes += generator.text(
        'CORTE DE CAJA (CORTE Z)',
        styles: const PosStyles(align: PosAlign.center, bold: true),
      );
      bytes += generator.text(
        '--------------------------------',
        styles: const PosStyles(align: PosAlign.center),
      );

      // Metadata
      bytes += generator.text('Fecha: $dateStr');
      bytes += generator.text('Cajero: $cashier');
      bytes += generator.text(
        '--------------------------------',
        styles: const PosStyles(align: PosAlign.center),
      );

      // Summary Metrics
      bytes += generator.text(
        'VENTAS TOTALES: \$${summary.totalCollected.toStringAsFixed(2)}',
        styles: const PosStyles(bold: true),
      );
      bytes += generator.text('Transacciones: ${summary.totalTransactions}');
      bytes += generator.text('Pendientes: ${summary.pendingTransactions}');
      bytes += generator.text('Ticket Promedio: \$${summary.averageTicket.toStringAsFixed(2)}');
      bytes += generator.text(
        '--------------------------------',
        styles: const PosStyles(align: PosAlign.center),
      );

      // Breakdown by Method
      bytes += generator.text('DESGLOSE DE METODOS', styles: const PosStyles(bold: true));
      bytes += generator.text('Efectivo:   \$${summary.totalCash.toStringAsFixed(2)}');
      bytes += generator.text('Tarjeta:    \$${summary.totalCard.toStringAsFixed(2)}');
      bytes += generator.text('QR Dinamico:\$${summary.totalQr.toStringAsFixed(2)}');
      bytes += generator.text(
        '--------------------------------',
        styles: const PosStyles(align: PosAlign.center),
      );

      // Drawer Balancing
      final expectedCash = initialFloat + summary.totalCash;
      bytes += generator.text('ARQUEO DE CAJON', styles: const PosStyles(bold: true));
      bytes += generator.text('Fondo Inicial:   \$${initialFloat.toStringAsFixed(2)}');
      bytes += generator.text('Ventas Efectivo: \$${summary.totalCash.toStringAsFixed(2)}');
      bytes += generator.text('Esperado Cajon:  \$${expectedCash.toStringAsFixed(2)}');
      bytes += generator.text('Contado Cajon:   \$${countedCash.toStringAsFixed(2)}');

      final diffLabel = difference == 0 
          ? 'CUADRE EXACTO' 
          : difference > 0 
              ? 'SOBRANTE: +\$${difference.toStringAsFixed(2)}' 
              : 'FALTANTE: -\$${difference.abs().toStringAsFixed(2)}';

      bytes += generator.text(
        diffLabel,
        styles: const PosStyles(bold: true, align: PosAlign.center),
      );

      bytes += generator.text(
        '--------------------------------',
        styles: const PosStyles(align: PosAlign.center),
      );
      bytes += generator.emptyLines(2);

      // Signatures
      bytes += generator.text('____________________', styles: const PosStyles(align: PosAlign.center));
      bytes += generator.text('Entrego (Cajero)', styles: const PosStyles(align: PosAlign.center));
      bytes += generator.emptyLines(2);

      bytes += generator.text('____________________', styles: const PosStyles(align: PosAlign.center));
      bytes += generator.text('Recibio (Supervisor)', styles: const PosStyles(align: PosAlign.center));

      bytes += generator.emptyLines(3);
      bytes += generator.cut();

      return await PrintBluetoothThermal.writeBytes(bytes);
    } catch (e) {
      debugPrint('❌ Error imprimiendo ticket de corte de caja: $e');
      return false;
    }
  }

  Future<String> getPaymentBaseUrl() async {
    final url = await _storage.read(key: 'payment_base_url');
    if (url != null && url.isNotEmpty) return url;
    return 'https://pay.oktane.io/o/';
  }

  /// Generates and prints an ESC/POS Pre-Check ticket with centered QR Code & SKU.
  Future<bool> printTablePreCheckTicket({
    required String tableName,
    required String zoneName,
    required String waiterName,
    required List<Map<String, dynamic>> items,
    required double totalAmount,
    String? customPaymentBaseUrl,
  }) async {
    final bool ready = await ensureConnected();
    if (!ready) {
      debugPrint('❌ Impresora no disponible para imprimir pre-cuenta');
      return false;
    }

    try {
      final profile = await CapabilityProfile.load();
      final generator = Generator(PaperSize.mm58, profile);
      List<int> bytes = [];

      final now = DateTime.now();
      final dateStr = DateFormat('dd/MM/yyyy HH:mm').format(now);
      final cleanTableName = tableName.replaceAll(' ', '').toUpperCase();
      final sku = 'ORD-$cleanTableName-${now.millisecondsSinceEpoch}';

      final baseUrl = customPaymentBaseUrl ?? await getPaymentBaseUrl();
      final paymentUrl = '$baseUrl$sku';

      final tip10 = totalAmount * 0.10;
      final tip15 = totalAmount * 0.15;

      bytes += generator.setGlobalCodeTable('CP1252');

      // Header Centered
      bytes += generator.text(
        'OKTANE POS',
        styles: const PosStyles(
          align: PosAlign.center,
          bold: true,
          height: PosTextSize.size2,
          width: PosTextSize.size2,
        ),
      );
      bytes += generator.text(
        'PRE-CUENTA DE MESA',
        styles: const PosStyles(align: PosAlign.center, bold: true),
      );
      bytes += generator.text(
        '--------------------------------',
        styles: const PosStyles(align: PosAlign.center),
      );

      // Metadata
      bytes += generator.text('Mesa: $tableName ($zoneName)');
      bytes += generator.text('Atendio: $waiterName');
      bytes += generator.text('Fecha: $dateStr');
      bytes += generator.text(
        '--------------------------------',
        styles: const PosStyles(align: PosAlign.center),
      );

      // Body Items
      if (items.isEmpty) {
        bytes += generator.text('Consumo de Mesa', styles: const PosStyles(bold: true));
      } else {
        for (final item in items) {
          final name = item['name']?.toString() ?? item['concept']?.toString() ?? 'Consumo';
          final qty = (item['quantity'] as num?)?.toInt() ?? 1;
          final price = (item['price'] as num?)?.toDouble() ?? (item['amount'] as num?)?.toDouble() ?? 0.0;
          final subtotal = (item['subtotal'] as num?)?.toDouble() ?? price;
          final isTakeaway = item['is_takeaway'] == true;
          final notes = item['notes']?.toString() ?? '';

          final takeawayTag = isTakeaway ? ' [LLEVAR]' : '';
          final lineDesc = '${qty}x $name$takeawayTag';

          bytes += generator.text(lineDesc, styles: const PosStyles(bold: true));
          if (notes.isNotEmpty) {
            bytes += generator.text('  Notas: $notes');
          }
          bytes += generator.text('  Subtotal: \$${subtotal.toStringAsFixed(2)} MXN');
        }
      }

      bytes += generator.text(
        '--------------------------------',
        styles: const PosStyles(align: PosAlign.center),
      );

      // Totals & Tip Suggestions
      bytes += generator.text(
        'SUBTOTAL: \$${totalAmount.toStringAsFixed(2)} MXN',
        styles: const PosStyles(
          align: PosAlign.right,
          bold: true,
        ),
      );
      bytes += generator.text('Propina sug 10%: \$${tip10.toStringAsFixed(2)} MXN', styles: const PosStyles(align: PosAlign.right));
      bytes += generator.text('Propina sug 15%: \$${tip15.toStringAsFixed(2)} MXN', styles: const PosStyles(align: PosAlign.right));

      bytes += generator.text(
        'TOTAL: \$${totalAmount.toStringAsFixed(2)} MXN',
        styles: const PosStyles(
          align: PosAlign.center,
          bold: true,
          height: PosTextSize.size2,
          width: PosTextSize.size1,
        ),
      );

      bytes += generator.text(
        '--------------------------------',
        styles: const PosStyles(align: PosAlign.center),
      );
      bytes += generator.emptyLines(1);

      // Centered QR Code
      bytes += generator.qrcode(paymentUrl, size: QRSize.size4);
      bytes += generator.emptyLines(1);

      // Footer
      bytes += generator.text('SKU: $sku', styles: const PosStyles(align: PosAlign.center, bold: true));
      bytes += generator.text('Escanea para pagar con tarjeta / digital', styles: const PosStyles(align: PosAlign.center));
      bytes += generator.text('o presenta este ticket en caja.', styles: const PosStyles(align: PosAlign.center));

      bytes += generator.emptyLines(3);
      bytes += generator.cut();

      return await PrintBluetoothThermal.writeBytes(bytes);
    } catch (e) {
      debugPrint('❌ Error imprimiendo ticket de pre-cuenta: $e');
      return false;
    }
  }
}

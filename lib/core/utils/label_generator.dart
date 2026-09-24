import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../data/models/paquete_model.dart';

class LabelGenerator {
  /// Genera una etiqueta térmica desde un PaqueteModel (Web/Admin) o Paquete (Drift)
  /// Usamos dynamic para aceptar ambos tipos de datos que tienen los mismos campos
  static Future<void> printThermalLabel(dynamic paquete) async {
    final doc = pw.Document();

    // Formato 4x6 pulgadas (101.6mm x 152.4mm)
    const PdfPageFormat format = PdfPageFormat(
      101.6 * PdfPageFormat.mm,
      152.4 * PdfPageFormat.mm,
      marginAll: 5 * PdfPageFormat.mm,
    );

    doc.addPage(
      pw.Page(
        pageFormat: format,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Encabezado
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('PAQUETERIA EXPRESS', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                  pw.Text('Oficina', style: const pw.TextStyle(fontSize: 8)),
                ],
              ),
              pw.Divider(thickness: 2),
              pw.SizedBox(height: 10),

              // Tracking y QR Central
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.BarcodeWidget(
                      barcode: pw.Barcode.qrCode(),
                      data: paquete.trackingNumber,
                      width: 60 * PdfPageFormat.mm,
                      height: 60 * PdfPageFormat.mm,
                    ),
                    pw.SizedBox(height: 5),
                    pw.Text(
                      paquete.trackingNumber,
                      style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 15),
              pw.Divider(),

              // Datos Remitente
              pw.Text('REMITENTE:', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
              pw.Text(paquete.remitenteNombre, style: const pw.TextStyle(fontSize: 12)),
              
              pw.SizedBox(height: 15),

              // Datos Destinatario
              pw.Text('DESTINATARIO:', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
              pw.Text(paquete.destinatarioNombre, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
              pw.Text(paquete.destinatarioDireccion, style: const pw.TextStyle(fontSize: 12)),
              pw.Text('Tel: ${paquete.destinatarioTelefono}', style: const pw.TextStyle(fontSize: 12)),

              pw.Spacer(),
              pw.Divider(thickness: 1),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('PESO: ${paquete.pesoKg} KG', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.Text('FECHA: ${DateTime.now().toString().substring(0, 10)}'),
                ],
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => doc.save(),
      name: 'Etiqueta_${paquete.trackingNumber}',
    );
  }
}

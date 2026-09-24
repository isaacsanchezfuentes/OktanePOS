import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

class EtiquetaService {
  static Future<void> imprimirEtiqueta({
    required String trackingNumber,
    required String destinatario,
    required String direccion,
    required String telefono,
    required double monto,
    required bool esSpei,
  }) async {
    final doc = pw.Document();
    final now = DateTime.now();
    final String dateStr = DateFormat('dd/MM/yyyy HH:mm').format(now);
    final String tipoPago = esSpei ? "PAGADO SPEI" : "EFECTIVO";

    // Formato ticket térmico 80mm (aprox 226 puntos de ancho)
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Text(
                "PAQUETERÍA",
                style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
              ),
              pw.Text(dateStr, style: const pw.TextStyle(fontSize: 10)),
              pw.SizedBox(height: 10),
              pw.Divider(),
              pw.SizedBox(height: 10),
              
              // Código QR Central
              pw.BarcodeWidget(
                barcode: pw.Barcode.qrCode(),
                data: trackingNumber,
                width: 120,
                height: 120,
              ),
              pw.SizedBox(height: 5),
              pw.Text(
                trackingNumber,
                style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 10),
              pw.Divider(),
              pw.SizedBox(height: 10),

              // Datos de entrega
              pw.Align(
                alignment: pw.Alignment.centerLeft,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text("DESTINATARIO:", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                    pw.Text(destinatario, style: const pw.TextStyle(fontSize: 12)),
                    pw.SizedBox(height: 5),
                    pw.Text("DIRECCIÓN:", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                    pw.Text(direccion, style: const pw.TextStyle(fontSize: 11)),
                    pw.SizedBox(height: 5),
                    pw.Text("TELÉFONO:", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                    pw.Text(telefono, style: const pw.TextStyle(fontSize: 12)),
                  ],
                ),
              ),
              pw.SizedBox(height: 15),
              pw.Divider(),
              pw.SizedBox(height: 5),
              
              // Indicador de cobro
              pw.Text(
                "\$${monto.toStringAsFixed(2)} - $tipoPago",
                style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 10),
              pw.Text("¡Gracias por su confianza!", style: const pw.TextStyle(fontSize: 8, fontStyle: pw.FontStyle.italic)),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => doc.save(),
      name: 'Etiqueta_$trackingNumber',
    );
  }
}

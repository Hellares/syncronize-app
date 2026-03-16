import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../domain/entities/venta.dart';

class PdfVentaGenerator {
  static Future<Uint8List> generarTicket({
    required Venta venta,
    required String empresaNombre,
    String? empresaRuc,
    Uint8List? logoEmpresa,
    String nombreImpuesto = 'IGV',
    double porcentajeImpuesto = 18.0,
  }) async {
    final pdf = pw.Document();

    final detalles = venta.detalles ?? [];

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat(80 * PdfPageFormat.mm, double.infinity,
            marginAll: 4 * PdfPageFormat.mm),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              // Logo
              if (logoEmpresa != null)
                pw.Center(
                  child: pw.Image(
                    pw.MemoryImage(logoEmpresa),
                    width: 120,
                  ),
                ),
              pw.SizedBox(height: 4),

              // Empresa
              pw.Text(empresaNombre,
                  style: pw.TextStyle(
                      fontSize: 12, fontWeight: pw.FontWeight.bold),
                  textAlign: pw.TextAlign.center),
              if (empresaRuc != null)
                pw.Text('RUC: $empresaRuc',
                    style: const pw.TextStyle(fontSize: 8),
                    textAlign: pw.TextAlign.center),

              pw.Divider(thickness: 1.5),

              // Titulo
              pw.Text('TICKET DE VENTA',
                  style: pw.TextStyle(
                      fontSize: 11, fontWeight: pw.FontWeight.bold),
                  textAlign: pw.TextAlign.center),
              pw.Text(venta.codigo,
                  style: pw.TextStyle(
                      fontSize: 10, fontWeight: pw.FontWeight.bold),
                  textAlign: pw.TextAlign.center),
              pw.Text(
                  'Fecha: ${venta.fechaVenta.day.toString().padLeft(2, '0')}/${venta.fechaVenta.month.toString().padLeft(2, '0')}/${venta.fechaVenta.year}',
                  style: const pw.TextStyle(fontSize: 8)),

              pw.Divider(),

              // Cliente
              pw.Align(
                alignment: pw.Alignment.centerLeft,
                child: pw.Text('CLIENTE',
                    style: pw.TextStyle(
                        fontSize: 9, fontWeight: pw.FontWeight.bold)),
              ),
              pw.Align(
                alignment: pw.Alignment.centerLeft,
                child: pw.Text('Nombre: ${venta.nombreCliente}',
                    style: const pw.TextStyle(fontSize: 8)),
              ),
              if (venta.documentoCliente != null)
                pw.Align(
                  alignment: pw.Alignment.centerLeft,
                  child: pw.Text('Doc: ${venta.documentoCliente}',
                      style: const pw.TextStyle(fontSize: 8)),
                ),

              pw.Divider(),

              // Detalle
              pw.Align(
                alignment: pw.Alignment.centerLeft,
                child: pw.Text('DETALLE',
                    style: pw.TextStyle(
                        fontSize: 9, fontWeight: pw.FontWeight.bold)),
              ),
              pw.SizedBox(height: 2),

              ...detalles.map((d) {
                final qty = d.cantidad % 1 == 0
                    ? d.cantidad.toInt().toString()
                    : d.cantidad.toStringAsFixed(2);
                return pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 2),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Expanded(
                        child: pw.Text('${qty}x ${d.descripcion}',
                            style: const pw.TextStyle(fontSize: 8)),
                      ),
                      pw.Text(
                          'S/${d.total.toStringAsFixed(2)}',
                          style: const pw.TextStyle(fontSize: 8)),
                    ],
                  ),
                );
              }),

              pw.Divider(),

              // Totales
              _buildTotalRow('Subtotal',
                  'S/${venta.subtotal.toStringAsFixed(2)}'),
              if (venta.descuento > 0)
                _buildTotalRow('Descuento',
                    '-S/${venta.descuento.toStringAsFixed(2)}'),
              _buildTotalRow(nombreImpuesto,
                  'S/${venta.impuestos.toStringAsFixed(2)}'),
              pw.Divider(thickness: 1.5),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('TOTAL',
                      style: pw.TextStyle(
                          fontSize: 11, fontWeight: pw.FontWeight.bold)),
                  pw.Text('S/${venta.total.toStringAsFixed(2)}',
                      style: pw.TextStyle(
                          fontSize: 11, fontWeight: pw.FontWeight.bold)),
                ],
              ),

              pw.Divider(),

              // Pago
              if (venta.metodoPago != null)
                _buildTotalRow('Metodo', venta.metodoPago!.label),
              if (venta.montoRecibido != null)
                _buildTotalRow('Recibido',
                    'S/${venta.montoRecibido!.toStringAsFixed(2)}'),
              if (venta.montoCambio != null && venta.montoCambio! > 0)
                _buildTotalRow('Cambio',
                    'S/${venta.montoCambio!.toStringAsFixed(2)}'),

              pw.SizedBox(height: 12),

              pw.Text('Gracias por su compra!',
                  style: pw.TextStyle(
                      fontSize: 9, fontWeight: pw.FontWeight.bold),
                  textAlign: pw.TextAlign.center),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildTotalRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 1),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 8)),
          pw.Text(value, style: const pw.TextStyle(fontSize: 8)),
        ],
      ),
    );
  }
}

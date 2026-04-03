import 'dart:typed_data';
import 'package:barcode/barcode.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../../configuracion_documentos/domain/entities/configuracion_documento_completa.dart';
import '../../domain/entities/venta.dart';

class PdfVentaGenerator {
  /// Convierte color hex (#RRGGBB) a PdfColor
  static PdfColor _hexToColor(String hex) {
    hex = hex.replaceFirst('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    final intVal = int.tryParse(hex, radix: 16) ?? 0xFF1565C0;
    return PdfColor.fromInt(intVal);
  }

  static Future<Uint8List> generarTicket({
    required Venta venta,
    required String empresaNombre,
    String? empresaRuc,
    Uint8List? logoEmpresa,
    String nombreImpuesto = 'IGV',
    double porcentajeImpuesto = 18.0,
    ConfiguracionDocumentoCompleta? documentConfig,
    Uint8List? firmaCliente,
  }) async {
    final pdf = pw.Document();
    final detalles = venta.detalles ?? [];

    // Colores desde configuración o defaults
    final colorPrimario = documentConfig != null
        ? _hexToColor(documentConfig.colorPrimarioEfectivo)
        : PdfColors.black;
    final colorCuerpo = documentConfig != null
        ? _hexToColor(documentConfig.colorCuerpoEfectivo)
        : PdfColors.black;

    // Plantilla
    final plantilla = documentConfig?.plantilla;
    final mostrarLogo = plantilla?.mostrarLogo ?? true;
    final mostrarDatosEmpresa = plantilla?.mostrarDatosEmpresa ?? true;
    final mostrarDatosCliente = plantilla?.mostrarDatosCliente ?? true;
    final mostrarDetalles = plantilla?.mostrarDetalles ?? true;
    final mostrarTotales = plantilla?.mostrarTotales ?? true;
    final mostrarObservaciones = plantilla?.mostrarObservaciones ?? true;
    final mostrarPiePagina = plantilla?.mostrarPiePagina ?? true;
    final textoPie = documentConfig?.configuracion.textoPiePagina ??
        'Gracias por su compra!';

    // Márgenes
    final margenH = (plantilla?.margenIzquierdo ?? 4) * PdfPageFormat.mm;
    final margenV = (plantilla?.margenSuperior ?? 4) * PdfPageFormat.mm;

    // Datos de empresa desde config o parámetros directos
    final nombreEmpresa =
        documentConfig?.configuracion.nombreComercial ?? empresaNombre;
    final ruc = documentConfig?.configuracion.ruc ?? empresaRuc;
    final direccion = documentConfig?.direccionEfectiva;
    final telefono = documentConfig?.telefonoEfectivo;

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat(
          80 * PdfPageFormat.mm,
          double.infinity,
          marginLeft: margenH,
          marginRight: margenH,
          marginTop: margenV,
          marginBottom: margenV,
        ),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              // Logo
              if (mostrarLogo && logoEmpresa != null)
                pw.Center(
                  child: pw.Image(
                    pw.MemoryImage(logoEmpresa),
                    width: 120,
                  ),
                ),
              if (mostrarLogo && logoEmpresa != null) pw.SizedBox(height: 4),

              // Empresa + Sede
              if (mostrarDatosEmpresa) ...[
                pw.Text(nombreEmpresa,
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                      color: colorPrimario,
                    ),
                    textAlign: pw.TextAlign.center),
                if (ruc != null)
                  pw.Text('RUC: $ruc',
                      style: pw.TextStyle(fontSize: 7, color: colorCuerpo),
                      textAlign: pw.TextAlign.center),
                if (venta.sedeNombre != null)
                  pw.Text('Sede: ${venta.sedeNombre}',
                      style: pw.TextStyle(fontSize: 7, color: colorCuerpo),
                      textAlign: pw.TextAlign.center),
                if (direccion != null && direccion.isNotEmpty)
                  pw.Text(direccion,
                      style: pw.TextStyle(fontSize: 7, color: colorCuerpo),
                      textAlign: pw.TextAlign.center),
                if (telefono != null && telefono.isNotEmpty)
                  pw.Text('Tel: $telefono',
                      style: pw.TextStyle(fontSize: 7, color: colorCuerpo),
                      textAlign: pw.TextAlign.center),
              ],

              _dottedLine(color: colorPrimario, thickness: 1.2),

              // Titulo: usar tipo de comprobante si tiene, sino TICKET DE VENTA
              pw.Text(
                  venta.tipoComprobante != null
                      ? '${venta.tipoComprobante} ELECTRONICA'
                      : 'TICKET DE VENTA',
                  style: pw.TextStyle(
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                    color: colorPrimario,
                  ),
                  textAlign: pw.TextAlign.center),
              pw.Text(venta.codigoComprobante ?? venta.codigo,
                  style: pw.TextStyle(
                    fontSize: 8,
                    fontWeight: pw.FontWeight.bold,
                    color: colorCuerpo,
                  ),
                  textAlign: pw.TextAlign.center),
              pw.Text(
                  'Fecha: ${venta.fechaVenta.day.toString().padLeft(2, '0')}/${venta.fechaVenta.month.toString().padLeft(2, '0')}/${venta.fechaVenta.year}',
                  style: pw.TextStyle(fontSize: 7, color: colorCuerpo)),
              if (venta.vendedorNombre != null)
                pw.Text('Vendedor: ${venta.vendedorNombre}',
                    style: pw.TextStyle(fontSize: 7, color: colorCuerpo)),
              if (venta.cajeroNombre != null)
                pw.Text('Cajero: ${venta.cajeroNombre}',
                    style: pw.TextStyle(fontSize: 7, color: colorCuerpo)),

              _dottedLine(color: colorPrimario),

              // Cliente
              if (mostrarDatosCliente) ...[
                pw.Align(
                  alignment: pw.Alignment.centerLeft,
                  child: pw.Text('CLIENTE',
                      style: pw.TextStyle(
                        fontSize: 8,
                        fontWeight: pw.FontWeight.bold,
                        color: colorPrimario,
                      )),
                ),
                pw.Align(
                  alignment: pw.Alignment.centerLeft,
                  child: pw.Text('Nombre: ${venta.nombreCliente}',
                      style: pw.TextStyle(fontSize: 7, color: colorCuerpo)),
                ),
                if (venta.documentoCliente != null)
                  pw.Align(
                    alignment: pw.Alignment.centerLeft,
                    child: pw.Text(
                        '${venta.tipoComprobante == 'FACTURA' ? 'RUC' : 'Doc'}: ${venta.documentoCliente}',
                        style: pw.TextStyle(fontSize: 7, color: colorCuerpo)),
                  ),
                if (venta.direccionCliente != null && venta.tipoComprobante != null)
                  pw.Align(
                    alignment: pw.Alignment.centerLeft,
                    child: pw.Text('Dir: ${venta.direccionCliente}',
                        style: pw.TextStyle(fontSize: 7, color: colorCuerpo)),
                  ),
                _dottedLine(color: colorPrimario),
              ],

              // Detalle
              if (mostrarDetalles) ...[
                pw.Align(
                  alignment: pw.Alignment.centerLeft,
                  child: pw.Text('DETALLE',
                      style: pw.TextStyle(
                        fontSize: 8,
                        fontWeight: pw.FontWeight.bold,
                        color: colorPrimario,
                      )),
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
                              style: pw.TextStyle(
                                  fontSize: 8, color: colorCuerpo)),
                        ),
                        pw.Text('S/${d.total.toStringAsFixed(2)}',
                            style:
                                pw.TextStyle(fontSize: 8, color: colorCuerpo)),
                      ],
                    ),
                  );
                }),
                _dottedLine(color: colorPrimario),
              ],

              // Totales
              if (mostrarTotales) ...[
                _buildTotalRow(
                    'Subtotal', 'S/${venta.subtotal.toStringAsFixed(2)}',
                    color: colorCuerpo),
                if (venta.descuento > 0)
                  _buildTotalRow(
                      'Descuento', '-S/${venta.descuento.toStringAsFixed(2)}',
                      color: colorCuerpo),
                _buildTotalRow(
                    nombreImpuesto, 'S/${venta.impuestos.toStringAsFixed(2)}',
                    color: colorCuerpo),
                _dottedLine(color: colorPrimario, thickness: 1.2),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('TOTAL',
                        style: pw.TextStyle(
                          fontSize: 9,
                          fontWeight: pw.FontWeight.bold,
                          color: colorPrimario,
                        )),
                    pw.Text('S/${venta.total.toStringAsFixed(2)}',
                        style: pw.TextStyle(
                          fontSize: 11,
                          fontWeight: pw.FontWeight.bold,
                          color: colorPrimario,
                        )),
                  ],
                ),
                _dottedLine(color: colorPrimario),

                // Info tributaria SUNAT para boleta/factura
                if (venta.tipoComprobante != null) ...[
                  pw.SizedBox(height: 3),
                  pw.Align(
                    alignment: pw.Alignment.centerLeft,
                    child: pw.Text('INFORMACIÓN TRIBUTARIA',
                        style: pw.TextStyle(fontSize: 6, fontWeight: pw.FontWeight.bold, color: colorPrimario)),
                  ),
                  pw.SizedBox(height: 2),
                  if (venta.comprobanteGravada != null && venta.comprobanteGravada! > 0)
                    _buildTotalRow('Op. Gravada', 'S/ ${venta.comprobanteGravada!.toStringAsFixed(2)}', color: colorCuerpo, fontSize: 6.5),
                  if (venta.comprobanteExonerada != null && venta.comprobanteExonerada! > 0)
                    _buildTotalRow('Op. Exonerada', 'S/ ${venta.comprobanteExonerada!.toStringAsFixed(2)}', color: colorCuerpo, fontSize: 6.5),
                  if (venta.comprobanteInafecta != null && venta.comprobanteInafecta! > 0)
                    _buildTotalRow('Op. Inafecta', 'S/ ${venta.comprobanteInafecta!.toStringAsFixed(2)}', color: colorCuerpo, fontSize: 6.5),
                  if (venta.comprobanteIgv != null)
                    _buildTotalRow(nombreImpuesto, 'S/ ${venta.comprobanteIgv!.toStringAsFixed(2)}', color: colorCuerpo, fontSize: 6.5),
                  if (venta.comprobanteIcbper != null && venta.comprobanteIcbper! > 0)
                    _buildTotalRow('ICBPER', 'S/ ${venta.comprobanteIcbper!.toStringAsFixed(2)}', color: colorCuerpo, fontSize: 6.5),
                  _buildTotalRow('Importe Total', 'S/ ${venta.total.toStringAsFixed(2)}', color: colorPrimario, fontSize: 7),
                  if (venta.comprobanteSunatHash != null) ...[
                    pw.SizedBox(height: 3),
                    pw.Text('Hash: ${venta.comprobanteSunatHash}',
                        style: pw.TextStyle(fontSize: 5, color: colorCuerpo),
                        textAlign: pw.TextAlign.center),
                  ],
                  pw.SizedBox(height: 2),
                ],
              ],

              // Pagos
              if (venta.pagos != null && venta.pagos!.isNotEmpty) ...[
                pw.Align(
                  alignment: pw.Alignment.centerLeft,
                  child: pw.Text('PAGOS',
                      style: pw.TextStyle(
                        fontSize: 8,
                        fontWeight: pw.FontWeight.bold,
                        color: colorPrimario,
                      )),
                ),
                pw.SizedBox(height: 2),
                ...venta.pagos!.map((p) => pw.Padding(
                      padding: const pw.EdgeInsets.only(bottom: 2),
                      child: pw.Column(
                        children: [
                          pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Text(
                                p.referencia != null && p.referencia!.isNotEmpty
                                    ? '${p.metodoPago.label} (${p.referencia})'
                                    : p.metodoPago.label,
                                style: pw.TextStyle(fontSize: 7, color: colorCuerpo),
                              ),
                              pw.Text('S/${p.monto.toStringAsFixed(2)}',
                                  style: pw.TextStyle(fontSize: 7, color: colorCuerpo)),
                            ],
                          ),
                          if (p.esEnDolares && p.montoOriginal != null)
                            pw.Align(
                              alignment: pw.Alignment.centerRight,
                              child: pw.Text(
                                '\$${p.montoOriginal!.toStringAsFixed(2)} USD (TC ${p.tipoCambio?.toStringAsFixed(3) ?? '-'})',
                                style: pw.TextStyle(fontSize: 6, color: colorCuerpo,
                                    fontStyle: pw.FontStyle.italic),
                              ),
                            ),
                        ],
                      ),
                    )),
                if (venta.pagos!.length > 1)
                  _buildTotalRow(
                    'Total pagado',
                    'S/${venta.pagos!.fold(0.0, (sum, p) => sum + p.monto).toStringAsFixed(2)}',
                    color: colorCuerpo,
                  ),
              ] else if (venta.metodoPago != null) ...[
                _buildTotalRow('Metodo', venta.metodoPago!.label,
                    color: colorCuerpo),
                if (venta.montoRecibido != null)
                  _buildTotalRow(
                      'Recibido', 'S/${venta.montoRecibido!.toStringAsFixed(2)}',
                      color: colorCuerpo),
              ],
              if (venta.montoCambio != null && venta.montoCambio! > 0)
                _buildTotalRow(
                    'Cambio', 'S/${venta.montoCambio!.toStringAsFixed(2)}',
                    color: colorCuerpo),

              // Observaciones
              if (mostrarObservaciones &&
                  venta.observaciones != null &&
                  venta.observaciones!.isNotEmpty) ...[
                pw.SizedBox(height: 4),
                pw.Align(
                  alignment: pw.Alignment.centerLeft,
                  child: pw.Text('Obs: ${venta.observaciones}',
                      style: pw.TextStyle(
                          fontSize: 7,
                          fontStyle: pw.FontStyle.italic,
                          color: colorCuerpo)),
                ),
              ],

              // Firma del cliente
              if (firmaCliente != null) ...[
                pw.SizedBox(height: 8),
                _dottedLine(color: colorPrimario),
                pw.SizedBox(height: 6),
                pw.Center(
                  child: pw.Image(
                    pw.MemoryImage(firmaCliente),
                    height: 50,
                    width: 120,
                    fit: pw.BoxFit.contain,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Container(
                  width: 140,
                  decoration: pw.BoxDecoration(
                    border: pw.Border(top: pw.BorderSide(width: 0.5, color: colorCuerpo)),
                  ),
                  child: pw.Padding(
                    padding: const pw.EdgeInsets.only(top: 3),
                    child: pw.Center(
                      child: pw.Text('Firma del cliente',
                          style: pw.TextStyle(fontSize: 7, color: colorCuerpo)),
                    ),
                  ),
                ),
              ],

              // QR Code
              pw.SizedBox(height: 8),
              _dottedLine(color: colorPrimario),
              pw.SizedBox(height: 6),
              pw.Center(
                child: pw.BarcodeWidget(
                  barcode: Barcode.qrCode(),
                  data: '${venta.codigo}|${venta.fechaVenta.day.toString().padLeft(2, '0')}/${venta.fechaVenta.month.toString().padLeft(2, '0')}/${venta.fechaVenta.year}|S/${venta.total.toStringAsFixed(2)}',
                  width: 60,
                  height: 60,
                  color: colorPrimario,
                ),
              ),

              pw.SizedBox(height: 8),

              // Pie de pagina
              if (mostrarPiePagina)
                pw.Text(textoPie,
                    style: pw.TextStyle(
                      fontSize: 9,
                      fontWeight: pw.FontWeight.bold,
                      color: colorPrimario,
                    ),
                    textAlign: pw.TextAlign.center),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _dottedLine({
    PdfColor color = PdfColors.black,
    double thickness = 0.8,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.CustomPaint(
        size: const PdfPoint(double.infinity, 1),
        painter: (PdfGraphics canvas, PdfPoint size) {
          canvas
            ..setStrokeColor(color)
            ..setLineWidth(thickness)
            ..setLineDashPattern([2, 2]);
          canvas
            ..moveTo(0, size.y / 2)
            ..lineTo(size.x, size.y / 2)
            ..strokePath();
        },
      ),
    );
  }

  static pw.Widget _buildTotalRow(String label, String value,
      {PdfColor color = PdfColors.black, double fontSize = 8}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 1),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(fontSize: fontSize, color: color)),
          pw.Text(value, style: pw.TextStyle(fontSize: fontSize, color: color)),
        ],
      ),
    );
  }
}

import 'dart:typed_data';
import 'package:barcode/barcode.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../../../core/utils/number_to_words.dart';
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
    String? razonSocial,
    String? nombreComercial,
    String? direccionFiscal,
    Uint8List? logoEmpresa,
    String nombreImpuesto = 'IGV',
    double porcentajeImpuesto = 18.0,
    ConfiguracionDocumentoCompleta? documentConfig,
    Uint8List? firmaCliente,
    String? resolucionSunat,
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

    // Datos de empresa: nombre comercial (título) + razón social + RUC (del emisor)
    final nombreEmpresaFinal =
        nombreComercial ?? documentConfig?.configuracion.nombreComercial ?? empresaNombre;
    final razonSocialFinal = razonSocial;
    // RUC: prioridad del emisor efectivo (puede ser sede con RUC propio)
    final ruc = empresaRuc ?? documentConfig?.configuracion.ruc;
    // Dirección: prioridad emisor efectivo > config documentos
    final direccion = direccionFiscal ?? documentConfig?.direccionEfectiva;
    final telefono = documentConfig?.telefonoEfectivo;
    final simboloMoneda = venta.moneda == 'USD' ? '\$ ' : 'S/ ';
    final nombreMoneda = venta.moneda == 'USD' ? 'DOLARES AMERICANOS' : 'SOLES';
    final esComprobante = venta.tipoComprobante != null;
    final esCredito = venta.esCredito;

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

              // Empresa + Emisor
              if (mostrarDatosEmpresa) ...[
                pw.Text(nombreEmpresaFinal,
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                      color: colorPrimario,
                    ),
                    textAlign: pw.TextAlign.center),
                if (razonSocialFinal != null && razonSocialFinal != nombreEmpresaFinal)
                  pw.Text(razonSocialFinal,
                      style: pw.TextStyle(fontSize: 6, color: colorCuerpo),
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
                      style: pw.TextStyle(fontSize: 6, color: colorCuerpo),
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
              pw.Align(
                alignment: pw.Alignment.centerLeft,
                child: pw.Text(
                    'Fecha: ${venta.fechaVenta.day.toString().padLeft(2, '0')}/${venta.fechaVenta.month.toString().padLeft(2, '0')}/${venta.fechaVenta.year}',
                    style: pw.TextStyle(fontSize: 7, color: colorCuerpo)),
              ),
              if (venta.vendedorNombre != null)
                pw.Align(
                  alignment: pw.Alignment.centerLeft,
                  child: pw.Text('Vendedor: ${venta.vendedorNombre}',
                      style: pw.TextStyle(fontSize: 6, color: colorCuerpo)),
                ),
              if (venta.cajeroNombre != null)
                pw.Align(
                  alignment: pw.Alignment.centerLeft,
                  child: pw.Text('Cajero: ${venta.cajeroNombre}',
                      style: pw.TextStyle(fontSize: 6, color: colorCuerpo)),
                ),

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
                      style: pw.TextStyle(fontSize: 6, color: colorCuerpo)),
                ),
                if (venta.documentoCliente != null)
                  pw.Align(
                    alignment: pw.Alignment.centerLeft,
                    child: pw.Text(
                        '${venta.documentoCliente!.length == 11 ? 'RUC' : 'DNI'}: ${venta.documentoCliente}',
                        style: pw.TextStyle(fontSize: 7, color: colorCuerpo)),
                  ),
                if (venta.direccionCliente != null && venta.direccionCliente!.isNotEmpty)
                  pw.Align(
                    alignment: pw.Alignment.centerLeft,
                    child: pw.Text('Dir: ${venta.direccionCliente}',
                        style: pw.TextStyle(fontSize: 7, color: colorCuerpo)),
                  ),
                if (venta.emailCliente != null && venta.emailCliente!.isNotEmpty)
                  pw.Align(
                    alignment: pw.Alignment.centerLeft,
                    child: pw.Text('Email: ${venta.emailCliente}',
                        style: pw.TextStyle(fontSize: 7, color: colorCuerpo)),
                  ),
                _dottedLine(color: colorPrimario),
              ],

              // Detalle con encabezado de tabla
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
                pw.SizedBox(height: 3),
                // Header de tabla
                pw.Row(
                  children: [
                    pw.SizedBox(width: 22, child: pw.Text('CANT', style: pw.TextStyle(fontSize: 6, fontWeight: pw.FontWeight.bold, color: colorPrimario))),
                    pw.Expanded(child: pw.Text('DESCRIPCIÓN', style: pw.TextStyle(fontSize: 6, fontWeight: pw.FontWeight.bold, color: colorPrimario))),
                    pw.SizedBox(width: 42, child: pw.Text('P.U.', style: pw.TextStyle(fontSize: 6, fontWeight: pw.FontWeight.bold, color: colorPrimario), textAlign: pw.TextAlign.right)),
                    pw.SizedBox(width: 48, child: pw.Text('TOTAL', style: pw.TextStyle(fontSize: 6, fontWeight: pw.FontWeight.bold, color: colorPrimario), textAlign: pw.TextAlign.right)),
                  ],
                ),
                pw.SizedBox(height: 2),
                ...detalles.map((d) {
                  final qty = d.cantidad % 1 == 0
                      ? d.cantidad.toInt().toString()
                      : d.cantidad.toStringAsFixed(2);
                  return pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 2),
                    child: pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.SizedBox(width: 22, child: pw.Text(qty, style: pw.TextStyle(fontSize: 7, color: colorCuerpo))),
                        pw.Expanded(child: pw.Text(d.descripcion, style: pw.TextStyle(fontSize: 7, color: colorCuerpo))),
                        pw.SizedBox(width: 42, child: pw.Text('$simboloMoneda${d.precioUnitario.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 7, color: colorCuerpo), textAlign: pw.TextAlign.right)),
                        pw.SizedBox(width: 48, child: pw.Text('$simboloMoneda${d.total.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 7, color: colorCuerpo), textAlign: pw.TextAlign.right)),
                      ],
                    ),
                  );
                }),
                _dottedLine(color: colorPrimario),
              ],

              // Condición de pago
              pw.Align(
                alignment: pw.Alignment.centerLeft,
                child: pw.Text(
                  'Condición: ${esCredito ? 'CRÉDITO' : 'CONTADO'}',
                  style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold, color: colorCuerpo),
                ),
              ),
              pw.SizedBox(height: 2),

              // Totales
              if (mostrarTotales) ...[
                _buildTotalRow(
                    'Subtotal', '$simboloMoneda${venta.subtotal.toStringAsFixed(2)}',
                    color: colorCuerpo),
                if (venta.descuento > 0)
                  _buildTotalRow(
                      'Descuento', '-$simboloMoneda${venta.descuento.toStringAsFixed(2)}',
                      color: colorCuerpo),
                _buildTotalRow(
                    nombreImpuesto, '$simboloMoneda${venta.impuestos.toStringAsFixed(2)}',
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
                    pw.Text('$simboloMoneda${venta.total.toStringAsFixed(2)}',
                        style: pw.TextStyle(
                          fontSize: 11,
                          fontWeight: pw.FontWeight.bold,
                          color: colorPrimario,
                        )),
                  ],
                ),
                _dottedLine(color: colorPrimario),

                // Info tributaria SUNAT para boleta/factura
                // Info tributaria: solo si hay mezcla de afectaciones o ICBPER
                if (esComprobante) ...[
                  // Detectar si hay operaciones mixtas
                  ..._buildInfoTributaria(venta, simboloMoneda, nombreImpuesto, colorPrimario, colorCuerpo),
                  // Monto en letras
                  pw.SizedBox(height: 2),
                  pw.Text(
                    'SON: ${NumberToWords.convert(venta.total, moneda: nombreMoneda)}',
                    style: pw.TextStyle(fontSize: 5, color: colorCuerpo, fontStyle: pw.FontStyle.italic),
                    textAlign: pw.TextAlign.center,
                  ),
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
                              pw.Text('$simboloMoneda${p.monto.toStringAsFixed(2)}',
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
                    '$simboloMoneda${venta.pagos!.fold(0.0, (sum, p) => sum + p.monto).toStringAsFixed(2)}',
                    color: colorCuerpo,
                  ),
              ] else if (venta.metodoPago != null) ...[
                _buildTotalRow('Metodo', venta.metodoPago!.label,
                    color: colorCuerpo),
                if (venta.montoRecibido != null)
                  _buildTotalRow(
                      'Recibido', '$simboloMoneda${venta.montoRecibido!.toStringAsFixed(2)}',
                      color: colorCuerpo),
              ],
              if (venta.montoCambio != null && venta.montoCambio! > 0)
                _buildTotalRow(
                    'Cambio', '$simboloMoneda${venta.montoCambio!.toStringAsFixed(2)}',
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

              // QR Code: SUNAT si tiene, sino interno
              pw.SizedBox(height: 8),
              _dottedLine(color: colorPrimario),
              pw.SizedBox(height: 6),
              pw.Center(
                child: pw.BarcodeWidget(
                  barcode: Barcode.qrCode(),
                  data: venta.comprobanteCadenaQR ??
                      '${venta.codigo}|${venta.fechaVenta.day.toString().padLeft(2, '0')}/${venta.fechaVenta.month.toString().padLeft(2, '0')}/${venta.fechaVenta.year}|$simboloMoneda${venta.total.toStringAsFixed(2)}',
                  width: 65,
                  height: 65,
                  color: colorPrimario,
                ),
              ),

              // Leyenda legal SUNAT
              if (esComprobante) ...[
                pw.SizedBox(height: 4),
                pw.Text(
                  'Representación impresa de la ${venta.tipoComprobante} ELECTRÓNICA',
                  style: pw.TextStyle(fontSize: 6, color: colorCuerpo),
                  textAlign: pw.TextAlign.center,
                ),
                if (venta.comprobanteEnlaceNubefact != null) ...[
                  pw.SizedBox(height: 1),
                  pw.Text(
                    'Consulte en: ${venta.comprobanteEnlaceNubefact}',
                    style: pw.TextStyle(fontSize: 5.5, color: colorCuerpo),
                    textAlign: pw.TextAlign.center,
                  ),
                ],
                if (resolucionSunat != null && resolucionSunat.isNotEmpty) ...[
                  pw.SizedBox(height: 1),
                  pw.Text(
                    'Autorizado mediante Resolución de Intendencia $resolucionSunat',
                    style: pw.TextStyle(fontSize: 5.5, color: colorCuerpo),
                    textAlign: pw.TextAlign.center,
                  ),
                ],
              ],

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

  /// Info tributaria: solo muestra sección expandida si hay operaciones mixtas o ICBPER.
  /// Si todo es gravado puro, no repite lo que ya dicen los totales de arriba.
  static List<pw.Widget> _buildInfoTributaria(
    Venta venta, String simbolo, String nombreImpuesto, PdfColor colorPrimario, PdfColor colorCuerpo,
  ) {
    final gravada = venta.comprobanteGravada ?? 0;
    final exonerada = venta.comprobanteExonerada ?? 0;
    final inafecta = venta.comprobanteInafecta ?? 0;
    final icbper = venta.comprobanteIcbper ?? 0;

    // Si solo hay operaciones gravadas y sin ICBPER, no mostrar sección redundante
    final tieneMezcla = exonerada > 0 || inafecta > 0 || icbper > 0;
    if (!tieneMezcla) return [];

    return [
      pw.SizedBox(height: 3),
      pw.Align(
        alignment: pw.Alignment.centerLeft,
        child: pw.Text('INFORMACIÓN TRIBUTARIA',
            style: pw.TextStyle(fontSize: 6, fontWeight: pw.FontWeight.bold, color: colorPrimario)),
      ),
      pw.SizedBox(height: 2),
      if (gravada > 0)
        _buildTotalRow('Op. Gravada', '$simbolo${gravada.toStringAsFixed(2)}', color: colorCuerpo, fontSize: 6.5),
      if (exonerada > 0)
        _buildTotalRow('Op. Exonerada', '$simbolo${exonerada.toStringAsFixed(2)}', color: colorCuerpo, fontSize: 6.5),
      if (inafecta > 0)
        _buildTotalRow('Op. Inafecta', '$simbolo${inafecta.toStringAsFixed(2)}', color: colorCuerpo, fontSize: 6.5),
      if (venta.comprobanteIgv != null)
        _buildTotalRow(nombreImpuesto, '$simbolo${venta.comprobanteIgv!.toStringAsFixed(2)}', color: colorCuerpo, fontSize: 6.5),
      if (icbper > 0)
        _buildTotalRow('ICBPER', '$simbolo${icbper.toStringAsFixed(2)}', color: colorCuerpo, fontSize: 6.5),
      _buildTotalRow('Importe Total', '$simbolo${venta.total.toStringAsFixed(2)}', color: colorPrimario, fontSize: 7),
    ];
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

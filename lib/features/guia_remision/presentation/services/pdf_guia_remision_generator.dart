import 'dart:typed_data';
import 'package:barcode/barcode.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../domain/entities/guia_remision.dart';

class PdfGuiaRemisionGenerator {
  /// Resuelve ubigeo a "DEPARTAMENTO - PROVINCIA - DISTRITO"
  static String _resolverUbigeo(String? ubigeo, List<Map<String, dynamic>>? ubigeos) {
    if (ubigeo == null || ubigeo.isEmpty || ubigeos == null) return '';
    final match = ubigeos.where((u) => u['ubigeo'] == ubigeo).toList();
    if (match.isEmpty) return '';
    final u = match.first;
    return '${u['departamento']} - ${u['provincia']} - ${u['distrito']}';
  }

  static Future<Uint8List> generar({
    required GuiaRemision guia,
    required String empresaNombre,
    String? empresaRuc,
    String? razonSocial,
    String? nombreComercial,
    String? direccionFiscal,
    Uint8List? logoEmpresa,
    List<Map<String, dynamic>>? ubigeos,
  }) async {
    final pdf = pw.Document();
    final detalles = guia.detalles;

    final nombreEmpresaFinal = nombreComercial ?? empresaNombre;

    // Resolver ubigeos a texto
    final partidaUbigeoText = _resolverUbigeo(guia.puntoPartidaUbigeo, ubigeos);
    final llegadaUbigeoText = _resolverUbigeo(guia.puntoLlegadaUbigeo, ubigeos);
    final dirPartida = partidaUbigeoText.isNotEmpty
        ? '$partidaUbigeoText - ${guia.puntoPartidaDireccion}'
        : guia.puntoPartidaDireccion;
    final dirLlegada = llegadaUbigeoText.isNotEmpty
        ? '$llegadaUbigeoText - ${guia.puntoLlegadaDireccion}'
        : guia.puntoLlegadaDireccion;

    // Determine title based on tipo
    final titulo = guia.tipo == 'REMITENTE'
        ? 'GUIA DE REMISION REMITENTE'
        : guia.tipo == 'TRANSPORTISTA'
            ? 'GUIA DE REMISION TRANSPORTISTA'
            : 'GUIA DE REMISION ELECTRONICA';

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat(
          80 * PdfPageFormat.mm,
          double.infinity,
          marginLeft: 4 * PdfPageFormat.mm,
          marginRight: 4 * PdfPageFormat.mm,
          marginTop: 4 * PdfPageFormat.mm,
          marginBottom: 4 * PdfPageFormat.mm,
        ),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              // ── Header: Logo ──
              if (logoEmpresa != null) ...[
                pw.Center(
                  child: pw.Image(
                    pw.MemoryImage(logoEmpresa),
                    width: 120,
                  ),
                ),
                pw.SizedBox(height: 4),
              ],

              // ── Header: Empresa data ──
              pw.Text(
                nombreEmpresaFinal,
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                ),
                textAlign: pw.TextAlign.center,
              ),
              if (razonSocial != null && razonSocial != nombreEmpresaFinal)
                pw.Text(
                  razonSocial,
                  style: const pw.TextStyle(fontSize: 6),
                  textAlign: pw.TextAlign.center,
                ),
              if (empresaRuc != null)
                pw.Text(
                  'RUC: $empresaRuc',
                  style: const pw.TextStyle(fontSize: 7),
                  textAlign: pw.TextAlign.center,
                ),
              if (direccionFiscal != null && direccionFiscal.isNotEmpty)
                pw.Text(
                  direccionFiscal,
                  style: const pw.TextStyle(fontSize: 6),
                  textAlign: pw.TextAlign.center,
                ),

              _dottedLine(thickness: 1.2),

              // ── Title ──
              pw.Text(
                titulo,
                style: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                ),
                textAlign: pw.TextAlign.center,
              ),
              pw.Text(
                guia.codigoGenerado,
                style: pw.TextStyle(
                  fontSize: 8,
                  fontWeight: pw.FontWeight.bold,
                ),
                textAlign: pw.TextAlign.center,
              ),
              pw.Align(
                alignment: pw.Alignment.centerLeft,
                child: pw.Text(
                  'Fecha emisión: ${_formatDate(guia.fechaEmision)}',
                  style: const pw.TextStyle(fontSize: 7),
                ),
              ),

              _dottedLine(),

              // ── Motivo de traslado ──
              pw.Align(
                alignment: pw.Alignment.centerLeft,
                child: pw.RichText(
                  text: pw.TextSpan(
                    children: [
                      pw.TextSpan(
                        text: 'MOTIVO: ',
                        style: pw.TextStyle(
                          fontSize: 7,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.TextSpan(
                        text: _motivoLabel(guia.motivoTraslado),
                        style: const pw.TextStyle(fontSize: 7),
                      ),
                    ],
                  ),
                ),
              ),
              pw.Align(
                alignment: pw.Alignment.centerLeft,
                child: pw.Text(
                  'Fecha inicio traslado: ${_formatDate(guia.fechaInicioTraslado)}',
                  style: const pw.TextStyle(fontSize: 7),
                ),
              ),
              if (guia.observaciones != null && guia.observaciones!.isNotEmpty)
                pw.Align(
                  alignment: pw.Alignment.centerLeft,
                  child: pw.Text(
                    'Obs: ${guia.observaciones}',
                    style: pw.TextStyle(
                      fontSize: 7,
                      fontStyle: pw.FontStyle.italic,
                    ),
                  ),
                ),

              _dottedLine(),

              // ── Destinatario ──
              pw.Align(
                alignment: pw.Alignment.centerLeft,
                child: pw.Text(
                  'DESTINATARIO',
                  style: pw.TextStyle(
                    fontSize: 7,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 2),
              pw.Align(
                alignment: pw.Alignment.centerLeft,
                child: pw.Text(
                  '${_tipoDocLabel(guia.clienteTipoDocumento)}: ${guia.clienteNumeroDocumento}',
                  style: const pw.TextStyle(fontSize: 7),
                ),
              ),
              pw.Align(
                alignment: pw.Alignment.centerLeft,
                child: pw.Text(
                  guia.clienteDenominacion,
                  style: const pw.TextStyle(fontSize: 7),
                ),
              ),
              if (guia.clienteDireccion != null &&
                  guia.clienteDireccion!.isNotEmpty)
                pw.Align(
                  alignment: pw.Alignment.centerLeft,
                  child: pw.Text(
                    'Dir: ${guia.clienteDireccion}',
                    style: const pw.TextStyle(fontSize: 7),
                  ),
                ),

              _dottedLine(),

              // ── Puntos de traslado ──
              pw.Align(
                alignment: pw.Alignment.centerLeft,
                child: pw.Text(
                  'PUNTO DE PARTIDA',
                  style: pw.TextStyle(
                    fontSize: 7,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.Align(
                alignment: pw.Alignment.centerLeft,
                child: pw.Text(
                  'Ubigeo: ${guia.puntoPartidaUbigeo}',
                  style: const pw.TextStyle(fontSize: 7),
                ),
              ),
              pw.Align(
                alignment: pw.Alignment.centerLeft,
                child: pw.Text(
                  'Dir: $dirPartida',
                  style: const pw.TextStyle(fontSize: 7),
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Align(
                alignment: pw.Alignment.centerLeft,
                child: pw.Text(
                  'PUNTO DE LLEGADA',
                  style: pw.TextStyle(
                    fontSize: 7,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.Align(
                alignment: pw.Alignment.centerLeft,
                child: pw.Text(
                  'Ubigeo: ${guia.puntoLlegadaUbigeo}',
                  style: const pw.TextStyle(fontSize: 7),
                ),
              ),
              pw.Align(
                alignment: pw.Alignment.centerLeft,
                child: pw.Text(
                  'Dir: $dirLlegada',
                  style: const pw.TextStyle(fontSize: 7),
                ),
              ),

              _dottedLine(),

              // ── Transporte ──
              pw.Align(
                alignment: pw.Alignment.centerLeft,
                child: pw.Text(
                  'TRANSPORTE',
                  style: pw.TextStyle(
                    fontSize: 7,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 2),
              pw.Align(
                alignment: pw.Alignment.centerLeft,
                child: pw.Text(
                  'Modalidad: ${guia.tipoTransporte == 'PUBLICO' ? 'Público' : 'Privado'}',
                  style: const pw.TextStyle(fontSize: 7),
                ),
              ),
              if (guia.tipoTransporte == 'PUBLICO') ...[
                if (guia.transportistaDenominacion != null)
                  pw.Align(
                    alignment: pw.Alignment.centerLeft,
                    child: pw.Text(
                      'Transportista: ${guia.transportistaDenominacion}',
                      style: const pw.TextStyle(fontSize: 7),
                    ),
                  ),
              ],
              if (guia.tipoTransporte == 'PRIVADO') ...[
                if (guia.conductorNombre != null ||
                    guia.conductorApellidos != null)
                  pw.Align(
                    alignment: pw.Alignment.centerLeft,
                    child: pw.Text(
                      'Conductor: ${guia.conductorNombre ?? ''} ${guia.conductorApellidos ?? ''}',
                      style: const pw.TextStyle(fontSize: 7),
                    ),
                  ),
                if (guia.conductorNumeroLicencia != null)
                  pw.Align(
                    alignment: pw.Alignment.centerLeft,
                    child: pw.Text(
                      'Licencia: ${guia.conductorNumeroLicencia}',
                      style: const pw.TextStyle(fontSize: 7),
                    ),
                  ),
              ],
              if (guia.transportistaPlacaNumero != null)
                pw.Align(
                  alignment: pw.Alignment.centerLeft,
                  child: pw.Text(
                    'Placa: ${guia.transportistaPlacaNumero}',
                    style: const pw.TextStyle(fontSize: 7),
                  ),
                ),

              _dottedLine(),

              // ── Items table ──
              pw.Align(
                alignment: pw.Alignment.centerLeft,
                child: pw.Text(
                  'DETALLE',
                  style: pw.TextStyle(
                    fontSize: 8,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 3),
              // Table header
              pw.Row(
                children: [
                  pw.SizedBox(
                    width: 28,
                    child: pw.Text(
                      'CANT',
                      style: pw.TextStyle(
                        fontSize: 6,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                  pw.Expanded(
                    child: pw.Text(
                      'DESCRIPCIÓN',
                      style: pw.TextStyle(
                        fontSize: 6,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                  pw.SizedBox(
                    width: 30,
                    child: pw.Text(
                      'U.M.',
                      style: pw.TextStyle(
                        fontSize: 6,
                        fontWeight: pw.FontWeight.bold,
                      ),
                      textAlign: pw.TextAlign.right,
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 2),
              // Table rows
              ...detalles.map((d) {
                final qty = d.cantidad % 1 == 0
                    ? d.cantidad.toInt().toString()
                    : d.cantidad.toStringAsFixed(2);
                return pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 2),
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.SizedBox(
                        width: 28,
                        child: pw.Text(
                          qty,
                          style: const pw.TextStyle(fontSize: 7),
                        ),
                      ),
                      pw.Expanded(
                        child: pw.Text(
                          d.descripcion,
                          style: const pw.TextStyle(fontSize: 7),
                        ),
                      ),
                      pw.SizedBox(
                        width: 30,
                        child: pw.Text(
                          d.unidadMedida,
                          style: const pw.TextStyle(fontSize: 7),
                          textAlign: pw.TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                );
              }),

              _dottedLine(),

              // ── Peso section ──
              pw.Align(
                alignment: pw.Alignment.centerLeft,
                child: pw.Text(
                  'Peso bruto total: ${guia.pesoBrutoTotal.toStringAsFixed(2)} ${guia.pesoBrutoUnidadMedida}',
                  style: const pw.TextStyle(fontSize: 7),
                ),
              ),
              if (guia.numeroBultos != null)
                pw.Align(
                  alignment: pw.Alignment.centerLeft,
                  child: pw.Text(
                    'Número de bultos: ${guia.numeroBultos}',
                    style: const pw.TextStyle(fontSize: 7),
                  ),
                ),

              _dottedLine(),

              // ── QR Code ──
              if (guia.cadenaQR != null && guia.cadenaQR!.isNotEmpty) ...[
                pw.SizedBox(height: 6),
                pw.Center(
                  child: pw.BarcodeWidget(
                    barcode: Barcode.qrCode(),
                    data: guia.cadenaQR!,
                    width: 65,
                    height: 65,
                  ),
                ),
                pw.SizedBox(height: 4),
              ],

              // ── Footer ──
              pw.Text(
                'Representación impresa de la GRE',
                style: const pw.TextStyle(fontSize: 6),
                textAlign: pw.TextAlign.center,
              ),
              if (guia.sunatHash != null && guia.sunatHash!.isNotEmpty) ...[
                pw.SizedBox(height: 2),
                pw.Text(
                  'Hash: ${guia.sunatHash}',
                  style: const pw.TextStyle(fontSize: 5),
                  textAlign: pw.TextAlign.center,
                ),
              ],
              if (guia.enlaceProveedor != null &&
                  guia.enlaceProveedor!.isNotEmpty) ...[
                pw.SizedBox(height: 1),
                pw.Text(
                  'Consulte en: ${guia.enlaceProveedor}',
                  style: const pw.TextStyle(fontSize: 5.5),
                  textAlign: pw.TextAlign.center,
                ),
              ],

              pw.SizedBox(height: 8),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  // ── Helpers ──

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

  static String _formatDate(DateTime date) {
    final d = date.isUtc ? date.toLocal() : date;
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  static String _tipoDocLabel(String tipo) {
    switch (tipo) {
      case '6':
        return 'RUC';
      case '1':
        return 'DNI';
      case '4':
        return 'C.E.';
      case '7':
        return 'PASAPORTE';
      default:
        return 'DOC';
    }
  }

  static String _motivoLabel(String motivo) {
    const labels = {
      'VENTA': 'VENTA',
      'COMPRA': 'COMPRA',
      'TRASLADO_ENTRE_ESTABLECIMIENTOS': 'TRASLADO ENTRE ESTABLECIMIENTOS',
      'DEVOLUCION': 'DEVOLUCIÓN',
      'CONSIGNACION': 'CONSIGNACIÓN',
      'IMPORTACION': 'IMPORTACIÓN',
      'EXPORTACION': 'EXPORTACIÓN',
      'OTROS': 'OTROS',
      'VENTA_SUJETA_A_CONFIRMACION': 'VENTA SUJETA A CONFIRMACIÓN',
      'VENTA_CON_ENTREGA_A_TERCEROS': 'VENTA CON ENTREGA A TERCEROS',
      'TRASLADO_BIENES_TRANSFORMACION':
          'TRASLADO BIENES PARA TRANSFORMACIÓN',
      'TRASLADO_EMISOR_ITINERANTE': 'TRASLADO EMISOR ITINERANTE',
      'RECOJO_BIENES_TRANSFORMADOS': 'RECOJO BIENES TRANSFORMADOS',
    };
    return labels[motivo] ?? motivo;
  }
}

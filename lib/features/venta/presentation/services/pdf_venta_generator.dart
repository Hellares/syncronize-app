import 'dart:typed_data';
import 'package:barcode/barcode.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../../../core/services/pdf/pdf_document_style.dart';
import '../../../../core/services/pdf/pdf_row_builders.dart';
import '../../../../core/utils/number_to_words.dart';
import '../../../configuracion_documentos/domain/entities/configuracion_documento_completa.dart';
import '../../domain/entities/venta.dart';

class PdfVentaGenerator {
  /// Genera cadenaQR en formato SUNAT-compliant:
  /// RUC|TIPO_DOC|SERIE|NUMERO|IGV|TOTAL|FECHA|TIPO_DOC_CLIENTE|NUM_DOC_CLIENTE|HASH|
  static String _generarQrSunat(Venta venta, String? ruc) {
    // Si no es comprobante electrónico, usar formato interno
    if (venta.tipoComprobante == null || venta.tipoComprobante == 'TICKET') {
      final f = venta.fechaVenta;
      return '${venta.codigo}|${f.day.toString().padLeft(2, '0')}/${f.month.toString().padLeft(2, '0')}/${f.year}|${venta.total.toStringAsFixed(2)}';
    }

    // Tipo documento SUNAT: 01=Factura, 03=Boleta, 07=NC, 08=ND
    String tipoDocSunat;
    switch (venta.tipoComprobante) {
      case 'FACTURA': tipoDocSunat = '01'; break;
      case 'BOLETA': tipoDocSunat = '03'; break;
      case 'NOTA_CREDITO': tipoDocSunat = '07'; break;
      case 'NOTA_DEBITO': tipoDocSunat = '08'; break;
      default: tipoDocSunat = '03';
    }

    // Serie y número desde codigoComprobante (F001-00000001)
    final partes = (venta.codigoComprobante ?? '').split('-');
    final serie = partes.isNotEmpty ? partes[0] : '';
    final numero = partes.length > 1 ? partes[1] : '';

    // Fecha DD/MM/YYYY
    final f = venta.fechaVenta;
    final fecha = '${f.day.toString().padLeft(2, '0')}/${f.month.toString().padLeft(2, '0')}/${f.year}';

    // Tipo documento cliente: 6=RUC, 1=DNI
    final docCliente = venta.documentoCliente ?? '';
    String tipoDocCliente;
    if (docCliente.length == 11) {
      tipoDocCliente = '6';
    } else if (docCliente.length == 8) {
      tipoDocCliente = '1';
    } else {
      tipoDocCliente = '-';
    }

    final igv = (venta.comprobanteIgv ?? 0.0).toStringAsFixed(2);
    final total = venta.total.toStringAsFixed(2);
    final hash = venta.comprobanteSunatHash ?? '';

    return '${ruc ?? ''}|$tipoDocSunat|$serie|$numero|$igv|$total|$fecha|$tipoDocCliente|$docCliente|$hash|';
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

    // Estilo unificado: colores + márgenes + flags. Venta usa defaults
    // distintos a cotización/compra (4mm margen, body color negro, primary
    // negro cuando no hay config).
    final style = PdfDocumentStyle.fromConfig(
      documentConfig: documentConfig,
      empresaNombre: empresaNombre,
      empresaRuc: empresaRuc,
      empresaDireccion: direccionFiscal,
      defaultPrimaryColor: PdfColors.black,
      defaultBodyColor: PdfColors.black,
      defaultMarginMm: 4.0,
    );
    final colorPrimario = style.colorPrimario;
    final colorCuerpo = style.colorCuerpo;
    final mostrarLogo = style.showLogo;
    final mostrarDatosEmpresa = style.showDatosEmpresa;
    final mostrarDatosCliente = style.showDatosCliente;
    final mostrarDetalles = style.showDetalles;
    final mostrarTotales = style.showTotales;
    final mostrarObservaciones = style.showObservaciones;
    final mostrarPiePagina = style.showPiePagina;
    // Pie específico de VENTA (política de devoluciones, etc.) con fallback
    // al texto general de la configuración de documentos.
    final textoPie = documentConfig?.configuracion.pieVentaEfectivo ??
        style.textoPiePagina ??
        'Gracias por su compra!';

    // Márgenes (venta solo usa horizontal/vertical simétricos del valor de
    // margenIzquierdo/margenSuperior — preserva esa semántica histórica).
    final margenH = style.marginLeftPt;
    final margenV = style.marginTopPt;

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
                  child: pw.Text(
                      'Vendedor: ${venta.vendedorAlias ?? venta.vendedorNombre}',
                      style: pw.TextStyle(fontSize: 6, color: colorCuerpo)),
                ),
              if (venta.cajeroNombre != null)
                pw.Align(
                  alignment: pw.Alignment.centerLeft,
                  child: pw.Text(
                      'Cajero: ${venta.cajeroAlias ?? venta.cajeroNombre}',
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
                // Renderizar items agrupando consecutivos del mismo origenComboId
                // bajo un header con el nombre del combo y el ahorro total.
                ..._buildDetallesConCombosAgrupados(
                  detalles,
                  simboloMoneda,
                  colorPrimario,
                  colorCuerpo,
                ),
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
              // Resumen de crédito
              if (esCredito && venta.cuotas != null && venta.cuotas!.isNotEmpty) ...[
                pw.SizedBox(height: 2),
                pw.Text(
                  'Cuotas: ${venta.cuotas!.length} | 1ra cuota vence: ${venta.cuotas!.first.fechaVencimiento.day.toString().padLeft(2, '0')}/${venta.cuotas!.first.fechaVencimiento.month.toString().padLeft(2, '0')}/${venta.cuotas!.first.fechaVencimiento.year}',
                  style: pw.TextStyle(fontSize: 6.5, color: colorCuerpo),
                ),
              ],
              pw.SizedBox(height: 2),

              // Totales — formato SUNAT unificado
              if (mostrarTotales) ...[
                ..._buildTotalesUnificados(venta, simboloMoneda, nombreImpuesto, colorPrimario, colorCuerpo),
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

                if (esComprobante) ...[
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
              ] else if (venta.metodoPagoDisplay != null) ...[
                _buildTotalRow('Metodo', venta.metodoPagoDisplay!,
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

              // QR Code: SUNAT si tiene cadenaQR, sino generar formato SUNAT-compliant
              pw.SizedBox(height: 8),
              _dottedLine(color: colorPrimario),
              pw.SizedBox(height: 6),
              pw.Center(
                child: pw.BarcodeWidget(
                  barcode: Barcode.qrCode(),
                  data: venta.comprobanteCadenaQR ??
                      _generarQrSunat(venta, ruc),
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
                if (venta.comprobanteEnlaceProveedor != null) ...[
                  pw.SizedBox(height: 1),
                  pw.Text(
                    'Consulte en: ${venta.comprobanteEnlaceProveedor}',
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

  /// Renderiza los items de la venta agrupando consecutivos del mismo
  /// `origenComboId` bajo un header con el nombre del combo y el "Ahorro"
  /// total (suma de descuentos prorrateados de los componentes).
  ///
  /// Items sueltos (sin origenComboId) se renderizan tal cual.
  /// Asume que los items del mismo combo están contiguos (lo está al
  /// crearse desde el cubit, y el backend respeta `orden`).
  static List<pw.Widget> _buildDetallesConCombosAgrupados(
    List<dynamic> detalles, // List<VentaDetalle>
    String simboloMoneda,
    PdfColor colorPrimario,
    PdfColor colorCuerpo,
  ) {
    final widgets = <pw.Widget>[];
    String? lastCombo;

    for (var i = 0; i < detalles.length; i++) {
      final d = detalles[i];
      final origen = d.origenComboId as String?;
      final origenNombre = d.origenComboNombre as String?;

      // Header del combo cuando empieza un nuevo grupo.
      if (origen != null && origen != lastCombo) {
        double ahorroCombo = 0;
        for (final x in detalles) {
          if (x.origenComboId == origen) {
            ahorroCombo += (x.descuento as double);
          }
        }
        widgets.add(pw.Padding(
          padding: const pw.EdgeInsets.only(top: 2, bottom: 1),
          child: pw.Row(
            children: [
              pw.Text('🏷 ', style: pw.TextStyle(fontSize: 7, color: colorPrimario)),
              pw.Expanded(
                child: pw.Text(
                  'COMBO: ${(origenNombre ?? 'Combo').toUpperCase()}',
                  style: pw.TextStyle(
                    fontSize: 7,
                    fontWeight: pw.FontWeight.bold,
                    color: colorPrimario,
                  ),
                ),
              ),
              if (ahorroCombo > 0)
                pw.Text(
                  'Ahorro $simboloMoneda${ahorroCombo.toStringAsFixed(2)}',
                  style: pw.TextStyle(
                    fontSize: 6,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.green700,
                  ),
                ),
            ],
          ),
        ));
        lastCombo = origen;
      } else if (origen == null) {
        lastCombo = null;
      }

      final qty = d.cantidad % 1 == 0
          ? d.cantidad.toInt().toString()
          : d.cantidad.toStringAsFixed(2);
      // Total de línea sin ICBPER (ICBPER se muestra aparte como impuesto)
      final totalLinea = (d.total as double) - (d.icbper as double);
      final descuento = d.descuento as double;
      final esItemDeCombo = origen != null;

      widgets.add(pw.Padding(
        padding: pw.EdgeInsets.only(
          bottom: 2,
          left: esItemDeCombo ? 8 : 0, // sangría visual para items del combo
        ),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.SizedBox(
              width: esItemDeCombo ? 14 : 22,
              child: pw.Text(qty,
                  style: pw.TextStyle(fontSize: 7, color: colorCuerpo)),
            ),
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(d.descripcion,
                      style: pw.TextStyle(fontSize: 6, color: colorCuerpo)),
                  if (descuento > 0)
                    pw.Text(
                      'Desc $simboloMoneda${descuento.toStringAsFixed(2)}',
                      style: pw.TextStyle(
                          fontSize: 5, color: PdfColors.green700),
                    ),
                  // Línea que cobra una orden de servicio: la línea va por
                  // el COSTO NETO (el comprobante sale por el total); aquí
                  // se desglosa el adelanto previo (con su método) y lo
                  // efectivamente cobrado HOY (total − adelanto).
                  if (d.esOrdenServicio == true &&
                      (d.ordenAdelanto ?? 0) > 0) ...[
                    pw.Text(
                      'Adelanto${d.ordenMetodoPagoAdelanto != null ? " (${d.ordenMetodoPagoAdelanto})" : ""} '
                      '-$simboloMoneda${d.ordenAdelanto!.toStringAsFixed(2)}',
                      style: pw.TextStyle(
                          fontSize: 5, color: PdfColors.green700),
                    ),
                    pw.Text(
                      'Saldo cobrado hoy $simboloMoneda${((d.total as double) - (d.ordenAdelanto as double)).toStringAsFixed(2)}',
                      style: pw.TextStyle(
                          fontSize: 5,
                          fontWeight: pw.FontWeight.bold,
                          color: colorCuerpo),
                    ),
                  ],
                ],
              ),
            ),
            pw.SizedBox(
              width: 42,
              child: pw.Text(
                '$simboloMoneda${d.precioUnitario.toStringAsFixed(2)}',
                style: pw.TextStyle(fontSize: 7, color: colorCuerpo),
                textAlign: pw.TextAlign.right,
              ),
            ),
            pw.SizedBox(
              width: 48,
              child: pw.Text(
                '$simboloMoneda${totalLinea.toStringAsFixed(2)}',
                style: pw.TextStyle(fontSize: 7, color: colorCuerpo),
                textAlign: pw.TextAlign.right,
              ),
            ),
          ],
        ),
      ));
    }

    return widgets;
  }

  /// Totales unificados formato SUNAT: Op. Gravada, Inafecta, Exonerada, Descuento, IGV, ICBPER
  static List<pw.Widget> _buildTotalesUnificados(
    Venta venta, String simbolo, String nombreImpuesto, PdfColor colorPrimario, PdfColor colorCuerpo,
  ) {
    final gravada = venta.comprobanteGravada ?? venta.subtotal;
    final exonerada = venta.comprobanteExonerada ?? 0;
    final inafecta = venta.comprobanteInafecta ?? 0;
    final igv = venta.comprobanteIgv ?? venta.impuestos;
    final icbper = venta.comprobanteIcbper ?? 0;

    return [
      _buildTotalRow('Op. Gravada', '$simbolo${gravada.toStringAsFixed(2)}', color: colorCuerpo),
      _buildTotalRow('Op. Exonerada', '$simbolo${exonerada.toStringAsFixed(2)}', color: colorCuerpo),
      _buildTotalRow('Op. Inafecta', '$simbolo${inafecta.toStringAsFixed(2)}', color: colorCuerpo),
      _buildTotalRow('Descuento', venta.descuento > 0 ? '-$simbolo${venta.descuento.toStringAsFixed(2)}' : '$simbolo${0.toStringAsFixed(2)}', color: colorCuerpo),
      _buildTotalRow(nombreImpuesto, '$simbolo${igv.toStringAsFixed(2)}', color: colorCuerpo),
      _buildTotalRow('ICBPER', '$simbolo${icbper.toStringAsFixed(2)}', color: colorCuerpo),
    ];
  }

  static pw.Widget _dottedLine({
    PdfColor color = PdfColors.black,
    double thickness = 0.8,
  }) =>
      PdfRowBuilders.dottedLine(color: color, thickness: thickness);

  // Venta usa padding `bottom: 1` (más compacto que cotización/compra) y
  // soporta color → pasa overrides explícitos.
  static pw.Widget _buildTotalRow(String label, String value,
          {PdfColor color = PdfColors.black, double fontSize = 8}) =>
      PdfRowBuilders.totalRow(
        label: label,
        value: value,
        fontSize: fontSize,
        color: color,
        padding: const pw.EdgeInsets.only(bottom: 1),
      );
}

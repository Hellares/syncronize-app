import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:syncronize/core/services/pdf/builders/pdf_header_builder.dart';
import 'package:syncronize/core/services/pdf/builders/pdf_party_builder.dart';
import 'package:syncronize/core/services/pdf/builders/pdf_totales_builder.dart';
import 'package:syncronize/core/services/pdf/pdf_document_service.dart';
import 'package:syncronize/core/services/pdf/pdf_document_style.dart';
import 'package:syncronize/core/services/pdf/pdf_row_builders.dart';
import 'package:syncronize/core/utils/date_formatter.dart';
import '../../domain/entities/cotizacion.dart';
import '../../../configuracion_documentos/domain/entities/configuracion_documento_completa.dart';

/// Servicio para generar documentos PDF de cotizaciones
class PdfCotizacionGenerator {
  /// Genera un PDF con el detalle completo de la cotizacion
  ///
  /// [modoCliente] = true: oculta precios unitarios, descuentos y subtotales
  /// por linea, mostrando solo descripcion, cantidad y el total final.
  /// Ideal para compartir con el cliente sin exponer costos internos.
  ///
  /// [documentConfig] si se proporciona, se usan colores, margenes y secciones
  /// visibles de la configuracion centralizada. Si es null, se usan defaults.
  static Future<Uint8List> generarDocumento({
    required Cotizacion cotizacion,
    required String empresaNombre,
    String? empresaRuc,
    String? empresaDireccion,
    String? empresaTelefono,
    Uint8List? logoEmpresa,
    bool modoCliente = false,
    String nombreImpuesto = 'IGV',
    double porcentajeImpuesto = 18.0,
    ConfiguracionDocumentoCompleta? documentConfig,
  }) async {
    final style = PdfDocumentStyle.fromConfig(
      documentConfig: documentConfig,
      empresaNombre: empresaNombre,
      empresaRuc: empresaRuc,
      empresaDireccion: empresaDireccion,
      empresaTelefono: empresaTelefono,
      defaultMarginMm: 10.0,
    );
    final primaryColor = style.colorPrimario;
    final isTicket = style.formatoPapel.isTicket;
    final sectionSpacing = isTicket ? 8.0 : 20.0;
    final smallSpacing = isTicket ? 6.0 : 12.0;

    final bodyWidgets = <pw.Widget>[
      _buildHeader(
        empresaNombre: style.empresaNombre,
        empresaRuc: style.empresaRuc,
        empresaDireccion: style.empresaDireccion,
        empresaTelefono: style.empresaTelefono,
        sedeNombre: style.sedeNombre,
        logo: style.showLogo ? logoEmpresa : null,
        cotizacion: cotizacion,
        primaryColor: primaryColor,
        showDatosEmpresa: style.showDatosEmpresa,
        isTicket: isTicket,
      ),
      pw.SizedBox(height: sectionSpacing),
      if (style.showDatosCliente) ...[
        _buildClienteInfo(cotizacion,
            primaryColor: primaryColor, isTicket: isTicket),
        pw.SizedBox(height: sectionSpacing),
      ],
      if (style.showDetalles) ...[
        _buildDetallesTable(
          cotizacion,
          modoCliente: modoCliente,
          primaryColor: primaryColor,
          isTicket: isTicket,
        ),
        pw.SizedBox(height: sectionSpacing),
      ],
      if (style.showTotales)
        _buildTotalesSection(cotizacion,
            modoCliente: modoCliente,
            nombreImpuesto: nombreImpuesto,
            porcentajeImpuesto: porcentajeImpuesto,
            isTicket: isTicket),
      if (style.showObservaciones &&
          cotizacion.observaciones != null &&
          cotizacion.observaciones!.isNotEmpty) ...[
        pw.SizedBox(height: sectionSpacing),
        _buildObservaciones(
          cotizacion.observaciones!,
          primaryColor: primaryColor,
          isTicket: isTicket,
        ),
      ],
      if (style.showCondiciones &&
          cotizacion.condiciones != null &&
          cotizacion.condiciones!.isNotEmpty) ...[
        pw.SizedBox(height: smallSpacing),
        _buildCondiciones(cotizacion.condiciones!, isTicket: isTicket),
      ],
      if (style.showFirma && !isTicket) ...[
        pw.SizedBox(height: 30),
        _buildFirmasSection(cotizacion),
      ],
    ];

    return PdfDocumentService.build(
      style: style,
      bodyWidgets: bodyWidgets,
      footerText: style.textoPiePagina ?? 'Gracias por su preferencia',
      showPaginacion:
          documentConfig?.configuracion.mostrarPaginacion ?? true,
    );
  }

  /// Encabezado con datos de empresa y titulo
  static pw.Widget _buildHeader({
    required String empresaNombre,
    String? empresaRuc,
    String? empresaDireccion,
    String? empresaTelefono,
    String? sedeNombre,
    Uint8List? logo,
    required Cotizacion cotizacion,
    required PdfColor primaryColor,
    bool showDatosEmpresa = true,
    bool isTicket = false,
  }) {
    final lines = <String>[
      'Fecha: ${DateFormatter.formatDate(cotizacion.fechaEmision)}',
      if (cotizacion.fechaVencimiento != null)
        'Vence: ${DateFormatter.formatDate(cotizacion.fechaVencimiento!)}',
      'Moneda: ${cotizacion.moneda}',
    ];
    return PdfHeaderBuilder.build(
      empresaNombre: empresaNombre,
      empresaRuc: empresaRuc,
      empresaDireccion: empresaDireccion,
      empresaTelefono: empresaTelefono,
      sedeNombre: sedeNombre,
      logo: logo,
      tipoDocumento: 'COTIZACION',
      codigo: cotizacion.codigo,
      documentLines: lines,
      primaryColor: primaryColor,
      showDatosEmpresa: showDatosEmpresa,
      isTicket: isTicket,
    );
  }

  /// Seccion con nombre de la cotizacion e info del cliente
  static pw.Widget _buildClienteInfo(
    Cotizacion cotizacion, {
    required PdfColor primaryColor,
    bool isTicket = false,
  }) {
    final fields = <PdfPartyField>[
      PdfPartyField('Cliente', cotizacion.nombreCliente),
      if (cotizacion.documentoCliente != null)
        PdfPartyField('Documento', cotizacion.documentoCliente!),
      if (cotizacion.emailCliente != null)
        PdfPartyField('Email', cotizacion.emailCliente!),
      if (cotizacion.telefonoCliente != null)
        PdfPartyField('Telefono', cotizacion.telefonoCliente!),
      if (cotizacion.direccionCliente != null)
        PdfPartyField('Direccion', cotizacion.direccionCliente!),
      if (cotizacion.vendedorNombre != null)
        PdfPartyField('Vendedor', cotizacion.vendedorNombre!),
    ];

    pw.Widget? header;
    if (cotizacion.nombre != null && cotizacion.nombre!.isNotEmpty) {
      header = PdfPartyBuilder.banner(
        text: cotizacion.nombre!,
        primaryColor: primaryColor,
        isTicket: isTicket,
      );
    }

    return PdfPartyBuilder.build(
      title: 'DATOS DEL CLIENTE',
      fields: fields,
      primaryColor: primaryColor,
      isTicket: isTicket,
      headerBlock: header,
    );
  }

  /// Tabla de detalles/items
  static pw.Widget _buildDetallesTable(
    Cotizacion cotizacion, {
    bool modoCliente = false,
    required PdfColor primaryColor,
    bool isTicket = false,
  }) {
    final detalles = cotizacion.detalles ?? [];
    final cellFontSize = isTicket ? 7.0 : 9.0;
    final cellPadding = isTicket ? 3.0 : 6.0;
    final titleSize = isTicket ? 8.0 : 11.0;

    // Ticket mode: simplified columns — #, Desc, Cant, Subtotal
    // A4 mode client: #, Descripcion, Cantidad
    // A4 mode interno: #, Descripcion, Cantidad, P.Unit, Desc, Subtotal
    final Map<int, pw.TableColumnWidth> columnWidths;
    final List<pw.Widget> headerCells;

    if (isTicket) {
      if (modoCliente) {
        columnWidths = {
          0: const pw.FixedColumnWidth(18),
          1: const pw.FlexColumnWidth(3),
          2: const pw.FixedColumnWidth(30),
        };
        headerCells = [
          _buildTableCell('#',
              isHeader: true, color: PdfColors.white, fontSize: cellFontSize, padding: cellPadding),
          _buildTableCell('Desc.',
              isHeader: true, color: PdfColors.white, fontSize: cellFontSize, padding: cellPadding),
          _buildTableCell('Cant.',
              isHeader: true, color: PdfColors.white, align: pw.TextAlign.center,
              fontSize: cellFontSize, padding: cellPadding),
        ];
      } else {
        columnWidths = {
          0: const pw.FixedColumnWidth(18),
          1: const pw.FlexColumnWidth(3),
          2: const pw.FixedColumnWidth(28),
          3: const pw.FixedColumnWidth(45),
          4: const pw.FixedColumnWidth(45),
        };
        headerCells = [
          _buildTableCell('#',
              isHeader: true, color: PdfColors.white, fontSize: cellFontSize, padding: cellPadding),
          _buildTableCell('Desc.',
              isHeader: true, color: PdfColors.white, fontSize: cellFontSize, padding: cellPadding),
          _buildTableCell('Cant.',
              isHeader: true, color: PdfColors.white, align: pw.TextAlign.center,
              fontSize: cellFontSize, padding: cellPadding),
          _buildTableCell('P.U.',
              isHeader: true, color: PdfColors.white, align: pw.TextAlign.right,
              fontSize: cellFontSize, padding: cellPadding),
          _buildTableCell('Subt.',
              isHeader: true, color: PdfColors.white, align: pw.TextAlign.right,
              fontSize: cellFontSize, padding: cellPadding),
        ];
      }
    } else if (modoCliente) {
      columnWidths = {
        0: const pw.FixedColumnWidth(30),
        1: const pw.FlexColumnWidth(4),
        2: const pw.FixedColumnWidth(60),
      };
      headerCells = [
        _buildTableCell('#', isHeader: true, color: PdfColors.white),
        _buildTableCell('Descripcion', isHeader: true, color: PdfColors.white),
        _buildTableCell('Cantidad',
            isHeader: true, color: PdfColors.white, align: pw.TextAlign.center),
      ];
    } else {
      columnWidths = {
        0: const pw.FixedColumnWidth(30),
        1: const pw.FlexColumnWidth(3),
        2: const pw.FixedColumnWidth(55),
        3: const pw.FixedColumnWidth(70),
        4: const pw.FixedColumnWidth(60),
        5: const pw.FixedColumnWidth(70),
      };
      headerCells = [
        _buildTableCell('#', isHeader: true, color: PdfColors.white),
        _buildTableCell('Descripcion', isHeader: true, color: PdfColors.white),
        _buildTableCell('Cantidad',
            isHeader: true, color: PdfColors.white, align: pw.TextAlign.center),
        _buildTableCell('P. Unit.',
            isHeader: true, color: PdfColors.white, align: pw.TextAlign.right),
        _buildTableCell('Desc.',
            isHeader: true, color: PdfColors.white, align: pw.TextAlign.right),
        _buildTableCell('Subtotal',
            isHeader: true, color: PdfColors.white, align: pw.TextAlign.right),
      ];
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          isTicket ? 'DETALLE' : 'DETALLE DE LA COTIZACION',
          style: pw.TextStyle(
            fontSize: titleSize,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: isTicket ? 4 : 8),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey400),
          columnWidths: columnWidths,
          children: [
            pw.TableRow(
              decoration: pw.BoxDecoration(color: primaryColor),
              children: headerCells,
            ),
            ...detalles.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;

              final List<pw.Widget> rowCells;
              if (isTicket) {
                if (modoCliente) {
                  rowCells = [
                    _buildTableCell('${index + 1}',
                        align: pw.TextAlign.center, fontSize: cellFontSize, padding: cellPadding),
                    _buildTableCell(item.descripcion,
                        fontSize: cellFontSize, padding: cellPadding),
                    _buildTableCell(_formatCantidad(item.cantidad),
                        align: pw.TextAlign.center, fontSize: cellFontSize, padding: cellPadding),
                  ];
                } else {
                  rowCells = [
                    _buildTableCell('${index + 1}',
                        align: pw.TextAlign.center, fontSize: cellFontSize, padding: cellPadding),
                    _buildTableCell(item.descripcion,
                        fontSize: cellFontSize, padding: cellPadding),
                    _buildTableCell(_formatCantidad(item.cantidad),
                        align: pw.TextAlign.center, fontSize: cellFontSize, padding: cellPadding),
                    _buildTableCell(_formatMonto(item.precioUnitario),
                        align: pw.TextAlign.right, fontSize: cellFontSize, padding: cellPadding),
                    _buildTableCell(
                        _formatMonto(
                            item.cantidad * item.precioUnitario - item.descuento),
                        align: pw.TextAlign.right, fontSize: cellFontSize, padding: cellPadding),
                  ];
                }
              } else if (modoCliente) {
                rowCells = [
                  _buildTableCell('${index + 1}', align: pw.TextAlign.center),
                  _buildTableCell(item.descripcion),
                  _buildTableCell(_formatCantidad(item.cantidad),
                      align: pw.TextAlign.center),
                ];
              } else {
                rowCells = [
                  _buildTableCell('${index + 1}', align: pw.TextAlign.center),
                  _buildTableCell(item.descripcion),
                  _buildTableCell(_formatCantidad(item.cantidad),
                      align: pw.TextAlign.center),
                  _buildTableCell(_formatMonto(item.precioUnitario),
                      align: pw.TextAlign.right),
                  _buildTableCell(
                      item.descuento > 0 ? _formatMonto(item.descuento) : '-',
                      align: pw.TextAlign.right),
                  _buildTableCell(
                      _formatMonto(
                          item.cantidad * item.precioUnitario - item.descuento),
                      align: pw.TextAlign.right),
                ];
              }

              return pw.TableRow(
                decoration: pw.BoxDecoration(
                  color: index % 2 == 0 ? PdfColors.white : PdfColors.grey100,
                ),
                children: rowCells,
              );
            }),
          ],
        ),
      ],
    );
  }

  /// Seccion de totales
  static pw.Widget _buildTotalesSection(
    Cotizacion cotizacion, {
    bool modoCliente = false,
    String nombreImpuesto = 'IGV',
    double porcentajeImpuesto = 18.0,
    bool isTicket = false,
  }) =>
      PdfTotalesBuilder.simple(
        moneda: cotizacion.moneda,
        subtotal: cotizacion.subtotal,
        descuento: cotizacion.descuento,
        impuestos: cotizacion.impuestos,
        total: cotizacion.total,
        nombreImpuesto: nombreImpuesto,
        porcentajeImpuesto: porcentajeImpuesto,
        isTicket: isTicket,
        hideBreakdown: modoCliente,
      );

  /// Observaciones
  static pw.Widget _buildObservaciones(
    String observaciones, {
    required PdfColor primaryColor,
    bool isTicket = false,
  }) {
    final lightBg = PdfColor(
      primaryColor.red,
      primaryColor.green,
      primaryColor.blue,
      0.08,
    );
    final borderColor = PdfColor(
      primaryColor.red,
      primaryColor.green,
      primaryColor.blue,
      0.3,
    );
    final labelSize = isTicket ? 7.0 : 10.0;
    final textSize = isTicket ? 6.0 : 9.0;

    return pw.Container(
      width: double.infinity,
      padding: pw.EdgeInsets.all(isTicket ? 6 : 12),
      decoration: pw.BoxDecoration(
        color: lightBg,
        border: pw.Border.all(color: borderColor),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'OBSERVACIONES',
            style: pw.TextStyle(
              fontSize: labelSize,
              fontWeight: pw.FontWeight.bold,
              color: primaryColor,
            ),
          ),
          pw.SizedBox(height: isTicket ? 3 : 6),
          pw.Text(observaciones, style: pw.TextStyle(fontSize: textSize)),
        ],
      ),
    );
  }

  /// Condiciones comerciales
  static pw.Widget _buildCondiciones(String condiciones,
      {bool isTicket = false}) {
    final labelSize = isTicket ? 7.0 : 10.0;
    final textSize = isTicket ? 6.0 : 9.0;

    return pw.Container(
      width: double.infinity,
      padding: pw.EdgeInsets.all(isTicket ? 6 : 12),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            isTicket ? 'CONDICIONES' : 'CONDICIONES COMERCIALES',
            style: pw.TextStyle(
              fontSize: labelSize,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: isTicket ? 3 : 6),
          pw.Text(condiciones, style: pw.TextStyle(fontSize: textSize)),
        ],
      ),
    );
  }

  /// Firmas
  static pw.Widget _buildFirmasSection(Cotizacion cotizacion) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
      children: [
        _buildFirmaBox('VENDEDOR', cotizacion.vendedorNombre ?? ''),
        _buildFirmaBox('CLIENTE', cotizacion.nombreCliente),
      ],
    );
  }

  static pw.Widget _buildFirmaBox(String label, String nombre) {
    return pw.Container(
      width: 200,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Container(
            height: 60,
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey400),
              borderRadius:
                  const pw.BorderRadius.all(pw.Radius.circular(4)),
            ),
          ),
          pw.SizedBox(height: 6),
          pw.Text('_______________________',
              style: const pw.TextStyle(fontSize: 8)),
          pw.SizedBox(height: 2),
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          if (nombre.isNotEmpty)
            pw.Text(nombre, style: const pw.TextStyle(fontSize: 8)),
        ],
      ),
    );
  }

  // ==================== HELPERS ====================

  // _buildInfoRow y _buildTotalRow ya no son usados — los call sites
  // delegan directamente a los builders compuestos
  // (PdfPartyBuilder/PdfTotalesBuilder). Solo queda _buildTableCell
  // porque la tabla de detalles aún lo usa.
  static pw.Widget _buildTableCell(
    String text, {
    bool isHeader = false,
    double fontSize = 9,
    PdfColor? color,
    pw.TextAlign align = pw.TextAlign.left,
    double padding = 6,
  }) =>
      PdfRowBuilders.tableCell(
        text,
        isHeader: isHeader,
        fontSize: fontSize,
        color: color,
        align: align,
        padding: padding,
      );

  static String _formatMonto(double value) {
    return value.toStringAsFixed(2);
  }

  static String _formatCantidad(double value) {
    if (value == value.truncateToDouble()) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(2);
  }
}

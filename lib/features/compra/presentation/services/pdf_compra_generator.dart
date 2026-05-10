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
import '../../domain/entities/compra.dart';
import '../../domain/entities/orden_compra.dart';
import '../../../configuracion_documentos/domain/entities/configuracion_documento_completa.dart';

class PdfCompraGenerator {
  // ==================== COMPRA (RECEPCION) ====================

  static Future<Uint8List> generarDocumentoCompra({
    required Compra compra,
    required String empresaNombre,
    String? empresaRuc,
    String? empresaDireccion,
    String? empresaTelefono,
    Uint8List? logoEmpresa,
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

    final bodyWidgets = <pw.Widget>[
      _buildHeader(
        empresaNombre: style.empresaNombre,
        empresaRuc: style.empresaRuc,
        empresaDireccion: style.empresaDireccion,
        empresaTelefono: style.empresaTelefono,
        sedeNombre: style.sedeNombre ?? compra.sedeNombre,
        logo: style.showLogo ? logoEmpresa : null,
        titulo: 'COMPRA',
        codigo: compra.codigo,
        fechaLabel: 'Recepcion',
        fecha: compra.fechaRecepcion,
        moneda: compra.moneda,
        estado: compra.estadoTexto,
        primaryColor: primaryColor,
        showDatosEmpresa: style.showDatosEmpresa,
        isTicket: isTicket,
      ),
      pw.SizedBox(height: sectionSpacing),
      _buildProveedorInfo(
        nombreProveedor: compra.nombreProveedor,
        documentoProveedor: compra.documentoProveedor,
        tipoDocumento: compra.tipoDocumentoProveedor,
        serieDocumento: compra.serieDocumentoProveedor,
        numeroDocumento: compra.numeroDocumentoProveedor,
        terminosPago: compra.terminosPago,
        diasCredito: compra.diasCredito,
        fechaVencimientoPago: compra.fechaVencimientoPago,
        primaryColor: primaryColor,
        isTicket: isTicket,
      ),
      pw.SizedBox(height: sectionSpacing),
      if (style.showDetalles) ...[
        _buildDetallesCompraTable(compra, primaryColor: primaryColor, isTicket: isTicket),
        pw.SizedBox(height: sectionSpacing),
      ],
      if (style.showTotales)
        _buildTotalesSection(
          moneda: compra.moneda,
          subtotal: compra.subtotal,
          descuento: compra.descuento,
          impuestos: compra.impuestos,
          total: compra.total,
          nombreImpuesto: nombreImpuesto,
          porcentajeImpuesto: porcentajeImpuesto,
          isTicket: isTicket,
        ),
      if (style.showObservaciones &&
          compra.observaciones != null &&
          compra.observaciones!.isNotEmpty) ...[
        pw.SizedBox(height: sectionSpacing),
        _buildObservaciones(compra.observaciones!, primaryColor: primaryColor, isTicket: isTicket),
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

  // ==================== ORDEN DE COMPRA ====================

  static Future<Uint8List> generarDocumentoOrdenCompra({
    required OrdenCompra orden,
    required String empresaNombre,
    String? empresaRuc,
    String? empresaDireccion,
    String? empresaTelefono,
    Uint8List? logoEmpresa,
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
        sedeNombre: style.sedeNombre ?? orden.sedeNombre,
        logo: style.showLogo ? logoEmpresa : null,
        titulo: 'ORDEN DE COMPRA',
        codigo: orden.codigo,
        fechaLabel: 'Emision',
        fecha: orden.fechaEmision,
        fechaEntrega: orden.fechaEntregaEsperada,
        moneda: orden.moneda,
        estado: orden.estadoTexto,
        primaryColor: primaryColor,
        showDatosEmpresa: style.showDatosEmpresa,
        isTicket: isTicket,
      ),
      pw.SizedBox(height: sectionSpacing),
      _buildProveedorInfo(
        nombreProveedor: orden.nombreProveedor,
        documentoProveedor: orden.documentoProveedor,
        emailProveedor: orden.emailProveedor,
        telefonoProveedor: orden.telefonoProveedor,
        direccionProveedor: orden.direccionProveedor,
        terminosPago: orden.terminosPago,
        diasCredito: orden.diasCredito,
        primaryColor: primaryColor,
        isTicket: isTicket,
      ),
      pw.SizedBox(height: sectionSpacing),
      if (style.showDetalles) ...[
        _buildDetallesOrdenTable(orden, primaryColor: primaryColor, isTicket: isTicket),
        pw.SizedBox(height: sectionSpacing),
      ],
      if (style.showTotales)
        _buildTotalesSection(
          moneda: orden.moneda,
          subtotal: orden.subtotal,
          descuento: orden.descuento,
          impuestos: orden.impuestos,
          total: orden.total,
          nombreImpuesto: nombreImpuesto,
          porcentajeImpuesto: porcentajeImpuesto,
          isTicket: isTicket,
        ),
      if (style.showObservaciones &&
          orden.observaciones != null &&
          orden.observaciones!.isNotEmpty) ...[
        pw.SizedBox(height: sectionSpacing),
        _buildObservaciones(orden.observaciones!, primaryColor: primaryColor, isTicket: isTicket),
      ],
      if (style.showCondiciones &&
          orden.condiciones != null &&
          orden.condiciones!.isNotEmpty) ...[
        pw.SizedBox(height: smallSpacing),
        _buildCondiciones(orden.condiciones!, isTicket: isTicket),
      ],
      if (style.showFirma && !isTicket) ...[
        pw.SizedBox(height: 30),
        _buildFirmasSection(),
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

  // ==================== WIDGETS COMPARTIDOS ====================

  static pw.Widget _buildHeader({
    required String empresaNombre,
    String? empresaRuc,
    String? empresaDireccion,
    String? empresaTelefono,
    String? sedeNombre,
    Uint8List? logo,
    required String titulo,
    required String codigo,
    required String fechaLabel,
    required DateTime fecha,
    DateTime? fechaEntrega,
    required String moneda,
    required String estado,
    required PdfColor primaryColor,
    bool showDatosEmpresa = true,
    bool isTicket = false,
  }) {
    final lines = <String>[
      '$fechaLabel: ${DateFormatter.formatDate(fecha)}',
      if (fechaEntrega != null)
        'Entrega: ${DateFormatter.formatDate(fechaEntrega)}',
      'Estado: $estado',
      'Moneda: $moneda',
    ];
    return PdfHeaderBuilder.build(
      empresaNombre: empresaNombre,
      empresaRuc: empresaRuc,
      empresaDireccion: empresaDireccion,
      empresaTelefono: empresaTelefono,
      sedeNombre: sedeNombre,
      logo: logo,
      tipoDocumento: titulo,
      codigo: codigo,
      documentLines: lines,
      primaryColor: primaryColor,
      showDatosEmpresa: showDatosEmpresa,
      isTicket: isTicket,
    );
  }

  static pw.Widget _buildProveedorInfo({
    required String nombreProveedor,
    String? documentoProveedor,
    String? emailProveedor,
    String? telefonoProveedor,
    String? direccionProveedor,
    String? tipoDocumento,
    String? serieDocumento,
    String? numeroDocumento,
    String? terminosPago,
    int? diasCredito,
    DateTime? fechaVencimientoPago,
    required PdfColor primaryColor,
    bool isTicket = false,
  }) {
    String? docFactura;
    if (tipoDocumento != null) {
      final serie = serieDocumento ?? '';
      final numero = numeroDocumento ?? '';
      docFactura = '$tipoDocumento $serie-$numero'.trim();
    }

    final fields = <PdfPartyField>[
      PdfPartyField('Proveedor', nombreProveedor),
      if (documentoProveedor != null && documentoProveedor.isNotEmpty)
        PdfPartyField('RUC/DNI', documentoProveedor),
      if (emailProveedor != null && emailProveedor.isNotEmpty)
        PdfPartyField('Email', emailProveedor),
      if (telefonoProveedor != null && telefonoProveedor.isNotEmpty)
        PdfPartyField('Telefono', telefonoProveedor),
      if (direccionProveedor != null && direccionProveedor.isNotEmpty)
        PdfPartyField('Direccion', direccionProveedor),
      if (docFactura != null) PdfPartyField('Doc. Proveedor', docFactura),
      if (terminosPago != null && terminosPago.isNotEmpty)
        PdfPartyField('Terminos Pago', terminosPago),
      if (diasCredito != null)
        PdfPartyField('Dias Credito', '$diasCredito dias'),
      if (fechaVencimientoPago != null)
        PdfPartyField(
            'Venc. Pago', DateFormatter.formatDate(fechaVencimientoPago)),
    ];

    return PdfPartyBuilder.build(
      title: 'DATOS DEL PROVEEDOR',
      fields: fields,
      primaryColor: primaryColor,
      isTicket: isTicket,
      // Compra usa labelWidth ligeramente más ancho (55/80 vs 50/70 default)
      infoRowLabelWidth: isTicket ? 55.0 : 80.0,
    );
  }

  static pw.Widget _buildDetallesCompraTable(
    Compra compra, {
    required PdfColor primaryColor,
    bool isTicket = false,
  }) {
    final detalles = compra.detalles ?? [];
    final cellFontSize = isTicket ? 7.0 : 9.0;
    final cellPadding = isTicket ? 3.0 : 6.0;
    final titleSize = isTicket ? 8.0 : 11.0;

    final Map<int, pw.TableColumnWidth> columnWidths;
    final List<pw.Widget> headerCells;

    if (isTicket) {
      columnWidths = {
        0: const pw.FixedColumnWidth(18),
        1: const pw.FlexColumnWidth(3),
        2: const pw.FixedColumnWidth(28),
        3: const pw.FixedColumnWidth(45),
        4: const pw.FixedColumnWidth(45),
      };
      headerCells = [
        _buildTableCell('#', isHeader: true, color: PdfColors.white, fontSize: cellFontSize, padding: cellPadding),
        _buildTableCell('Desc.', isHeader: true, color: PdfColors.white, fontSize: cellFontSize, padding: cellPadding),
        _buildTableCell('Cant.', isHeader: true, color: PdfColors.white, align: pw.TextAlign.center, fontSize: cellFontSize, padding: cellPadding),
        _buildTableCell('P.U.', isHeader: true, color: PdfColors.white, align: pw.TextAlign.right, fontSize: cellFontSize, padding: cellPadding),
        _buildTableCell('Subt.', isHeader: true, color: PdfColors.white, align: pw.TextAlign.right, fontSize: cellFontSize, padding: cellPadding),
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
        _buildTableCell('Cantidad', isHeader: true, color: PdfColors.white, align: pw.TextAlign.center),
        _buildTableCell('P. Unit.', isHeader: true, color: PdfColors.white, align: pw.TextAlign.right),
        _buildTableCell('Desc.', isHeader: true, color: PdfColors.white, align: pw.TextAlign.right),
        _buildTableCell('Subtotal', isHeader: true, color: PdfColors.white, align: pw.TextAlign.right),
      ];
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          isTicket ? 'DETALLE' : 'DETALLE DE LA COMPRA',
          style: pw.TextStyle(fontSize: titleSize, fontWeight: pw.FontWeight.bold),
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
              final lineSubtotal = item.cantidad * item.precioUnitario - item.descuento;

              final List<pw.Widget> rowCells;
              if (isTicket) {
                rowCells = [
                  _buildTableCell('${index + 1}', align: pw.TextAlign.center, fontSize: cellFontSize, padding: cellPadding),
                  _buildTableCell(item.descripcion, fontSize: cellFontSize, padding: cellPadding),
                  _buildTableCell(_formatCantidad(item.cantidad.toDouble()), align: pw.TextAlign.center, fontSize: cellFontSize, padding: cellPadding),
                  _buildTableCell(_formatMonto(item.precioUnitario), align: pw.TextAlign.right, fontSize: cellFontSize, padding: cellPadding),
                  _buildTableCell(_formatMonto(lineSubtotal), align: pw.TextAlign.right, fontSize: cellFontSize, padding: cellPadding),
                ];
              } else {
                rowCells = [
                  _buildTableCell('${index + 1}', align: pw.TextAlign.center),
                  _buildTableCell(item.descripcion),
                  _buildTableCell(_formatCantidad(item.cantidad.toDouble()), align: pw.TextAlign.center),
                  _buildTableCell(_formatMonto(item.precioUnitario), align: pw.TextAlign.right),
                  _buildTableCell(item.descuento > 0 ? _formatMonto(item.descuento) : '-', align: pw.TextAlign.right),
                  _buildTableCell(_formatMonto(lineSubtotal), align: pw.TextAlign.right),
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

  static pw.Widget _buildDetallesOrdenTable(
    OrdenCompra orden, {
    required PdfColor primaryColor,
    bool isTicket = false,
  }) {
    final detalles = orden.detalles ?? [];
    final cellFontSize = isTicket ? 7.0 : 9.0;
    final cellPadding = isTicket ? 3.0 : 6.0;
    final titleSize = isTicket ? 8.0 : 11.0;

    final Map<int, pw.TableColumnWidth> columnWidths;
    final List<pw.Widget> headerCells;

    if (isTicket) {
      columnWidths = {
        0: const pw.FixedColumnWidth(18),
        1: const pw.FlexColumnWidth(3),
        2: const pw.FixedColumnWidth(28),
        3: const pw.FixedColumnWidth(45),
        4: const pw.FixedColumnWidth(45),
      };
      headerCells = [
        _buildTableCell('#', isHeader: true, color: PdfColors.white, fontSize: cellFontSize, padding: cellPadding),
        _buildTableCell('Desc.', isHeader: true, color: PdfColors.white, fontSize: cellFontSize, padding: cellPadding),
        _buildTableCell('Cant.', isHeader: true, color: PdfColors.white, align: pw.TextAlign.center, fontSize: cellFontSize, padding: cellPadding),
        _buildTableCell('P.U.', isHeader: true, color: PdfColors.white, align: pw.TextAlign.right, fontSize: cellFontSize, padding: cellPadding),
        _buildTableCell('Subt.', isHeader: true, color: PdfColors.white, align: pw.TextAlign.right, fontSize: cellFontSize, padding: cellPadding),
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
        _buildTableCell('Cantidad', isHeader: true, color: PdfColors.white, align: pw.TextAlign.center),
        _buildTableCell('P. Unit.', isHeader: true, color: PdfColors.white, align: pw.TextAlign.right),
        _buildTableCell('Desc.', isHeader: true, color: PdfColors.white, align: pw.TextAlign.right),
        _buildTableCell('Subtotal', isHeader: true, color: PdfColors.white, align: pw.TextAlign.right),
      ];
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          isTicket ? 'DETALLE' : 'DETALLE DE LA ORDEN DE COMPRA',
          style: pw.TextStyle(fontSize: titleSize, fontWeight: pw.FontWeight.bold),
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
              final lineSubtotal = item.cantidad * item.precioUnitario - item.descuento;

              final List<pw.Widget> rowCells;
              if (isTicket) {
                rowCells = [
                  _buildTableCell('${index + 1}', align: pw.TextAlign.center, fontSize: cellFontSize, padding: cellPadding),
                  _buildTableCell(item.descripcion, fontSize: cellFontSize, padding: cellPadding),
                  _buildTableCell(_formatCantidad(item.cantidad.toDouble()), align: pw.TextAlign.center, fontSize: cellFontSize, padding: cellPadding),
                  _buildTableCell(_formatMonto(item.precioUnitario), align: pw.TextAlign.right, fontSize: cellFontSize, padding: cellPadding),
                  _buildTableCell(_formatMonto(lineSubtotal), align: pw.TextAlign.right, fontSize: cellFontSize, padding: cellPadding),
                ];
              } else {
                rowCells = [
                  _buildTableCell('${index + 1}', align: pw.TextAlign.center),
                  _buildTableCell(item.descripcion),
                  _buildTableCell(_formatCantidad(item.cantidad.toDouble()), align: pw.TextAlign.center),
                  _buildTableCell(_formatMonto(item.precioUnitario), align: pw.TextAlign.right),
                  _buildTableCell(item.descuento > 0 ? _formatMonto(item.descuento) : '-', align: pw.TextAlign.right),
                  _buildTableCell(_formatMonto(lineSubtotal), align: pw.TextAlign.right),
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

  static pw.Widget _buildTotalesSection({
    required String moneda,
    required double subtotal,
    required double descuento,
    required double impuestos,
    required double total,
    String nombreImpuesto = 'IGV',
    double porcentajeImpuesto = 18.0,
    bool isTicket = false,
  }) =>
      PdfTotalesBuilder.simple(
        moneda: moneda,
        subtotal: subtotal,
        descuento: descuento,
        impuestos: impuestos,
        total: total,
        nombreImpuesto: nombreImpuesto,
        porcentajeImpuesto: porcentajeImpuesto,
        isTicket: isTicket,
      );

  static pw.Widget _buildObservaciones(
    String observaciones, {
    required PdfColor primaryColor,
    bool isTicket = false,
  }) {
    final lightBg = PdfColor(primaryColor.red, primaryColor.green, primaryColor.blue, 0.08);
    final borderColor = PdfColor(primaryColor.red, primaryColor.green, primaryColor.blue, 0.3);
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
          pw.Text('OBSERVACIONES',
              style: pw.TextStyle(fontSize: labelSize, fontWeight: pw.FontWeight.bold, color: primaryColor)),
          pw.SizedBox(height: isTicket ? 3 : 6),
          pw.Text(observaciones, style: pw.TextStyle(fontSize: textSize)),
        ],
      ),
    );
  }

  static pw.Widget _buildCondiciones(String condiciones, {bool isTicket = false}) {
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
            style: pw.TextStyle(fontSize: labelSize, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: isTicket ? 3 : 6),
          pw.Text(condiciones, style: pw.TextStyle(fontSize: textSize)),
        ],
      ),
    );
  }

  static pw.Widget _buildFirmasSection() {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
      children: [
        _buildFirmaBox('RESPONSABLE'),
        _buildFirmaBox('PROVEEDOR'),
      ],
    );
  }

  static pw.Widget _buildFirmaBox(String label) {
    return pw.Container(
      width: 200,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Container(
            height: 60,
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey400),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
            ),
          ),
          pw.SizedBox(height: 6),
          pw.Text('_______________________', style: const pw.TextStyle(fontSize: 8)),
          pw.SizedBox(height: 2),
          pw.Text(label, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
        ],
      ),
    );
  }

  // ==================== HELPERS ====================

  // _buildInfoRow y _buildTotalRow ya no se usan — call sites delegan
  // directamente a builders compuestos. Queda _buildTableCell porque la
  // tabla de detalles aún lo usa.
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

  static String _formatMonto(double value) => value.toStringAsFixed(2);

  static String _formatCantidad(double value) {
    if (value == value.truncateToDouble()) return value.toInt().toString();
    return value.toStringAsFixed(2);
  }
}

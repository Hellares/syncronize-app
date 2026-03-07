import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:syncronize/core/utils/date_formatter.dart';
import '../../domain/entities/compra.dart';
import '../../domain/entities/orden_compra.dart';
import '../../../configuracion_documentos/domain/entities/configuracion_documento_completa.dart';
import '../../../configuracion_documentos/domain/entities/plantilla_documento.dart';

PdfColor _hexToColor(String hex) {
  hex = hex.replaceFirst('#', '');
  if (hex.length == 6) {
    hex = 'FF$hex';
  }
  return PdfColor.fromInt(int.parse(hex, radix: 16));
}

const _defaultPrimaryHex = '#1565C0';

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
    final pdf = pw.Document();

    final primaryColor = _hexToColor(
      documentConfig?.colorPrimarioEfectivo ?? _defaultPrimaryHex,
    );
    final config = documentConfig?.configuracion;
    final plantilla = documentConfig?.plantilla;

    final effectiveEmpresaNombre = config?.nombreComercial ?? empresaNombre;
    final effectiveRuc = config?.ruc ?? empresaRuc;
    final effectiveDireccion =
        documentConfig?.direccionEfectiva ?? config?.direccion ?? empresaDireccion;
    final effectiveTelefono =
        documentConfig?.telefonoEfectivo ?? config?.telefono ?? empresaTelefono;

    final marginTop = (plantilla?.margenSuperior ?? 10.0) * PdfPageFormat.mm;
    final marginBottom = (plantilla?.margenInferior ?? 10.0) * PdfPageFormat.mm;
    final marginLeft = (plantilla?.margenIzquierdo ?? 10.0) * PdfPageFormat.mm;
    final marginRight = (plantilla?.margenDerecho ?? 10.0) * PdfPageFormat.mm;

    final showLogo = plantilla?.mostrarLogo ?? true;
    final showDatosEmpresa = plantilla?.mostrarDatosEmpresa ?? true;
    final showDetalles = plantilla?.mostrarDetalles ?? true;
    final showTotales = plantilla?.mostrarTotales ?? true;
    final showObservaciones = plantilla?.mostrarObservaciones ?? true;
    final showPiePagina = plantilla?.mostrarPiePagina ?? true;

    final footerText = config?.textoPiePagina ?? 'Gracias por su preferencia';
    final showPaginacion = config?.mostrarPaginacion ?? true;

    final formatoPapel = plantilla?.formatoPapel ?? FormatoPapel.A4;
    final isTicket = formatoPapel.isTicket;
    final sectionSpacing = isTicket ? 8.0 : 20.0;

    final margin = pw.EdgeInsets.only(
      top: marginTop,
      bottom: marginBottom,
      left: marginLeft,
      right: marginRight,
    );

    final contentWidgets = <pw.Widget>[
      _buildHeader(
        empresaNombre: effectiveEmpresaNombre,
        empresaRuc: effectiveRuc,
        empresaDireccion: effectiveDireccion,
        empresaTelefono: effectiveTelefono,
        sedeNombre: documentConfig?.sede?.nombre ?? compra.sedeNombre,
        logo: showLogo ? logoEmpresa : null,
        titulo: 'COMPRA',
        codigo: compra.codigo,
        fechaLabel: 'Recepcion',
        fecha: compra.fechaRecepcion,
        moneda: compra.moneda,
        estado: compra.estadoTexto,
        primaryColor: primaryColor,
        showDatosEmpresa: showDatosEmpresa,
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
      if (showDetalles) ...[
        _buildDetallesCompraTable(compra, primaryColor: primaryColor, isTicket: isTicket),
        pw.SizedBox(height: sectionSpacing),
      ],
      if (showTotales)
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
      if (showObservaciones &&
          compra.observaciones != null &&
          compra.observaciones!.isNotEmpty) ...[
        pw.SizedBox(height: sectionSpacing),
        _buildObservaciones(compra.observaciones!, primaryColor: primaryColor, isTicket: isTicket),
      ],
    ];

    if (isTicket) {
      final ticketWidth = formatoPapel == FormatoPapel.TICKET_80MM
          ? 80 * PdfPageFormat.mm
          : 58 * PdfPageFormat.mm;

      if (showPiePagina) {
        contentWidgets.add(_buildFooter(1, 1,
            footerText: footerText, showPaginacion: false, isTicket: true));
      }

      pdf.addPage(pw.Page(
        pageFormat: PdfPageFormat(ticketWidth, double.infinity),
        margin: margin,
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          mainAxisSize: pw.MainAxisSize.min,
          children: contentWidgets,
        ),
      ));
    } else {
      pdf.addPage(pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: margin,
        build: (context) => contentWidgets,
        footer: showPiePagina
            ? (context) => _buildFooter(
                  context.pageNumber, context.pagesCount,
                  footerText: footerText,
                  showPaginacion: showPaginacion,
                  isTicket: false,
                )
            : null,
      ));
    }

    return pdf.save();
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
    final pdf = pw.Document();

    final primaryColor = _hexToColor(
      documentConfig?.colorPrimarioEfectivo ?? _defaultPrimaryHex,
    );
    final config = documentConfig?.configuracion;
    final plantilla = documentConfig?.plantilla;

    final effectiveEmpresaNombre = config?.nombreComercial ?? empresaNombre;
    final effectiveRuc = config?.ruc ?? empresaRuc;
    final effectiveDireccion =
        documentConfig?.direccionEfectiva ?? config?.direccion ?? empresaDireccion;
    final effectiveTelefono =
        documentConfig?.telefonoEfectivo ?? config?.telefono ?? empresaTelefono;

    final marginTop = (plantilla?.margenSuperior ?? 10.0) * PdfPageFormat.mm;
    final marginBottom = (plantilla?.margenInferior ?? 10.0) * PdfPageFormat.mm;
    final marginLeft = (plantilla?.margenIzquierdo ?? 10.0) * PdfPageFormat.mm;
    final marginRight = (plantilla?.margenDerecho ?? 10.0) * PdfPageFormat.mm;

    final showLogo = plantilla?.mostrarLogo ?? true;
    final showDatosEmpresa = plantilla?.mostrarDatosEmpresa ?? true;
    final showDetalles = plantilla?.mostrarDetalles ?? true;
    final showTotales = plantilla?.mostrarTotales ?? true;
    final showObservaciones = plantilla?.mostrarObservaciones ?? true;
    final showCondiciones = plantilla?.mostrarCondiciones ?? true;
    final showFirma = plantilla?.mostrarFirma ?? true;
    final showPiePagina = plantilla?.mostrarPiePagina ?? true;

    final footerText = config?.textoPiePagina ?? 'Gracias por su preferencia';
    final showPaginacion = config?.mostrarPaginacion ?? true;

    final formatoPapel = plantilla?.formatoPapel ?? FormatoPapel.A4;
    final isTicket = formatoPapel.isTicket;
    final sectionSpacing = isTicket ? 8.0 : 20.0;
    final smallSpacing = isTicket ? 6.0 : 12.0;

    final margin = pw.EdgeInsets.only(
      top: marginTop,
      bottom: marginBottom,
      left: marginLeft,
      right: marginRight,
    );

    final contentWidgets = <pw.Widget>[
      _buildHeader(
        empresaNombre: effectiveEmpresaNombre,
        empresaRuc: effectiveRuc,
        empresaDireccion: effectiveDireccion,
        empresaTelefono: effectiveTelefono,
        sedeNombre: documentConfig?.sede?.nombre ?? orden.sedeNombre,
        logo: showLogo ? logoEmpresa : null,
        titulo: 'ORDEN DE COMPRA',
        codigo: orden.codigo,
        fechaLabel: 'Emision',
        fecha: orden.fechaEmision,
        fechaEntrega: orden.fechaEntregaEsperada,
        moneda: orden.moneda,
        estado: orden.estadoTexto,
        primaryColor: primaryColor,
        showDatosEmpresa: showDatosEmpresa,
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
      if (showDetalles) ...[
        _buildDetallesOrdenTable(orden, primaryColor: primaryColor, isTicket: isTicket),
        pw.SizedBox(height: sectionSpacing),
      ],
      if (showTotales)
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
      if (showObservaciones &&
          orden.observaciones != null &&
          orden.observaciones!.isNotEmpty) ...[
        pw.SizedBox(height: sectionSpacing),
        _buildObservaciones(orden.observaciones!, primaryColor: primaryColor, isTicket: isTicket),
      ],
      if (showCondiciones &&
          orden.condiciones != null &&
          orden.condiciones!.isNotEmpty) ...[
        pw.SizedBox(height: smallSpacing),
        _buildCondiciones(orden.condiciones!, isTicket: isTicket),
      ],
      if (showFirma && !isTicket) ...[
        pw.SizedBox(height: 30),
        _buildFirmasSection(),
      ],
    ];

    if (isTicket) {
      final ticketWidth = formatoPapel == FormatoPapel.TICKET_80MM
          ? 80 * PdfPageFormat.mm
          : 58 * PdfPageFormat.mm;

      if (showPiePagina) {
        contentWidgets.add(_buildFooter(1, 1,
            footerText: footerText, showPaginacion: false, isTicket: true));
      }

      pdf.addPage(pw.Page(
        pageFormat: PdfPageFormat(ticketWidth, double.infinity),
        margin: margin,
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          mainAxisSize: pw.MainAxisSize.min,
          children: contentWidgets,
        ),
      ));
    } else {
      pdf.addPage(pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: margin,
        build: (context) => contentWidgets,
        footer: showPiePagina
            ? (context) => _buildFooter(
                  context.pageNumber, context.pagesCount,
                  footerText: footerText,
                  showPaginacion: showPaginacion,
                  isTicket: false,
                )
            : null,
      ));
    }

    return pdf.save();
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
    final titleFontSize = isTicket ? 10.0 : 16.0;
    final codeFontSize = isTicket ? 9.0 : 13.0;
    final detailFontSize = isTicket ? 7.0 : 9.0;
    final logoHeight = isTicket ? 30.0 : 50.0;
    final logoWidth = isTicket ? 70.0 : 120.0;

    final empresaInfo = pw.Column(
      crossAxisAlignment: isTicket ? pw.CrossAxisAlignment.center : pw.CrossAxisAlignment.start,
      children: [
        if (logo != null)
          pw.Image(
            pw.MemoryImage(logo),
            height: logoHeight,
            width: logoWidth,
            fit: pw.BoxFit.contain,
          )
        else
          pw.Text(
            empresaNombre,
            style: pw.TextStyle(fontSize: titleFontSize, fontWeight: pw.FontWeight.bold),
            textAlign: isTicket ? pw.TextAlign.center : pw.TextAlign.left,
          ),
        if (showDatosEmpresa) ...[
          if (sedeNombre != null) ...[
            pw.SizedBox(height: 2),
            pw.Text('Sede: $sedeNombre', style: pw.TextStyle(fontSize: detailFontSize)),
          ],
          if (empresaRuc != null) ...[
            pw.SizedBox(height: isTicket ? 1 : 3),
            pw.Text('RUC: $empresaRuc', style: pw.TextStyle(fontSize: detailFontSize)),
          ],
          if (empresaDireccion != null) ...[
            pw.SizedBox(height: isTicket ? 1 : 2),
            pw.Text(empresaDireccion,
                style: pw.TextStyle(fontSize: detailFontSize),
                textAlign: isTicket ? pw.TextAlign.center : pw.TextAlign.left),
          ],
          if (empresaTelefono != null) ...[
            pw.SizedBox(height: isTicket ? 1 : 2),
            pw.Text('Tel: $empresaTelefono', style: pw.TextStyle(fontSize: detailFontSize)),
          ],
        ],
      ],
    );

    final documentInfo = pw.Container(
      width: isTicket ? double.infinity : null,
      padding: pw.EdgeInsets.all(isTicket ? 6 : 12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: primaryColor, width: isTicket ? 1 : 2),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Text(
            titulo,
            style: pw.TextStyle(
              fontSize: titleFontSize,
              fontWeight: pw.FontWeight.bold,
              color: primaryColor,
            ),
          ),
          pw.SizedBox(height: isTicket ? 3 : 6),
          pw.Text(codigo,
              style: pw.TextStyle(fontSize: codeFontSize, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: isTicket ? 2 : 4),
          pw.Text(
            '$fechaLabel: ${DateFormatter.formatDate(fecha)}',
            style: pw.TextStyle(fontSize: detailFontSize),
          ),
          if (fechaEntrega != null) ...[
            pw.SizedBox(height: isTicket ? 1 : 2),
            pw.Text(
              'Entrega: ${DateFormatter.formatDate(fechaEntrega)}',
              style: pw.TextStyle(fontSize: detailFontSize),
            ),
          ],
          pw.SizedBox(height: isTicket ? 2 : 4),
          pw.Text('Estado: $estado', style: pw.TextStyle(fontSize: detailFontSize)),
          pw.SizedBox(height: isTicket ? 1 : 2),
          pw.Text('Moneda: $moneda', style: pw.TextStyle(fontSize: detailFontSize)),
        ],
      ),
    );

    if (isTicket) {
      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [empresaInfo, pw.SizedBox(height: 6), documentInfo],
      );
    }

    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [pw.Expanded(child: empresaInfo), documentInfo],
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
    final labelSize = isTicket ? 8.0 : 10.0;
    final padding = isTicket ? 8.0 : 15.0;

    String? docFactura;
    if (tipoDocumento != null) {
      final serie = serieDocumento ?? '';
      final numero = numeroDocumento ?? '';
      docFactura = '$tipoDocumento $serie-$numero'.trim();
    }

    final allFields = <pw.Widget>[
      _buildInfoRow('Proveedor', nombreProveedor, isTicket: isTicket),
      if (documentoProveedor != null && documentoProveedor.isNotEmpty)
        _buildInfoRow('RUC/DNI', documentoProveedor, isTicket: isTicket),
      if (emailProveedor != null && emailProveedor.isNotEmpty)
        _buildInfoRow('Email', emailProveedor, isTicket: isTicket),
      if (telefonoProveedor != null && telefonoProveedor.isNotEmpty)
        _buildInfoRow('Telefono', telefonoProveedor, isTicket: isTicket),
      if (direccionProveedor != null && direccionProveedor.isNotEmpty)
        _buildInfoRow('Direccion', direccionProveedor, isTicket: isTicket),
      if (docFactura != null)
        _buildInfoRow('Doc. Proveedor', docFactura, isTicket: isTicket),
      if (terminosPago != null && terminosPago.isNotEmpty)
        _buildInfoRow('Terminos Pago', terminosPago, isTicket: isTicket),
      if (diasCredito != null)
        _buildInfoRow('Dias Credito', '$diasCredito dias', isTicket: isTicket),
      if (fechaVencimientoPago != null)
        _buildInfoRow('Venc. Pago', DateFormatter.formatDate(fechaVencimientoPago),
            isTicket: isTicket),
    ];

    return pw.Container(
      padding: pw.EdgeInsets.all(padding),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'DATOS DEL PROVEEDOR',
            style: pw.TextStyle(
              fontSize: labelSize,
              fontWeight: pw.FontWeight.bold,
              color: primaryColor,
            ),
          ),
          pw.SizedBox(height: isTicket ? 4 : 8),
          pw.Divider(color: PdfColors.grey300),
          pw.SizedBox(height: isTicket ? 4 : 8),
          if (isTicket)
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: allFields,
            )
          else
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: allFields.take((allFields.length / 2).ceil()).toList(),
                  ),
                ),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: allFields.skip((allFields.length / 2).ceil()).toList(),
                  ),
                ),
              ],
            ),
        ],
      ),
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
  }) {
    final totalFontSize = isTicket ? 9.0 : 13.0;
    final rowFontSize = isTicket ? 7.0 : 10.0;
    final containerPadding = isTicket ? 6.0 : 12.0;

    final totalesContent = pw.Container(
      width: isTicket ? double.infinity : 220,
      padding: pw.EdgeInsets.all(containerPadding),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Column(
        children: [
          _buildTotalRow('Subtotal', '$moneda ${_formatMonto(subtotal)}', fontSize: rowFontSize),
          if (descuento > 0)
            _buildTotalRow('Descuento', '- $moneda ${_formatMonto(descuento)}', fontSize: rowFontSize),
          _buildTotalRow(
            '$nombreImpuesto (${porcentajeImpuesto.toStringAsFixed(0)}%)',
            '$moneda ${_formatMonto(impuestos)}',
            fontSize: rowFontSize,
          ),
          pw.Divider(color: PdfColors.grey400),
          pw.SizedBox(height: isTicket ? 2 : 4),
          _buildTotalRow('TOTAL', '$moneda ${_formatMonto(total)}',
              bold: true, fontSize: totalFontSize),
        ],
      ),
    );

    if (isTicket) return totalesContent;

    return pw.Row(
      children: [pw.Expanded(child: pw.SizedBox()), totalesContent],
    );
  }

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

  static pw.Widget _buildFooter(
    int pageNumber,
    int totalPages, {
    String footerText = 'Gracias por su preferencia',
    bool showPaginacion = true,
    bool isTicket = false,
  }) {
    final fontSize = isTicket ? 6.0 : 8.0;

    if (isTicket) {
      return pw.Container(
        margin: const pw.EdgeInsets.only(top: 6),
        padding: const pw.EdgeInsets.symmetric(vertical: 4),
        decoration: const pw.BoxDecoration(
          border: pw.Border(top: pw.BorderSide(color: PdfColors.grey400)),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Text(footerText, style: pw.TextStyle(fontSize: fontSize)),
            pw.SizedBox(height: 2),
            pw.Text('Generado: ${DateFormatter.formatDateTime(DateTime.now())}',
                style: pw.TextStyle(fontSize: fontSize)),
          ],
        ),
      );
    }

    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 20),
      padding: const pw.EdgeInsets.symmetric(vertical: 8),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: PdfColors.grey400)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(footerText, style: pw.TextStyle(fontSize: fontSize)),
          if (showPaginacion)
            pw.Text('Pagina $pageNumber de $totalPages', style: pw.TextStyle(fontSize: fontSize)),
          pw.Text('Generado: ${DateFormatter.formatDateTime(DateTime.now())}',
              style: pw.TextStyle(fontSize: fontSize)),
        ],
      ),
    );
  }

  // ==================== HELPERS ====================

  static pw.Widget _buildInfoRow(String label, String value, {bool isTicket = false}) {
    final fontSize = isTicket ? 7.0 : 9.0;
    final labelWidth = isTicket ? 55.0 : 80.0;
    return pw.Padding(
      padding: pw.EdgeInsets.symmetric(vertical: isTicket ? 1 : 2),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: labelWidth,
            child: pw.Text('$label:', style: pw.TextStyle(fontSize: fontSize, fontWeight: pw.FontWeight.bold)),
          ),
          pw.Expanded(child: pw.Text(value, style: pw.TextStyle(fontSize: fontSize))),
        ],
      ),
    );
  }

  static pw.Widget _buildTableCell(
    String text, {
    bool isHeader = false,
    double fontSize = 9,
    PdfColor? color,
    pw.TextAlign align = pw.TextAlign.left,
    double padding = 6,
  }) {
    return pw.Padding(
      padding: pw.EdgeInsets.all(padding),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: fontSize,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: color,
        ),
        textAlign: align,
      ),
    );
  }

  static pw.Widget _buildTotalRow(String label, String value, {bool bold = false, double fontSize = 10}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(fontSize: fontSize, fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal)),
          pw.Text(value, style: pw.TextStyle(fontSize: fontSize, fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal)),
        ],
      ),
    );
  }

  static String _formatMonto(double value) => value.toStringAsFixed(2);

  static String _formatCantidad(double value) {
    if (value == value.truncateToDouble()) return value.toInt().toString();
    return value.toStringAsFixed(2);
  }
}

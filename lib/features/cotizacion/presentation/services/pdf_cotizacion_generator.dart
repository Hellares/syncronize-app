import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:syncronize/core/utils/date_formatter.dart';
import '../../domain/entities/cotizacion.dart';
import '../../../configuracion_documentos/domain/entities/configuracion_documento_completa.dart';
import '../../../configuracion_documentos/domain/entities/plantilla_documento.dart';

/// Convierte un color hex (#RRGGBB) a PdfColor
PdfColor _hexToColor(String hex) {
  hex = hex.replaceFirst('#', '');
  if (hex.length == 6) {
    hex = 'FF$hex';
  }
  return PdfColor.fromInt(int.parse(hex, radix: 16));
}

/// Color primario por defecto si no hay config
const _defaultPrimaryHex = '#1565C0';

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
    final pdf = pw.Document();

    // Colores dinamicos desde configuracion
    final primaryColor = _hexToColor(
      documentConfig?.colorPrimarioEfectivo ?? _defaultPrimaryHex,
    );
    // Datos de empresa desde configuracion (con fallbacks)
    final config = documentConfig?.configuracion;
    final plantilla = documentConfig?.plantilla;

    final effectiveEmpresaNombre =
        config?.nombreComercial ?? empresaNombre;
    final effectiveRuc = config?.ruc ?? empresaRuc;
    final effectiveDireccion =
        documentConfig?.direccionEfectiva ?? config?.direccion ?? empresaDireccion;
    final effectiveTelefono =
        documentConfig?.telefonoEfectivo ?? config?.telefono ?? empresaTelefono;

    // Margenes dinamicos
    final marginTop = (plantilla?.margenSuperior ?? 10.0) * PdfPageFormat.mm;
    final marginBottom = (plantilla?.margenInferior ?? 10.0) * PdfPageFormat.mm;
    final marginLeft = (plantilla?.margenIzquierdo ?? 10.0) * PdfPageFormat.mm;
    final marginRight = (plantilla?.margenDerecho ?? 10.0) * PdfPageFormat.mm;

    // Flags de visibilidad
    final showLogo = plantilla?.mostrarLogo ?? true;
    final showDatosEmpresa = plantilla?.mostrarDatosEmpresa ?? true;
    final showDatosCliente = plantilla?.mostrarDatosCliente ?? true;
    final showDetalles = plantilla?.mostrarDetalles ?? true;
    final showTotales = plantilla?.mostrarTotales ?? true;
    final showObservaciones = plantilla?.mostrarObservaciones ?? true;
    final showCondiciones = plantilla?.mostrarCondiciones ?? true;
    final showFirma = plantilla?.mostrarFirma ?? true;
    final showPiePagina = plantilla?.mostrarPiePagina ?? true;

    // Texto pie de pagina
    final footerText =
        config?.textoPiePagina ?? 'Gracias por su preferencia';
    final showPaginacion = config?.mostrarPaginacion ?? true;

    // Formato de papel dinámico
    final formatoPapel = plantilla?.formatoPapel ?? FormatoPapel.A4;
    final isTicket = formatoPapel.isTicket;

    // Espaciado dinámico
    final sectionSpacing = isTicket ? 8.0 : 20.0;
    final smallSpacing = isTicket ? 6.0 : 12.0;

    final margin = pw.EdgeInsets.only(
      top: marginTop,
      bottom: marginBottom,
      left: marginLeft,
      right: marginRight,
    );

    // Contenido principal (sin footer — se agrega diferente según tipo de página)
    final contentWidgets = <pw.Widget>[
      _buildHeader(
        empresaNombre: effectiveEmpresaNombre,
        empresaRuc: effectiveRuc,
        empresaDireccion: effectiveDireccion,
        empresaTelefono: effectiveTelefono,
        sedeNombre: documentConfig?.sede?.nombre,
        logo: showLogo ? logoEmpresa : null,
        cotizacion: cotizacion,
        primaryColor: primaryColor,
        showDatosEmpresa: showDatosEmpresa,
        isTicket: isTicket,
      ),
      pw.SizedBox(height: sectionSpacing),
      if (showDatosCliente) ...[
        _buildClienteInfo(cotizacion,
            primaryColor: primaryColor, isTicket: isTicket),
        pw.SizedBox(height: sectionSpacing),
      ],
      if (showDetalles) ...[
        _buildDetallesTable(
          cotizacion,
          modoCliente: modoCliente,
          primaryColor: primaryColor,
          isTicket: isTicket,
        ),
        pw.SizedBox(height: sectionSpacing),
      ],
      if (showTotales)
        _buildTotalesSection(cotizacion,
            modoCliente: modoCliente,
            nombreImpuesto: nombreImpuesto,
            porcentajeImpuesto: porcentajeImpuesto,
            isTicket: isTicket),
      if (showObservaciones &&
          cotizacion.observaciones != null &&
          cotizacion.observaciones!.isNotEmpty) ...[
        pw.SizedBox(height: sectionSpacing),
        _buildObservaciones(
          cotizacion.observaciones!,
          primaryColor: primaryColor,
          isTicket: isTicket,
        ),
      ],
      if (showCondiciones &&
          cotizacion.condiciones != null &&
          cotizacion.condiciones!.isNotEmpty) ...[
        pw.SizedBox(height: smallSpacing),
        _buildCondiciones(cotizacion.condiciones!, isTicket: isTicket),
      ],
      if (showFirma && !isTicket) ...[
        pw.SizedBox(height: 30),
        _buildFirmasSection(cotizacion),
      ],
    ];

    if (isTicket) {
      // Ticket: página única con altura ajustada al contenido
      final ticketWidth = formatoPapel == FormatoPapel.TICKET_80MM
          ? 80 * PdfPageFormat.mm
          : 58 * PdfPageFormat.mm;

      // Agregar footer como parte del contenido para ticket
      if (showPiePagina) {
        contentWidgets.add(_buildFooter(
          cotizacion,
          1,
          1,
          footerText: footerText,
          showPaginacion: false,
          isTicket: true,
        ));
      }

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat(ticketWidth, double.infinity),
          margin: margin,
          build: (context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            mainAxisSize: pw.MainAxisSize.min,
            children: contentWidgets,
          ),
        ),
      );
    } else {
      // A4: MultiPage con paginación normal
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: margin,
          build: (context) => contentWidgets,
          footer: showPiePagina
              ? (context) => _buildFooter(
                    cotizacion,
                    context.pageNumber,
                    context.pagesCount,
                    footerText: footerText,
                    showPaginacion: showPaginacion,
                    isTicket: false,
                  )
              : null,
        ),
      );
    }

    return pdf.save();
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
    final titleFontSize = isTicket ? 10.0 : 16.0;
    final codeFontSize = isTicket ? 9.0 : 13.0;
    final detailFontSize = isTicket ? 7.0 : 9.0;
    final logoHeight = isTicket ? 30.0 : 50.0;
    final logoWidth = isTicket ? 70.0 : 120.0;

    final empresaInfo = pw.Column(
      crossAxisAlignment:
          isTicket ? pw.CrossAxisAlignment.center : pw.CrossAxisAlignment.start,
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
            style: pw.TextStyle(
              fontSize: titleFontSize,
              fontWeight: pw.FontWeight.bold,
            ),
            textAlign: isTicket ? pw.TextAlign.center : pw.TextAlign.left,
          ),
        if (showDatosEmpresa) ...[
          if (sedeNombre != null) ...[
            pw.SizedBox(height: 2),
            pw.Text('Sede: $sedeNombre',
                style: pw.TextStyle(fontSize: detailFontSize)),
          ],
          if (empresaRuc != null) ...[
            pw.SizedBox(height: isTicket ? 1 : 3),
            pw.Text('RUC: $empresaRuc',
                style: pw.TextStyle(fontSize: detailFontSize)),
          ],
          if (empresaDireccion != null) ...[
            pw.SizedBox(height: isTicket ? 1 : 2),
            pw.Text(empresaDireccion,
                style: pw.TextStyle(fontSize: detailFontSize),
                textAlign: isTicket ? pw.TextAlign.center : pw.TextAlign.left),
          ],
          if (empresaTelefono != null) ...[
            pw.SizedBox(height: isTicket ? 1 : 2),
            pw.Text('Tel: $empresaTelefono',
                style: pw.TextStyle(fontSize: detailFontSize)),
          ],
        ],
      ],
    );

    final cotizacionInfo = pw.Container(
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
            'COTIZACION',
            style: pw.TextStyle(
              fontSize: titleFontSize,
              fontWeight: pw.FontWeight.bold,
              color: primaryColor,
            ),
          ),
          pw.SizedBox(height: isTicket ? 3 : 6),
          pw.Text(
            cotizacion.codigo,
            style: pw.TextStyle(
              fontSize: codeFontSize,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: isTicket ? 2 : 4),
          pw.Text(
            'Fecha: ${DateFormatter.formatDate(cotizacion.fechaEmision)}',
            style: pw.TextStyle(fontSize: detailFontSize),
          ),
          if (cotizacion.fechaVencimiento != null) ...[
            pw.SizedBox(height: isTicket ? 1 : 2),
            pw.Text(
              'Vence: ${DateFormatter.formatDate(cotizacion.fechaVencimiento!)}',
              style: pw.TextStyle(fontSize: detailFontSize),
            ),
          ],
          pw.SizedBox(height: isTicket ? 2 : 4),
          pw.Text(
            'Moneda: ${cotizacion.moneda}',
            style: pw.TextStyle(fontSize: detailFontSize),
          ),
        ],
      ),
    );

    // Ticket: stack vertically, todo centrado y ancho completo. A4: side by side
    if (isTicket) {
      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          empresaInfo,
          pw.SizedBox(height: 6),
          cotizacionInfo,
        ],
      );
    }

    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(child: empresaInfo),
        cotizacionInfo,
      ],
    );
  }

  /// Seccion con nombre de la cotizacion e info del cliente
  static pw.Widget _buildClienteInfo(
    Cotizacion cotizacion, {
    required PdfColor primaryColor,
    bool isTicket = false,
  }) {
    // Derive a light tint from primaryColor for background
    final lightBg = PdfColor(
      primaryColor.red,
      primaryColor.green,
      primaryColor.blue,
      0.08,
    );

    final titleSize = isTicket ? 9.0 : 13.0;
    final labelSize = isTicket ? 8.0 : 10.0;
    final padding = isTicket ? 8.0 : 15.0;

    final allClientFields = <pw.Widget>[
      _buildInfoRow('Cliente', cotizacion.nombreCliente, isTicket: isTicket),
      if (cotizacion.documentoCliente != null)
        _buildInfoRow('Documento', cotizacion.documentoCliente!,
            isTicket: isTicket),
      if (cotizacion.emailCliente != null)
        _buildInfoRow('Email', cotizacion.emailCliente!, isTicket: isTicket),
      if (cotizacion.telefonoCliente != null)
        _buildInfoRow('Telefono', cotizacion.telefonoCliente!,
            isTicket: isTicket),
      if (cotizacion.direccionCliente != null)
        _buildInfoRow('Direccion', cotizacion.direccionCliente!,
            isTicket: isTicket),
      if (cotizacion.vendedorNombre != null)
        _buildInfoRow('Vendedor', cotizacion.vendedorNombre!,
            isTicket: isTicket),
    ];

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Nombre de la cotizacion
        if (cotizacion.nombre != null && cotizacion.nombre!.isNotEmpty) ...[
          pw.Container(
            width: double.infinity,
            padding: pw.EdgeInsets.symmetric(
                horizontal: isTicket ? 6 : 12, vertical: isTicket ? 4 : 8),
            decoration: pw.BoxDecoration(
              color: lightBg,
              borderRadius:
                  const pw.BorderRadius.all(pw.Radius.circular(4)),
            ),
            child: pw.Text(
              cotizacion.nombre!,
              style: pw.TextStyle(
                fontSize: titleSize,
                fontWeight: pw.FontWeight.bold,
                color: primaryColor,
              ),
            ),
          ),
          pw.SizedBox(height: isTicket ? 6 : 12),
        ],
        // Datos del cliente
        pw.Container(
          padding: pw.EdgeInsets.all(padding),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey400),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'DATOS DEL CLIENTE',
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
                  children: allClientFields,
                )
              else
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          _buildInfoRow(
                              'Cliente', cotizacion.nombreCliente),
                          if (cotizacion.documentoCliente != null)
                            _buildInfoRow(
                                'Documento', cotizacion.documentoCliente!),
                          if (cotizacion.emailCliente != null)
                            _buildInfoRow(
                                'Email', cotizacion.emailCliente!),
                        ],
                      ),
                    ),
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          if (cotizacion.telefonoCliente != null)
                            _buildInfoRow(
                                'Telefono', cotizacion.telefonoCliente!),
                          if (cotizacion.direccionCliente != null)
                            _buildInfoRow(
                                'Direccion', cotizacion.direccionCliente!),
                          if (cotizacion.vendedorNombre != null)
                            _buildInfoRow(
                                'Vendedor', cotizacion.vendedorNombre!),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ],
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
          if (!modoCliente) ...[
            _buildTotalRow('Subtotal',
                '${cotizacion.moneda} ${_formatMonto(cotizacion.subtotal)}',
                fontSize: rowFontSize),
            if (cotizacion.descuento > 0)
              _buildTotalRow('Descuento',
                  '- ${cotizacion.moneda} ${_formatMonto(cotizacion.descuento)}',
                  fontSize: rowFontSize),
            _buildTotalRow(
                '$nombreImpuesto (${porcentajeImpuesto.toStringAsFixed(0)}%)',
                '${cotizacion.moneda} ${_formatMonto(cotizacion.impuestos)}',
                fontSize: rowFontSize),
            pw.Divider(color: PdfColors.grey400),
            pw.SizedBox(height: isTicket ? 2 : 4),
          ],
          _buildTotalRow(
            'TOTAL',
            '${cotizacion.moneda} ${_formatMonto(cotizacion.total)}',
            bold: true,
            fontSize: totalFontSize,
          ),
        ],
      ),
    );

    if (isTicket) {
      return totalesContent;
    }

    return pw.Row(
      children: [
        pw.Expanded(child: pw.SizedBox()),
        totalesContent,
      ],
    );
  }

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

  /// Footer
  static pw.Widget _buildFooter(
    Cotizacion cotizacion,
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
            pw.Text(
              'Generado: ${DateFormatter.formatDateTime(DateTime.now())}',
              style: pw.TextStyle(fontSize: fontSize),
            ),
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
            pw.Text(
              'Pagina $pageNumber de $totalPages',
              style: pw.TextStyle(fontSize: fontSize),
            ),
          pw.Text(
            'Generado: ${DateFormatter.formatDateTime(DateTime.now())}',
            style: pw.TextStyle(fontSize: fontSize),
          ),
        ],
      ),
    );
  }

  // ==================== HELPERS ====================

  static pw.Widget _buildInfoRow(String label, String value,
      {bool isTicket = false}) {
    final fontSize = isTicket ? 7.0 : 9.0;
    final labelWidth = isTicket ? 50.0 : 70.0;
    return pw.Padding(
      padding: pw.EdgeInsets.symmetric(vertical: isTicket ? 1 : 2),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: labelWidth,
            child: pw.Text(
              '$label:',
              style: pw.TextStyle(
                fontSize: fontSize,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          pw.Expanded(
            child: pw.Text(value, style: pw.TextStyle(fontSize: fontSize)),
          ),
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

  static pw.Widget _buildTotalRow(
    String label,
    String value, {
    bool bold = false,
    double fontSize = 10,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: fontSize,
              fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: fontSize,
              fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

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

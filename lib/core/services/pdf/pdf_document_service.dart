import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../features/configuracion_documentos/domain/entities/plantilla_documento.dart';
import 'builders/pdf_footer_builder.dart';
import 'pdf_document_style.dart';

/// Orquestador que construye el `pw.Document` final.
///
/// Cada generador (cotización, compra, etc.) prepara la lista de widgets
/// del body (header + party + tabla + totales + ...) y delega aquí el
/// montaje de la página: márgenes, formato A4 vs ticket, footer multi-página.
///
/// Esta clase reemplaza el boilerplate `if (isTicket) pw.Page else pw.MultiPage`
/// que vivía duplicado en los 3 generadores.
class PdfDocumentService {
  PdfDocumentService._();

  /// Construye y serializa el PDF.
  ///
  /// - `bodyWidgets`: contenido del documento (sin footer — lo agrega el
  ///   service según el formato).
  /// - `footerText`: texto del pie. Si `style.showPiePagina` es false, no
  ///   se renderiza footer.
  /// - `showPaginacion`: solo aplica al modo A4.
  static Future<Uint8List> build({
    required PdfDocumentStyle style,
    required List<pw.Widget> bodyWidgets,
    String footerText = 'Gracias por su preferencia',
    bool showPaginacion = true,
  }) async {
    final pdf = pw.Document();
    final isTicket = style.formatoPapel.isTicket;
    final margin = pw.EdgeInsets.only(
      top: style.marginTopPt,
      bottom: style.marginBottomPt,
      left: style.marginLeftPt,
      right: style.marginRightPt,
    );

    if (isTicket) {
      final ticketWidth = style.formatoPapel == FormatoPapel.TICKET_80MM
          ? 80 * PdfPageFormat.mm
          : 58 * PdfPageFormat.mm;

      // En ticket el footer va inline al final del body porque pw.Page
      // no soporta un slot footer.
      final children = <pw.Widget>[...bodyWidgets];
      if (style.showPiePagina) {
        children.add(PdfFooterBuilder.build(
          pageNumber: 1,
          totalPages: 1,
          footerText: footerText,
          showPaginacion: false,
          isTicket: true,
        ));
      }

      pdf.addPage(pw.Page(
        pageFormat: PdfPageFormat(ticketWidth, double.infinity),
        margin: margin,
        build: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          mainAxisSize: pw.MainAxisSize.min,
          children: children,
        ),
      ));
    } else {
      pdf.addPage(pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: margin,
        build: (_) => bodyWidgets,
        footer: style.showPiePagina
            ? (ctx) => PdfFooterBuilder.build(
                  pageNumber: ctx.pageNumber,
                  totalPages: ctx.pagesCount,
                  footerText: footerText,
                  showPaginacion: showPaginacion,
                  isTicket: false,
                )
            : null,
      ));
    }

    return pdf.save();
  }
}

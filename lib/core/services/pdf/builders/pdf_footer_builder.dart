import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../utils/date_formatter.dart';

/// Footer estándar de documento PDF (cotización, compra, etc.).
///
/// Dos modos:
/// - **A4**: Row horizontal con texto pie + paginación + timestamp generado.
/// - **Ticket térmico**: Column centrado con texto pie + timestamp.
///
/// `package:pdf` re-renderiza el footer por página, por lo que `DateTime.now()`
/// se evalúa al render time (no se cacha entre páginas). Si el documento es
/// largo, los timestamps pueden diferir por segundos — esto es esperado y los
/// golden tests lo filtran via `_volatilePatterns`.
class PdfFooterBuilder {
  PdfFooterBuilder._();

  static pw.Widget build({
    required int pageNumber,
    required int totalPages,
    String footerText = 'Gracias por su preferencia',
    bool showPaginacion = true,
    bool isTicket = false,
  }) {
    final fontSize = isTicket ? 6.0 : 8.0;
    final textStyle = pw.TextStyle(fontSize: fontSize);
    final timestamp =
        'Generado: ${DateFormatter.formatDateTime(DateTime.now())}';

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
            pw.Text(footerText, style: textStyle),
            pw.SizedBox(height: 2),
            pw.Text(timestamp, style: textStyle),
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
          pw.Text(footerText, style: textStyle),
          if (showPaginacion)
            pw.Text('Pagina $pageNumber de $totalPages', style: textStyle),
          pw.Text(timestamp, style: textStyle),
        ],
      ),
    );
  }
}

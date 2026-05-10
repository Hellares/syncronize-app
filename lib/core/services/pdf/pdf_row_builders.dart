import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Helpers de filas/celdas reutilizables para los generadores de PDF.
///
/// Encapsulan helpers que estaban duplicados en `pdf_cotizacion_generator`,
/// `pdf_venta_generator` y `pdf_compra_generator`. Los defaults preservan
/// el comportamiento histórico de cada generador; donde un call-site usaba
/// valores distintos, se exponen como named params override.
class PdfRowBuilders {
  PdfRowBuilders._();

  /// Fila etiqueta/valor para sección de totales.
  ///
  /// - Cotización y compra: defaults (`fontSize: 10`, `vertical: 2` padding,
  ///   `bold: false`).
  /// - Venta: pasa `padding: EdgeInsets.only(bottom: 1)` y `color`.
  static pw.Widget totalRow({
    required String label,
    required String value,
    bool bold = false,
    double fontSize = 10,
    PdfColor? color,
    pw.EdgeInsets padding = const pw.EdgeInsets.symmetric(vertical: 2),
  }) {
    final style = pw.TextStyle(
      fontSize: fontSize,
      fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
      color: color,
    );
    return pw.Padding(
      padding: padding,
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: style),
          pw.Text(value, style: style),
        ],
      ),
    );
  }

  /// Fila label/valor para datos del cliente/proveedor (formato `Label: Value`).
  ///
  /// - Cotización usa labelWidth 50/70 (default).
  /// - Compra usa labelWidth 55/80 → override `labelWidth`.
  static pw.Widget infoRow({
    required String label,
    required String value,
    bool isTicket = false,
    double? labelWidth,
    double? fontSize,
  }) {
    final fs = fontSize ?? (isTicket ? 7.0 : 9.0);
    final lw = labelWidth ?? (isTicket ? 50.0 : 70.0);
    return pw.Padding(
      padding: pw.EdgeInsets.symmetric(vertical: isTicket ? 1 : 2),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: lw,
            child: pw.Text(
              '$label:',
              style: pw.TextStyle(
                fontSize: fs,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          pw.Expanded(
            child: pw.Text(value, style: pw.TextStyle(fontSize: fs)),
          ),
        ],
      ),
    );
  }

  /// Celda de tabla con padding + alineación + color opcional.
  ///
  /// Idéntico en cotización y compra; venta no la usa.
  static pw.Widget tableCell(
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
}

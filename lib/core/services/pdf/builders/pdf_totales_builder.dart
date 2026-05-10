import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../pdf_row_builders.dart';

/// Sección de totales unificada (cotización + compra).
///
/// Genera una caja con borde gris que contiene:
/// - Subtotal
/// - Descuento (si > 0)
/// - Impuesto (IGV / configurable)
/// - Divider
/// - TOTAL en negrita y fuente grande
///
/// Modos:
/// - **A4**: caja de ancho fijo (220pt) alineada a la derecha.
/// - **Ticket**: caja de ancho completo, sin alineación.
///
/// `hideBreakdown` (cotización: `modoCliente=true`) oculta subtotal/descuento/
/// impuesto y muestra solo el TOTAL.
class PdfTotalesBuilder {
  PdfTotalesBuilder._();

  static pw.Widget simple({
    required String moneda,
    required double subtotal,
    required double descuento,
    required double impuestos,
    required double total,
    String nombreImpuesto = 'IGV',
    double porcentajeImpuesto = 18.0,
    bool isTicket = false,
    bool hideBreakdown = false,
  }) {
    final totalFontSize = isTicket ? 9.0 : 13.0;
    final rowFontSize = isTicket ? 7.0 : 10.0;
    final containerPadding = isTicket ? 6.0 : 12.0;

    String fmt(double v) => v.toStringAsFixed(2);

    final box = pw.Container(
      width: isTicket ? double.infinity : 220,
      padding: pw.EdgeInsets.all(containerPadding),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Column(
        children: [
          if (!hideBreakdown) ...[
            PdfRowBuilders.totalRow(
              label: 'Subtotal',
              value: '$moneda ${fmt(subtotal)}',
              fontSize: rowFontSize,
            ),
            if (descuento > 0)
              PdfRowBuilders.totalRow(
                label: 'Descuento',
                value: '- $moneda ${fmt(descuento)}',
                fontSize: rowFontSize,
              ),
            PdfRowBuilders.totalRow(
              label:
                  '$nombreImpuesto (${porcentajeImpuesto.toStringAsFixed(0)}%)',
              value: '$moneda ${fmt(impuestos)}',
              fontSize: rowFontSize,
            ),
            pw.Divider(color: PdfColors.grey400),
            pw.SizedBox(height: isTicket ? 2 : 4),
          ],
          PdfRowBuilders.totalRow(
            label: 'TOTAL',
            value: '$moneda ${fmt(total)}',
            bold: true,
            fontSize: totalFontSize,
          ),
        ],
      ),
    );

    if (isTicket) return box;
    // A4: alinea a la derecha con expanded
    return pw.Row(
      children: [pw.Expanded(child: pw.SizedBox()), box],
    );
  }
}

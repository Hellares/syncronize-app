import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../pdf_row_builders.dart';

/// Campo simple `Label: Value` para construir el bloque de cliente/proveedor.
class PdfPartyField {
  final String label;
  final String value;
  const PdfPartyField(this.label, this.value);
}

/// Bloque de "DATOS DEL CLIENTE" / "DATOS DEL PROVEEDOR" (o cualquier party
/// del documento).
///
/// Genera un container con borde gris que contiene:
/// 1. Título en mayúsculas con color primario.
/// 2. Divider.
/// 3. Lista de fields:
///    - **Ticket**: una columna apilada.
///    - **A4**: dos columnas (split a la mitad).
///
/// Cada caller pasa los `fields` ya filtrados (sin nulls) en el orden que
/// quiera. El builder no decide qué fields mostrar.
///
/// Si se necesita un header adicional sobre el bloque (ej. "nombre de la
/// cotización" como banner), se pasa como `headerBlock`.
class PdfPartyBuilder {
  PdfPartyBuilder._();

  static pw.Widget build({
    required String title,
    required List<PdfPartyField> fields,
    required PdfColor primaryColor,
    bool isTicket = false,
    pw.Widget? headerBlock,
    /// Override labelWidth de los infoRow (cotización usa 50/70,
    /// compra usa 55/80).
    double? infoRowLabelWidth,
  }) {
    final labelSize = isTicket ? 8.0 : 10.0;
    final padding = isTicket ? 8.0 : 15.0;
    final widgets =
        fields.map((f) => PdfRowBuilders.infoRow(
              label: f.label,
              value: f.value,
              isTicket: isTicket,
              labelWidth: infoRowLabelWidth,
            )).toList();

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        if (headerBlock != null) ...[
          headerBlock,
          pw.SizedBox(height: isTicket ? 6 : 12),
        ],
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
                title,
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
                  children: widgets,
                )
              else
                _twoColumnSplit(widgets),
            ],
          ),
        ),
      ],
    );
  }

  /// Distribuye los widgets en dos columnas (mitad / mitad).
  static pw.Widget _twoColumnSplit(List<pw.Widget> widgets) {
    final mid = (widgets.length / 2).ceil();
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: widgets.take(mid).toList(),
          ),
        ),
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: widgets.skip(mid).toList(),
          ),
        ),
      ],
    );
  }

  /// Helper para construir el banner opcional con el "nombre" del documento
  /// (usado por cotización cuando `cotizacion.nombre` está set).
  static pw.Widget banner({
    required String text,
    required PdfColor primaryColor,
    bool isTicket = false,
  }) {
    final lightBg = PdfColor(
      primaryColor.red,
      primaryColor.green,
      primaryColor.blue,
      0.08,
    );
    final titleSize = isTicket ? 9.0 : 13.0;
    return pw.Container(
      width: double.infinity,
      padding: pw.EdgeInsets.symmetric(
        horizontal: isTicket ? 6 : 12,
        vertical: isTicket ? 4 : 8,
      ),
      decoration: pw.BoxDecoration(
        color: lightBg,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: titleSize,
          fontWeight: pw.FontWeight.bold,
          color: primaryColor,
        ),
      ),
    );
  }
}

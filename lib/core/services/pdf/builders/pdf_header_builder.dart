import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Header de documento PDF (cotización, compra, etc.).
///
/// Estructura:
/// - **Izquierda** (`empresaInfo`): logo (si hay) o nombre empresa, +
///   datos opcionales (sede, RUC, dirección, teléfono).
/// - **Derecha** (`documentInfo`): caja con borde primario que contiene
///   tipo de documento ("COTIZACION", "COMPRA", etc.), código, y una
///   lista flexible de líneas (`documentLines`) que cada generador
///   compone según su entidad (fecha, vencimiento, estado, moneda).
///
/// Layout:
/// - **Ticket**: Column stack vertical, todo centrado y ancho completo.
/// - **A4**: Row split, empresaInfo expandido, documentInfo a la derecha.
class PdfHeaderBuilder {
  PdfHeaderBuilder._();

  static pw.Widget build({
    required String empresaNombre,
    String? empresaRuc,
    String? empresaDireccion,
    String? empresaTelefono,
    String? sedeNombre,
    Uint8List? logo,
    required String tipoDocumento,
    required String codigo,
    required List<String> documentLines,
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

    // Renderiza las líneas adicionales del documento con SizedBox entre
    // ellas (replicando el patrón histórico de cada generador).
    final documentLineWidgets = <pw.Widget>[];
    for (var i = 0; i < documentLines.length; i++) {
      documentLineWidgets.add(pw.SizedBox(height: isTicket ? 2 : 4));
      documentLineWidgets.add(pw.Text(
        documentLines[i],
        style: pw.TextStyle(fontSize: detailFontSize),
      ));
    }

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
            tipoDocumento,
            style: pw.TextStyle(
              fontSize: titleFontSize,
              fontWeight: pw.FontWeight.bold,
              color: primaryColor,
            ),
          ),
          pw.SizedBox(height: isTicket ? 3 : 6),
          pw.Text(
            codigo,
            style: pw.TextStyle(
              fontSize: codeFontSize,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          ...documentLineWidgets,
        ],
      ),
    );

    if (isTicket) {
      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          empresaInfo,
          pw.SizedBox(height: 6),
          documentInfo,
        ],
      );
    }

    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(child: empresaInfo),
        documentInfo,
      ],
    );
  }
}

import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../herramientas/presentation/services/calculo_mostrador_esc_pos_generator.dart';

/// Un ticket físico para el ÁNFORA: número + nombre del participante.
class DatosTicketAnfora {
  final int numero;
  final String nombre;
  final String? dni;

  const DatosTicketAnfora({
    required this.numero,
    required this.nombre,
    this.dni,
  });
}

/// Tickets del sorteo para IMPRIMIR y recortar (ánfora física): grilla
/// A4 de 2 columnas × 5 filas (10 por hoja) con líneas de corte. Cada
/// ticket lleva el título del sorteo, su NÚMERO y el nombre + DNI del
/// participante — quien compró 20 sale 20 veces.
class TicketsAnforaPdfGenerator {
  static const _porFila = 2;
  static const _filasPorPagina = 5;
  static const _porPagina = _porFila * _filasPorPagina;

  static Future<Uint8List> generate({
    required String sorteoTitulo,
    required String empresaNombre,
    required List<DatosTicketAnfora> tickets,
  }) async {
    final doc = pw.Document();
    final sanitize = CalculoMostradorEscPosGenerator.sanitize;

    for (var i = 0; i < tickets.length; i += _porPagina) {
      final pagina = tickets.skip(i).take(_porPagina).toList();
      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(16),
          build: (_) => pw.Column(
            children: [
              for (var f = 0; f < _filasPorPagina; f++)
                pw.Expanded(
                  child: pw.Row(
                    children: [
                      for (var c = 0; c < _porFila; c++)
                        pw.Expanded(
                          child: f * _porFila + c < pagina.length
                              ? _ticket(
                                  pagina[f * _porFila + c],
                                  sorteoTitulo,
                                  empresaNombre,
                                  sanitize,
                                )
                              : pw.SizedBox(),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      );
    }
    return doc.save();
  }

  static pw.Widget _ticket(
    DatosTicketAnfora t,
    String sorteoTitulo,
    String empresaNombre,
    String Function(String) sanitize,
  ) {
    return pw.Container(
      margin: const pw.EdgeInsets.all(4),
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(width: 1, color: PdfColors.grey700),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Column(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.Text(
            sanitize(sorteoTitulo.toUpperCase()),
            textAlign: pw.TextAlign.center,
            maxLines: 1,
            style: pw.TextStyle(
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey700,
            ),
          ),
          pw.Text(
            'TICKET #${t.numero}',
            textAlign: pw.TextAlign.center,
            style: pw.TextStyle(
              fontSize: 20,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.Column(
            children: [
              pw.Text(
                sanitize(t.nombre.toUpperCase()),
                textAlign: pw.TextAlign.center,
                maxLines: 2,
                style: pw.TextStyle(
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              if (t.dni != null && t.dni!.isNotEmpty)
                pw.Text(
                  'DNI ${t.dni}',
                  textAlign: pw.TextAlign.center,
                  style: const pw.TextStyle(
                      fontSize: 8, color: PdfColors.grey700),
                ),
            ],
          ),
          pw.Text(
            sanitize(empresaNombre),
            textAlign: pw.TextAlign.center,
            maxLines: 1,
            style:
                const pw.TextStyle(fontSize: 7, color: PdfColors.grey600),
          ),
        ],
      ),
    );
  }
}

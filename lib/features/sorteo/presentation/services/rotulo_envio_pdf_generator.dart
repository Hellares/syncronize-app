import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../herramientas/presentation/services/calculo_mostrador_esc_pos_generator.dart';
import '../../domain/entities/sorteo.dart';

/// Rótulo de envío del premio para impresora NORMAL (A4): cada rótulo
/// ocupa EXACTAMENTE media hoja (con línea de corte al centro) — se
/// imprimen 2 por hoja o se recorta. Datos: DNI, nombres, celular,
/// agencia y dirección de la agencia (+ destino y remitente).
class RotuloEnvioPdfGenerator {
  static Future<Uint8List> generate({
    required List<SorteoPremio> premios,
    required String remitenteNombre,
    String? remitenteTelefono,
    /// Logo de la empresa — se estampa como MARCA DE AGUA translúcida
    /// al centro de cada rótulo (branding sin robar legibilidad).
    Uint8List? logoBytes,
  }) async {
    final doc = pw.Document();
    final sanitize = CalculoMostradorEscPosGenerator.sanitize;
    pw.MemoryImage? logo;
    if (logoBytes != null && logoBytes.isNotEmpty) {
      try {
        logo = pw.MemoryImage(logoBytes);
      } catch (_) {
        // Logo corrupto/formato no soportado → rótulo sin marca de agua.
      }
    }

    // De a 2 por página A4 (mitad superior e inferior).
    for (var i = 0; i < premios.length; i += 2) {
      final par = premios.skip(i).take(2).toList();
      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.zero,
          build: (_) => pw.Column(
            children: [
              pw.Expanded(
                child: _rotulo(par[0], remitenteNombre, remitenteTelefono,
                    sanitize, logo),
              ),
              _lineaCorte(),
              pw.Expanded(
                child: par.length > 1
                    ? _rotulo(par[1], remitenteNombre, remitenteTelefono,
                        sanitize, logo)
                    : pw.SizedBox(),
              ),
            ],
          ),
        ),
      );
    }
    return doc.save();
  }

  static pw.Widget _lineaCorte() {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 10),
      child: pw.Row(
        children: [
          pw.Text('8<', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500)),
          pw.SizedBox(width: 4),
          pw.Expanded(
            child: pw.Text(
              '- ' * 120,
              maxLines: 1,
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _rotulo(
    SorteoPremio p,
    String remitenteNombre,
    String? remitenteTelefono,
    String Function(String) sanitize,
    pw.MemoryImage? logo,
  ) {
    return pw.Padding(
      padding: const pw.EdgeInsets.fromLTRB(36, 28, 36, 22),
      // El marco lo dibuja el contenido (un solo encuadre uniforme).
      child: pw.Container(
        child: pw.Stack(
          children: [
            // Marca de agua: logo de la empresa translúcido al centro.
            if (logo != null)
              pw.Positioned.fill(
                child: pw.Center(
                  child: pw.Opacity(
                    opacity: 0.07,
                    child: pw.Image(
                      logo,
                      width: 230,
                      height: 150,
                      fit: pw.BoxFit.contain,
                    ),
                  ),
                ),
              ),
            // Positioned.fill: la tabla interna usa Expanded y necesita
            // la altura completa del rótulo (no la intrínseca del Stack).
            pw.Positioned.fill(
              child: _contenidoRotulo(
                  p, remitenteNombre, remitenteTelefono, sanitize),
            ),
          ],
        ),
      ),
    );
  }

  static pw.Widget _contenidoRotulo(
    SorteoPremio p,
    String remitenteNombre,
    String? remitenteTelefono,
    String Function(String) sanitize,
  ) {
    const borde = pw.BorderSide(color: PdfColors.grey700, width: 0.7);

    // Fila de la tabla: etiqueta (ancho fijo, SIN fondo — el logo de
    // marca de agua debe verse a través de todo) + valor grande. Cada
    // fila se ESTIRA para repartirse el alto disponible.
    pw.Widget fila(String etiqueta, String? valor,
        {double fontSize = 16, bool ultimaFila = false}) {
      return pw.Expanded(
        child: pw.Container(
          decoration: pw.BoxDecoration(
            border: pw.Border(bottom: ultimaFila ? pw.BorderSide.none : borde),
          ),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              pw.Container(
                width: 128,
                padding: const pw.EdgeInsets.symmetric(horizontal: 8),
                alignment: pw.Alignment.centerLeft,
                decoration: const pw.BoxDecoration(
                  border: pw.Border(right: borde),
                ),
                child: pw.Text(
                  etiqueta,
                  style: pw.TextStyle(
                    fontSize: 13,
                    fontWeight: pw.FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              pw.Expanded(
                child: pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 10),
                  alignment: pw.Alignment.centerLeft,
                  child: pw.Text(
                    valor != null && valor.isNotEmpty ? sanitize(valor) : '-',
                    maxLines: 2,
                    style: pw.TextStyle(
                      fontSize: fontSize,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Rótulo completo dentro de UN solo marco: cabecera, tabla y pie de
    // remitente encuadrados, celdas transparentes (resalta el logo).
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey700, width: 1),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Cabecera (dentro del marco): título + agencia protagonista.
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: const pw.BoxDecoration(
              border: pw.Border(bottom: borde),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Text(
                  'ROTULO DE ENVIO',
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.grey700,
                    letterSpacing: 1.2,
                  ),
                ),
                if (p.agenciaNombre != null && p.agenciaNombre!.isNotEmpty)
                  pw.Text(
                    sanitize(p.agenciaNombre!.toUpperCase()),
                    style: pw.TextStyle(
                        fontSize: 16, fontWeight: pw.FontWeight.bold),
                  ),
              ],
            ),
          ),

          // Tabla: llena todo el alto entre cabecera y pie.
          pw.Expanded(
            child: pw.Column(
              children: [
                fila('DESTINATARIO', p.ganadorNombre.toUpperCase(),
                    fontSize: 17),
                fila('DNI', p.ganadorDni),
                fila('CELULAR', p.ganadorCelular),
                fila('DESTINO', p.destinoTexto?.toUpperCase()),
                fila(
                  'AGENCIA',
                  [
                    if (p.agenciaNombre != null &&
                        p.agenciaNombre!.isNotEmpty)
                      p.agenciaNombre!.toUpperCase(),
                    if (p.agenciaDireccion != null &&
                        p.agenciaDireccion!.isNotEmpty)
                      p.agenciaDireccion!,
                  ].join(' - '),
                  fontSize: 13,
                  ultimaFila: true,
                ),
              ],
            ),
          ),

          // Pie de remitente (dentro del marco).
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: const pw.BoxDecoration(
              border: pw.Border(top: borde),
            ),
            child: pw.Text(
              sanitize(
                'REMITENTE: ${remitenteNombre.toUpperCase()}'
                '${remitenteTelefono != null && remitenteTelefono.isNotEmpty ? '  ·  TEL: $remitenteTelefono' : ''}',
              ),
              style:
                  const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
            ),
          ),
        ],
      ),
    );
  }
}

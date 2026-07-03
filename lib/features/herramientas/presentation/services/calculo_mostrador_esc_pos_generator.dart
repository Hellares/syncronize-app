import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';

import '../../../venta/domain/entities/venta_detalle_input.dart';

/// Bytes ESC-POS de la "lista calculada" de la calculadora de mostrador.
/// NO es un comprobante: es una cotización informal de precios que el
/// vendedor le entrega al cliente (sin correlativo, sin stock, sin IGV
/// desglosado — los precios ya son finales de vitrina).
class CalculoMostradorEscPosGenerator {
  /// La impresora codifica latin1: caracteres unicode fuera de ese rango
  /// (— – ’ “ ” … etc., típicos en nombres de variante) hacen tirar al
  /// encoder con "contains invalid character". Se mapean a su equivalente
  /// ASCII y cualquier otro fuera de latin1 se descarta.
  static String _sanitize(String s) {
    const mapa = {
      '—': '-', '–': '-', '−': '-',
      '’': "'", '‘': "'",
      '“': '"', '”': '"',
      '…': '...',
      ' ': ' ',
      '→': '>', '•': '-', '·': '-',
    };
    final sb = StringBuffer();
    for (final ch in s.split('')) {
      if (mapa.containsKey(ch)) {
        sb.write(mapa[ch]);
      } else if (ch.codeUnitAt(0) <= 0xFF) {
        sb.write(ch);
      }
      // Fuera de latin1 y sin mapeo → se omite.
    }
    return sb.toString();
  }

  static Future<List<int>> generate({
    required List<VentaDetalleInput> items,
    String? sedeNombre,
    int paperWidth = 80,
  }) async {
    final profile = await CapabilityProfile.load();
    final paperSize = paperWidth == 58 ? PaperSize.mm58 : PaperSize.mm80;
    final generator = Generator(paperSize, profile);
    final chars = paperWidth == 58 ? 42 : 64;
    List<int> bytes = [];

    bytes += generator.reset();
    bytes += generator.setStyles(const PosStyles(fontType: PosFontType.fontB));

    // Título único (sin nombre de empresa; sin size2 — el doble alto de
    // fontB se ve pixeleado en térmicas).
    bytes += generator.text(
      'COTIZACION DE PRECIOS',
      styles: const PosStyles(
        align: PosAlign.center,
        bold: true,
        fontType: PosFontType.fontB,
      ),
    );
    if (sedeNombre != null && sedeNombre.isNotEmpty) {
      bytes += generator.text(
        _sanitize(sedeNombre),
        styles: const PosStyles(
            align: PosAlign.center, fontType: PosFontType.fontB),
      );
    }
    final now = DateTime.now();
    final fecha =
        '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year} '
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    bytes += generator.text(
      fecha,
      styles:
          const PosStyles(align: PosAlign.center, fontType: PosFontType.fontB),
    );
    bytes += generator.text('-' * chars,
        styles: const PosStyles(fontType: PosFontType.fontB));

    // ── Tabla: PRODUCTO | CANT | PRECIO | TOTAL ──
    // Anchos fijos por caracteres (fontB): numéricos a la derecha.
    const wCant = 5;
    const wPrecio = 8;
    const wTotal = 9;
    final wNombre = chars - wCant - wPrecio - wTotal;

    /// Corta [texto] en el último espacio que quepa en [ancho] (o corte
    /// duro si es una sola palabra). Devuelve (línea, resto).
    (String, String) cortar(String texto, int ancho) {
      if (texto.length <= ancho) return (texto, '');
      var corte = texto.lastIndexOf(' ', ancho);
      if (corte <= 0) corte = ancho;
      return (texto.substring(0, corte).trimRight(),
          texto.substring(corte).trimLeft());
    }

    /// Fila de la tabla: nombres largos se envuelven en líneas adicionales
    /// (ancho completo, con sangría) para que se lean COMPLETOS.
    List<String> fila(String nombre, String cant, String precio, String tot) {
      final (linea1, restoInicial) = cortar(nombre, wNombre);
      final lineas = [
        '${linea1.padRight(wNombre)}${cant.padLeft(wCant)}'
            '${precio.padLeft(wPrecio)}${tot.padLeft(wTotal)}',
      ];
      var resto = restoInicial;
      while (resto.isNotEmpty) {
        final (linea, siguiente) = cortar(resto, chars - 2);
        lineas.add('  $linea');
        resto = siguiente;
      }
      return lineas;
    }

    bytes += generator.text(
      fila('PRODUCTO', 'CANT', 'PRECIO', 'TOTAL').first,
      styles: const PosStyles(bold: true, fontType: PosFontType.fontB),
    );
    bytes += generator.text('-' * chars,
        styles: const PosStyles(fontType: PosFontType.fontB));

    var i = 0;
    double total = 0;
    for (final item in items) {
      i++;
      total += item.total;
      final cant = item.cantidad % 1 == 0
          ? item.cantidad.toStringAsFixed(0)
          : item.cantidad.toStringAsFixed(2);
      for (final linea in fila(
        _sanitize('$i.${item.descripcion}'),
        cant,
        item.precioUnitario.toStringAsFixed(2),
        item.total.toStringAsFixed(2),
      )) {
        bytes += generator.text(
          linea,
          styles: const PosStyles(fontType: PosFontType.fontB),
        );
      }
      // Etiqueta de precio especial como sub-línea (solo si aplica).
      final etiquetas = <String>[
        if (item.enLiquidacion) 'LIQUIDACION',
        if (item.enOferta == true) 'OFERTA',
        if (item.nivelAplicado != null) 'X MAYOR',
      ];
      if (etiquetas.isNotEmpty) {
        bytes += generator.text(
          '  (${etiquetas.join('/')})',
          styles: const PosStyles(fontType: PosFontType.fontB),
        );
      }
    }

    bytes += generator.text('-' * chars,
        styles: const PosStyles(fontType: PosFontType.fontB));
    bytes += generator.row([
      PosColumn(
        text: 'TOTAL',
        width: 6,
        styles: const PosStyles(bold: true, fontType: PosFontType.fontB),
      ),
      PosColumn(
        text: 'S/ ${total.toStringAsFixed(2)}',
        width: 6,
        styles: const PosStyles(
          align: PosAlign.right,
          bold: true,
          fontType: PosFontType.fontB,
        ),
      ),
    ]);
    bytes += generator.feed(1);
    bytes += generator.text(
      'Precios referenciales del dia.',
      styles:
          const PosStyles(align: PosAlign.center, fontType: PosFontType.fontB),
    );
    bytes += generator.text(
      'NO es comprobante de pago.',
      styles:
          const PosStyles(align: PosAlign.center, fontType: PosFontType.fontB),
    );
    bytes += generator.feed(2);
    bytes += generator.cut();
    return bytes;
  }
}

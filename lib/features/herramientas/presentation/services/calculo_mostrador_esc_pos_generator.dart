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
  /// ASCII y cualquier otro fuera de latin1 se descarta. Público: el PDF
  /// de la calculadora lo reutiliza (la Helvetica embebida tampoco tiene
  /// esos glifos — se ven como ▯).
  static String sanitize(String s) {
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

  /// Envuelve [texto] por palabra en líneas de máximo [ancho] chars.
  static List<String> _envolver(String texto, int ancho) {
    final lineas = <String>[];
    var resto = texto.trim();
    while (resto.length > ancho) {
      var corte = resto.lastIndexOf(' ', ancho);
      if (corte <= 0) corte = ancho;
      lineas.add(resto.substring(0, corte).trimRight());
      resto = resto.substring(corte).trimLeft();
    }
    if (resto.isNotEmpty) lineas.add(resto);
    return lineas;
  }

  static Future<List<int>> generate({
    required List<VentaDetalleInput> items,
    String? sedeNombre,
    int paperWidth = 80,
    /// false = lista "muda": solo producto + cantidad y el TOTAL general
    /// al pie (sin precios por item) — para entregar como lista de compra.
    /// true = lista completa con precio/total POR ITEM pero SIN el total
    /// general (pedido del user: la cotización detalla, no cierra venta).
    bool conPrecios = true,
    /// true (solo junto a [conPrecios]): imprime bajo cada item sus
    /// niveles por mayor — el mismo texto de los chips de la UI
    /// ("3+ S/39.90"). Para entregar al cliente mayorista.
    bool conNiveles = false,
    /// Encabezado: nombre comercial + teléfono de la empresa (config
    /// efectiva sede > empresa, mismo origen que el ticket de venta).
    String? empresaNombre,
    String? empresaTelefono,
    /// Dirección de la sede — se imprime "SEDE: dirección" centrado.
    String? sedeDireccion,
  }) async {
    final profile = await CapabilityProfile.load();
    final paperSize = paperWidth == 58 ? PaperSize.mm58 : PaperSize.mm80;
    final generator = Generator(paperSize, profile);
    final chars = paperWidth == 58 ? 42 : 64;
    List<int> bytes = [];

    bytes += generator.reset();
    bytes += generator.setStyles(const PosStyles(fontType: PosFontType.fontB));

    // Encabezado en fontA (la estándar) SIN bold: en térmicas baratas
    // cualquier engrosado (bold o size2, en fontA o fontB) se rasteriza
    // pixeleado — la jerarquía la da el tamaño natural de fontA en
    // MAYÚSCULAS, no el peso.
    if (empresaNombre != null && empresaNombre.isNotEmpty) {
      bytes += generator.text(
        sanitize(empresaNombre.toUpperCase()),
        styles: const PosStyles(
          align: PosAlign.center,
          fontType: PosFontType.fontA,
        ),
      );
    }
    if (empresaTelefono != null && empresaTelefono.isNotEmpty) {
      bytes += generator.text(
        sanitize('Tel. $empresaTelefono'),
        styles: const PosStyles(
            align: PosAlign.center, fontType: PosFontType.fontB),
      );
    }
    if (sedeNombre != null && sedeNombre.isNotEmpty) {
      // "SEDE PRINCIPAL: Trujillo, ..." — direcciones largas se envuelven
      // por palabra para que cada línea salga centrada (el wrap del
      // hardware no centra la continuación).
      final textoSede = sanitize(
        (sedeDireccion != null && sedeDireccion.isNotEmpty)
            ? '${sedeNombre.toUpperCase()}: $sedeDireccion'
            : sedeNombre,
      );
      for (final linea in _envolver(textoSede, chars)) {
        bytes += generator.text(
          linea,
          styles: const PosStyles(
              align: PosAlign.center, fontType: PosFontType.fontB),
        );
      }
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
    // Título discreto FUERA del bloque de encabezados, encima de la línea
    // punteada (pedido user). fontB es la letra más chica que ofrece el
    // hardware ESC-POS (no hay tamaños en px).
    bytes += generator.text(
      'COTIZACION DE PRECIOS',
      styles: const PosStyles(fontType: PosFontType.fontB),
    );
    // Pegar las punteadas a la cabecera de tabla AL MÁXIMO: ESC 3 n fija
    // el avance de línea en n dots y fontB mide exactamente 17 de alto →
    // 17 = 0px de aire (las líneas quedan al ras del texto; menos de 17
    // se comería píxeles de los caracteres). Se restaura con ESC 2 tras
    // la fila PRODUCTO para que el resto del ticket respire normal.
    bytes += generator.rawBytes([0x1B, 0x33, 17]);
    bytes += generator.text('-' * chars,
        styles: const PosStyles(fontType: PosFontType.fontB));

    // ── Tabla: PRODUCTO | CANT | PRECIO | TOTAL ──
    // Anchos fijos por caracteres (fontB): numéricos a la derecha.
    const wCant = 5;
    final wPrecio = conPrecios ? 8 : 0;
    final wTotal = conPrecios ? 9 : 0;
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
      final numeros = conPrecios
          ? '${cant.padLeft(wCant)}${precio.padLeft(wPrecio)}${tot.padLeft(wTotal)}'
          : cant.padLeft(wCant);
      final lineas = ['${linea1.padRight(wNombre)}$numeros'];
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
      styles: const PosStyles(fontType: PosFontType.fontB),
    );
    // Interlineado default de vuelta (la punteada de abajo ya quedó
    // pegada por el avance corto de la fila PRODUCTO).
    bytes += generator.rawBytes([0x1B, 0x32]);
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
        sanitize('$i.${item.descripcion}'),
        cant,
        item.precioUnitario.toStringAsFixed(2),
        item.total.toStringAsFixed(2),
      )) {
        bytes += generator.text(
          linea,
          styles: const PosStyles(fontType: PosFontType.fontB),
        );
      }
      // Etiqueta de precio especial como sub-línea (solo en el modo con
      // precios — la lista muda no revela nada de pricing).
      final etiquetas = <String>[
        if (item.enLiquidacion) 'LIQUIDACION',
        if (item.enOferta == true) 'OFERTA',
        if (item.nivelAplicado != null) 'X MAYOR',
      ];
      if (conPrecios && etiquetas.isNotEmpty) {
        bytes += generator.text(
          '  (${etiquetas.join('/')})',
          styles: const PosStyles(fontType: PosFontType.fontB),
        );
      }
      // Niveles por mayor como sub-línea (mismo cálculo que los chips de
      // la UI: precio fijo del nivel o % sobre el precio base).
      if (conPrecios && conNiveles && item.niveles.isNotEmpty) {
        final base = item.precioBase ?? item.precioUnitario;
        final partes = item.niveles.take(3).map((n) {
          final p = n.precio ?? base * (1 - (n.porcentajeDesc ?? 0) / 100);
          return '${n.cantidadMinima}+ S/${p.toStringAsFixed(2)}';
        }).join(', ');
        bytes += generator.text(
          sanitize('  Por mayor: $partes'),
          styles: const PosStyles(fontType: PosFontType.fontB),
        );
      }
    }

    bytes += generator.text('-' * chars,
        styles: const PosStyles(fontType: PosFontType.fontB));
    // TOTAL general solo en la lista "muda" (su razón de ser es entregar
    // productos + total). En la lista completa cada item ya muestra su
    // total y el user pidió NO cerrar la suma en la cotización.
    if (!conPrecios) {
      bytes += generator.row([
        PosColumn(
          text: 'TOTAL',
          width: 6,
          styles: const PosStyles(fontType: PosFontType.fontB),
        ),
        PosColumn(
          text: 'S/ ${total.toStringAsFixed(2)}',
          width: 6,
          styles: const PosStyles(
            align: PosAlign.right,
            fontType: PosFontType.fontB,
          ),
        ),
      ]);
    }
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

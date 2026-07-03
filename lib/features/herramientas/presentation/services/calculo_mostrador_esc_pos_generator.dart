import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';

import '../../../venta/domain/entities/venta_detalle_input.dart';

/// Bytes ESC-POS de la "lista calculada" de la calculadora de mostrador.
/// NO es un comprobante: es una cotización informal de precios que el
/// vendedor le entrega al cliente (sin correlativo, sin stock, sin IGV
/// desglosado — los precios ya son finales de vitrina).
class CalculoMostradorEscPosGenerator {
  static Future<List<int>> generate({
    required List<VentaDetalleInput> items,
    required String empresaNombre,
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

    if (empresaNombre.isNotEmpty) {
      bytes += generator.text(
        empresaNombre.toUpperCase(),
        styles: const PosStyles(
          align: PosAlign.center,
          bold: true,
          height: PosTextSize.size2,
          fontType: PosFontType.fontB,
        ),
      );
    }
    if (sedeNombre != null && sedeNombre.isNotEmpty) {
      bytes += generator.text(
        sedeNombre,
        styles: const PosStyles(
            align: PosAlign.center, fontType: PosFontType.fontB),
      );
    }
    bytes += generator.feed(1);
    bytes += generator.text(
      'COTIZACION DE PRECIOS',
      styles: const PosStyles(
        align: PosAlign.center,
        bold: true,
        fontType: PosFontType.fontB,
      ),
    );
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

    // ── Items: "cant x descripcion" + precio unit y total a la derecha ──
    var i = 0;
    double total = 0;
    for (final item in items) {
      i++;
      total += item.total;
      final cant = item.cantidad % 1 == 0
          ? item.cantidad.toStringAsFixed(0)
          : item.cantidad.toStringAsFixed(2);
      bytes += generator.text(
        '$i. ${item.descripcion}',
        styles: const PosStyles(bold: true, fontType: PosFontType.fontB),
      );
      // Sub-línea: cantidad x precio (con etiqueta si es precio especial)
      final etiquetas = <String>[
        if (item.enLiquidacion) 'LIQUIDACION',
        if (item.enOferta == true) 'OFERTA',
        if (item.nivelAplicado != null) 'X MAYOR',
      ];
      final izq =
          '   $cant x S/ ${item.precioUnitario.toStringAsFixed(2)}${etiquetas.isNotEmpty ? ' (${etiquetas.join('/')})' : ''}';
      final der = 'S/ ${item.total.toStringAsFixed(2)}';
      final espacio = chars - izq.length - der.length;
      bytes += generator.text(
        espacio > 0 ? '$izq${' ' * espacio}$der' : '$izq $der',
        styles: const PosStyles(fontType: PosFontType.fontB),
      );
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
          height: PosTextSize.size2,
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

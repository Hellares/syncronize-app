import 'dart:typed_data';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../domain/entities/venta.dart';

class TicketVentaEscPosGenerator {
  static Future<List<int>> generate({
    required Venta venta,
    required String empresaNombre,
    String? empresaRuc,
    String? empresaDireccion,
    String? empresaTelefono,
    Uint8List? logoEmpresa,
    int paperWidth = 80,
    String nombreImpuesto = 'IGV',
  }) async {
    final profile = await CapabilityProfile.load();
    final paperSize = paperWidth == 58 ? PaperSize.mm58 : PaperSize.mm80;
    final generator = Generator(paperSize, profile);
    List<int> bytes = [];

    // ── Header empresa ──
    bytes += generator.text(
      empresaNombre,
      styles: const PosStyles(
        align: PosAlign.center,
        bold: true,
        height: PosTextSize.size2,
        width: PosTextSize.size1,
      ),
    );
    if (empresaRuc != null) {
      bytes += generator.text('RUC: $empresaRuc',
          styles: const PosStyles(align: PosAlign.center));
    }
    if (empresaDireccion != null) {
      bytes += generator.text(empresaDireccion,
          styles: const PosStyles(align: PosAlign.center));
    }
    if (empresaTelefono != null) {
      bytes += generator.text('Tel: $empresaTelefono',
          styles: const PosStyles(align: PosAlign.center));
    }

    bytes += generator.hr(ch: '=');

    // ── Titulo ──
    bytes += generator.text(
      'TICKET DE VENTA',
      styles: const PosStyles(
        align: PosAlign.center,
        bold: true,
        height: PosTextSize.size2,
        width: PosTextSize.size1,
      ),
    );
    bytes += generator.text(
      venta.codigo,
      styles: const PosStyles(align: PosAlign.center, bold: true),
    );
    bytes += generator.text(
      'Fecha: ${DateFormatter.formatDate(venta.fechaVenta)}',
      styles: const PosStyles(align: PosAlign.center),
    );

    bytes += generator.hr();

    // ── Cliente ──
    bytes += generator.text('CLIENTE', styles: const PosStyles(bold: true));
    bytes += generator.text('Nombre: ${venta.nombreCliente}');
    if (venta.documentoCliente != null) {
      bytes += generator.text('Doc: ${venta.documentoCliente}');
    }

    bytes += generator.hr();

    // ── Detalle ──
    bytes += generator.text('DETALLE', styles: const PosStyles(bold: true));

    if (venta.detalles != null) {
      for (final d in venta.detalles!) {
        final qty = d.cantidad % 1 == 0
            ? d.cantidad.toInt().toString()
            : d.cantidad.toStringAsFixed(2);
        bytes += generator.row([
          PosColumn(
            text: '${qty}x ${d.descripcion}',
            width: 8,
            styles: const PosStyles(align: PosAlign.left),
          ),
          PosColumn(
            text: 'S/${d.total.toStringAsFixed(2)}',
            width: 4,
            styles: const PosStyles(align: PosAlign.right),
          ),
        ]);
      }
    }

    bytes += generator.hr();

    // ── Totales ──
    bytes += generator.row([
      PosColumn(text: 'Subtotal:', width: 8),
      PosColumn(
        text: 'S/${venta.subtotal.toStringAsFixed(2)}',
        width: 4,
        styles: const PosStyles(align: PosAlign.right),
      ),
    ]);

    if (venta.descuento > 0) {
      bytes += generator.row([
        PosColumn(text: 'Descuento:', width: 8),
        PosColumn(
          text: '-S/${venta.descuento.toStringAsFixed(2)}',
          width: 4,
          styles: const PosStyles(align: PosAlign.right),
        ),
      ]);
    }

    bytes += generator.row([
      PosColumn(text: '$nombreImpuesto:', width: 8),
      PosColumn(
        text: 'S/${venta.impuestos.toStringAsFixed(2)}',
        width: 4,
        styles: const PosStyles(align: PosAlign.right),
      ),
    ]);

    bytes += generator.hr();

    bytes += generator.row([
      PosColumn(
        text: 'TOTAL:',
        width: 8,
        styles: const PosStyles(
            bold: true, height: PosTextSize.size2, width: PosTextSize.size1),
      ),
      PosColumn(
        text: 'S/${venta.total.toStringAsFixed(2)}',
        width: 4,
        styles: const PosStyles(
          align: PosAlign.right,
          bold: true,
          height: PosTextSize.size2,
          width: PosTextSize.size1,
        ),
      ),
    ]);

    bytes += generator.hr();

    // ── Pago ──
    if (venta.metodoPagoDisplay != null) {
      bytes += generator.text('Metodo: ${venta.metodoPagoDisplay}');
    }
    if (venta.montoRecibido != null) {
      bytes += generator.text(
          'Recibido: S/${venta.montoRecibido!.toStringAsFixed(2)}');
    }
    if (venta.montoCambio != null && venta.montoCambio! > 0) {
      bytes += generator.text(
          'Cambio: S/${venta.montoCambio!.toStringAsFixed(2)}');
    }

    bytes += generator.hr();

    // ── Footer ──
    bytes += generator.text(
      'Gracias por su compra!',
      styles: const PosStyles(align: PosAlign.center, bold: true),
    );

    bytes += generator.feed(3);
    bytes += generator.cut();

    return bytes;
  }
}

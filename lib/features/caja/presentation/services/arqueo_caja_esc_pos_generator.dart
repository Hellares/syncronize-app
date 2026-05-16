import 'dart:typed_data';

import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:image/image.dart' as img;

import '../../../../core/utils/date_formatter.dart';
import '../../domain/entities/arqueo_caja.dart';
import '../../domain/entities/caja.dart';

/// Genera bytes ESC-POS del comprobante de arqueo. Mismo estilo que
/// cierre pero con titulo "ARQUEO DE CAJA" + tipo (RUTINARIO/SORPRESIVO/RELEVO).
class ArqueoCajaEscPosGenerator {
  static Future<List<int>> generate({
    required Caja caja,
    required ArqueoCaja arqueo,
    required String empresaNombre,
    String? empresaRazonSocial,
    String? empresaRuc,
    String? empresaDireccion,
    String? empresaTelefono,
    String? sedeNombre,
    Uint8List? logoEmpresa,
    int paperWidth = 80,
  }) async {
    final profile = await CapabilityProfile.load();
    final paperSize = paperWidth == 58 ? PaperSize.mm58 : PaperSize.mm80;
    final generator = Generator(paperSize, profile);
    final charsPerLine = paperWidth == 58 ? 42 : 64;
    List<int> bytes = [];

    bytes += generator.reset();
    bytes += generator.setStyles(const PosStyles(fontType: PosFontType.fontB));

    // ── Logo ──
    if (logoEmpresa != null) {
      try {
        final decoded = img.decodeImage(logoEmpresa);
        if (decoded != null) {
          final maxWidth = paperWidth == 58 ? 220 : 320;
          final resized = decoded.width > maxWidth
              ? img.copyResize(decoded, width: maxWidth)
              : decoded;
          bytes += generator.image(resized, align: PosAlign.center);
          bytes += generator.feed(1);
        }
      } catch (_) {}
    }

    // ── Empresa ──
    bytes += generator.text(
      empresaNombre,
      styles: const PosStyles(
        align: PosAlign.center,
        height: PosTextSize.size2,
      ),
    );
    if (empresaRazonSocial != null && empresaRazonSocial.isNotEmpty) {
      bytes += generator.text(
        empresaRazonSocial,
        styles: const PosStyles(align: PosAlign.center),
      );
    }
    if (empresaRuc != null && empresaRuc.isNotEmpty) {
      bytes += generator.text(
        'RUC: $empresaRuc',
        styles: const PosStyles(align: PosAlign.center),
      );
    }
    if (empresaDireccion != null && empresaDireccion.trim().isNotEmpty) {
      bytes += generator.text(
        empresaDireccion,
        styles: const PosStyles(align: PosAlign.center),
      );
    }
    if (sedeNombre != null && sedeNombre.isNotEmpty) {
      bytes += generator.text(
        'Sede: $sedeNombre',
        styles: const PosStyles(align: PosAlign.center),
      );
    }
    if (empresaTelefono != null && empresaTelefono.isNotEmpty) {
      bytes += generator.text(
        'Tel: $empresaTelefono',
        styles: const PosStyles(align: PosAlign.center),
      );
    }

    bytes += generator.hr(ch: '-');

    // ── Titulo ──
    bytes += generator.text(
      'ARQUEO DE CAJA',
      styles: const PosStyles(
        align: PosAlign.center,
        height: PosTextSize.size2,
        bold: true,
      ),
    );
    bytes += generator.text(
      '(${arqueo.tipo.label.toUpperCase()})',
      styles: const PosStyles(align: PosAlign.center),
    );
    bytes += generator.text(
      caja.codigo,
      styles: const PosStyles(align: PosAlign.center),
    );

    bytes += generator.hr(ch: '-');

    // ── Cajero, fecha arqueo, autorizador / sucesor ──
    if (caja.usuarioNombre != null && caja.usuarioNombre!.isNotEmpty) {
      bytes += generator.text('Cajero:     ${caja.usuarioNombre}');
    }
    if (arqueo.realizadoPorNombre != null) {
      bytes += generator.text('Realiza:    ${arqueo.realizadoPorNombre}');
    }
    if (arqueo.autorizadoPorNombre != null) {
      bytes += generator.text('Autoriza:   ${arqueo.autorizadoPorNombre}');
    }
    if (arqueo.turnoEntregadoANombre != null) {
      bytes +=
          generator.text('Recibe turno: ${arqueo.turnoEntregadoANombre}');
    }
    bytes += generator.text(
      'Apertura:   ${DateFormatter.formatDateTime(caja.fechaApertura)}',
    );
    bytes += generator.text(
      'Arqueo:     ${DateFormatter.formatDateTime(arqueo.fechaArqueo)}',
    );

    bytes += generator.hr(ch: '-');

    // ── Resumen global ──
    bytes += generator.text('RESUMEN', styles: const PosStyles(bold: true));
    bytes += generator.text(
      _row('Monto Apertura', _money(arqueo.montoApertura), charsPerLine),
    );
    bytes += generator.text(
      _row('Total Ingresos', _money(arqueo.totalIngresos), charsPerLine),
    );
    bytes += generator.text(
      _row('Total Egresos', _money(arqueo.totalEgresos), charsPerLine),
    );
    bytes += generator.hr(ch: '-');
    bytes += generator.text(
      _row('Esperado', _money(arqueo.totalEsperado), charsPerLine),
    );
    bytes += generator.text(
      _row('Conteo Fisico', _money(arqueo.totalConteoFisico), charsPerLine),
    );
    bytes += generator.text(
      _row('DIFERENCIA', _money(arqueo.diferencia), charsPerLine),
      styles: const PosStyles(bold: true),
    );

    // ── Detalle por metodo (solo activos) ──
    final detallesActivos = arqueo.detalles.where((d) {
      return d.apertura.abs() > 0.001 ||
          d.ingresos.abs() > 0.001 ||
          d.egresos.abs() > 0.001 ||
          d.conteoFisico.abs() > 0.001;
    }).toList();

    if (detallesActivos.isNotEmpty) {
      bytes += generator.hr(ch: '-');
      bytes += generator.text(
        'POR METODO DE PAGO',
        styles: const PosStyles(bold: true),
      );
      for (final d in detallesActivos) {
        bytes += generator.text(d.metodoPago.label.toUpperCase());
        bytes += generator.text(
          _row('  Esperado', _money(d.esperado), charsPerLine),
        );
        bytes += generator.text(
          _row('  Conteo', _money(d.conteoFisico), charsPerLine),
        );
        bytes += generator.text(
          _row('  Dif.', _money(d.diferencia), charsPerLine),
        );
      }
    }

    // ── Observaciones ──
    final obs = arqueo.observaciones?.trim();
    if (obs != null && obs.isNotEmpty) {
      bytes += generator.hr(ch: '-');
      bytes += generator.text('Observaciones:');
      bytes += generator.text(obs);
    }

    // ── Firmas (segun tipo) ──
    bytes += generator.feed(3);
    bytes += generator.text(
      '_______________________',
      styles: const PosStyles(align: PosAlign.center),
    );
    bytes += generator.text(
      'Firma del Cajero',
      styles: const PosStyles(align: PosAlign.center),
    );
    // En sorpresivo o relevo agregamos espacio para la segunda firma.
    if (arqueo.tipo != TipoArqueoCaja.rutinario) {
      bytes += generator.feed(2);
      bytes += generator.text(
        '_______________________',
        styles: const PosStyles(align: PosAlign.center),
      );
      bytes += generator.text(
        arqueo.tipo == TipoArqueoCaja.relevo
            ? 'Firma del Sucesor'
            : 'Firma del Auditor',
        styles: const PosStyles(align: PosAlign.center),
      );
    }

    bytes += generator.feed(1);
    bytes += generator.text(
      'Emitido: ${DateFormatter.formatDateTime(DateTime.now())}',
      styles: const PosStyles(align: PosAlign.center),
    );

    bytes += generator.feed(2);
    bytes += generator.cut();
    return bytes;
  }

  static String _row(String label, String value, int chars) {
    if (label.length + value.length + 1 >= chars) {
      return '$label\n${value.padLeft(chars)}';
    }
    final spaces = chars - label.length - value.length;
    return label + (' ' * spaces) + value;
  }

  static String _money(double value) {
    final isNegative = value < 0;
    final abs = value.abs();
    final formatted = abs.toStringAsFixed(2);
    return isNegative ? 'S/ -$formatted' : 'S/ $formatted';
  }
}

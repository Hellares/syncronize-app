import 'dart:typed_data';

import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:image/image.dart' as img;

import '../../../../core/utils/date_formatter.dart';
import '../../domain/entities/caja.dart';
import '../../domain/entities/cierre_caja.dart';
import '../../domain/entities/movimiento_caja.dart';
import '../../domain/entities/resumen_caja.dart';

/// Genera bytes ESC-POS del resumen de cierre de caja. Mismo estilo y
/// tipografias que el ticket de venta: fontB global, padding manual
/// para tablas (las termicas baratas ignoran ESC $ del Generator.row).
class CierreCajaEscPosGenerator {
  static Future<List<int>> generate({
    required Caja caja,
    /// Si la caja está CERRADA, pasamos el cierre y se imprime el ticket
    /// definitivo con Esperado/Conteo/Diferencia. Si la caja está ABIERTA,
    /// pasamos `null` y entonces el caller DEBE proveer los totales en
    /// vivo vía `totalIngresos`/`totalEgresos`/`detalles` para que el
    /// ticket se imprima como "ESTADO DE CAJA" (snapshot de auditoría).
    CierreCaja? cierre,
    required String empresaNombre,
    String? empresaRazonSocial,
    String? empresaRuc,
    String? empresaDireccion,
    String? empresaTelefono,
    String? sedeNombre,
    Uint8List? logoEmpresa,
    int paperWidth = 80,
    /// Opcional: lista de movimientos para imprimir detalle completo
    /// (ventas, egresos, otros). Si es null o vacía, se imprime solo el
    /// resumen como antes. Los movimientos anulados se omiten del listado.
    List<MovimientoCaja>? movimientos,
    /// Totales en vivo para imprimir cuando NO hay cierre (caja abierta).
    /// Si `cierre` es null, estos son required en la práctica.
    double? totalIngresosVivo,
    double? totalEgresosVivo,
    List<ResumenMetodoPago>? detallesVivo,
    /// Desglose para mostrar bajo Total Egresos. Aplica tanto al cierre
    /// como al snapshot de caja abierta.
    double egresoAnulacionVenta = 0,
    int cantidadAnulaciones = 0,
    List<EgresoPorCategoria> egresosPorCategoria = const [],
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
    final direccion =
        empresaDireccion?.trim().isNotEmpty == true ? empresaDireccion : null;
    if (direccion != null) {
      bytes += generator.text(
        direccion,
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
      cierre != null ? 'CIERRE DE CAJA' : 'ESTADO DE CAJA',
      styles: const PosStyles(
        align: PosAlign.center,
        height: PosTextSize.size2,
        bold: true,
      ),
    );
    bytes += generator.text(
      caja.codigo,
      styles: const PosStyles(align: PosAlign.center),
    );

    bytes += generator.hr(ch: '-');

    // ── Cajero, fechas, duracion ──
    if (caja.usuarioNombre != null && caja.usuarioNombre!.isNotEmpty) {
      bytes += generator.text('Cajero:    ${caja.usuarioNombre}');
    }
    bytes += generator.text(
      'Apertura:  ${DateFormatter.formatDateTime(caja.fechaApertura)}',
    );
    if (caja.fechaCierre != null) {
      bytes += generator.text(
        'Cierre:    ${DateFormatter.formatDateTime(caja.fechaCierre!)}',
      );
      final duracion = caja.fechaCierre!.difference(caja.fechaApertura);
      bytes += generator.text('Duracion:  ${_formatDuracion(duracion)}');
    }

    bytes += generator.hr(ch: '-');

    // ── Resumen global ──
    final totIng = cierre?.totalIngresos ?? totalIngresosVivo ?? 0;
    final totEgr = cierre?.totalEgresos ?? totalEgresosVivo ?? 0;

    bytes += generator.text(
      'RESUMEN',
      styles: const PosStyles(bold: true),
    );
    bytes += generator.text(
      _row('Monto Apertura', _money(caja.montoApertura), charsPerLine),
    );
    bytes += generator.text(
      _row('Total Ingresos', _money(totIng), charsPerLine),
    );
    if (egresoAnulacionVenta > 0) {
      bytes += generator.text(
        _row('  (-${_money(egresoAnulacionVenta)} anulados)', '', charsPerLine),
      );
    }
    bytes += generator.text(
      _row('Total Egresos', _money(totEgr), charsPerLine),
    );
    // Desglose por categoría — solo egresos manuales reales.
    for (final e in egresosPorCategoria) {
      final lbl = '  ${_truncate(e.label, 18)}'
          '${e.cantidad > 0 ? " (${e.cantidad})" : ""}';
      bytes += generator.text(_row(lbl, _money(e.total), charsPerLine));
    }
    if (egresoAnulacionVenta > 0) {
      final lbl = '  Anul. Venta'
          '${cantidadAnulaciones > 0 ? " ($cantidadAnulaciones)" : ""}'
          ' *';
      bytes += generator.text(
        _row(lbl, _money(egresoAnulacionVenta), charsPerLine),
      );
      bytes += generator.text('  * ya descontado de Ingresos');
    }
    if (cierre != null) {
      bytes += generator.hr(ch: '-');
      bytes += generator.text(
        _row('Esperado', _money(cierre.totalEsperado), charsPerLine),
      );
      bytes += generator.text(
        _row('Conteo Fisico', _money(cierre.totalConteoFisico), charsPerLine),
      );
      bytes += generator.text(
        _row('DIFERENCIA', _money(cierre.diferencia), charsPerLine),
        styles: const PosStyles(bold: true),
      );
    } else {
      // Caja abierta: saldo en vivo = apertura + ingresos - egresos.
      final saldo = caja.montoApertura + totIng - totEgr;
      bytes += generator.hr(ch: '-');
      bytes += generator.text(
        _row('SALDO ACTUAL', _money(saldo), charsPerLine),
        styles: const PosStyles(bold: true),
      );
    }

    // ── Detalle por metodo (solo si hay actividad) ──
    final detallesConActividad = cierre != null
        ? cierre.detalles.where((d) {
            return d.apertura.abs() > 0.001 ||
                d.ingresos.abs() > 0.001 ||
                d.egresos.abs() > 0.001 ||
                d.conteoFisico.abs() > 0.001;
          }).toList()
        : const [];

    if (detallesConActividad.isNotEmpty) {
      bytes += generator.hr(ch: '-');
      bytes += generator.text(
        'POR METODO DE PAGO',
        styles: const PosStyles(bold: true),
      );
      for (final d in detallesConActividad) {
        bytes += generator.text(
          d.metodoPago.label.toUpperCase(),
          styles: const PosStyles(bold: true),
        );
        if (d.apertura.abs() > 0.001) {
          bytes += generator.text(
            _row('  Apertura', _money(d.apertura), charsPerLine),
          );
        }
        if (d.ingresos.abs() > 0.001) {
          bytes += generator.text(
            _row('  Ingresos', _money(d.ingresos), charsPerLine),
          );
        }
        if (d.egresos.abs() > 0.001) {
          bytes += generator.text(
            _row('  Egresos', _money(d.egresos), charsPerLine),
          );
        }
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
    final obs = cierre?.observaciones?.trim();
    if (obs != null && obs.isNotEmpty) {
      bytes += generator.hr(ch: '-');
      bytes += generator.text('Observaciones:');
      bytes += generator.text(obs);
    }

    // ── Detalle de movimientos (opcional) ──
    // Si el caller pasa movimientos, los desglosamos en VENTAS / EGRESOS /
    // OTROS INGRESOS. Se omiten anulados y contrapartidas. Cada línea va
    // compacta (hora HH:MM + código/categoría + método + monto).
    if (movimientos != null && movimientos.isNotEmpty) {
      final movsValidos = movimientos
          .where((m) => !m.anulado)
          .toList()
        ..sort((a, b) => a.fechaMovimiento.compareTo(b.fechaMovimiento));

      final ventas = movsValidos
          .where((m) =>
              m.tipo == TipoMovimientoCaja.ingreso &&
              m.categoria == CategoriaMovimientoCaja.venta)
          .toList();
      final egresos =
          movsValidos.where((m) => m.tipo == TipoMovimientoCaja.egreso).toList();
      final otrosIngresos = movsValidos
          .where((m) =>
              m.tipo == TipoMovimientoCaja.ingreso &&
              m.categoria != CategoriaMovimientoCaja.venta)
          .toList();

      bytes += generator.hr(ch: '=');
      bytes += generator.text(
        'DETALLE DE MOVIMIENTOS',
        styles: const PosStyles(align: PosAlign.center, bold: true),
      );
      bytes += generator.hr(ch: '-');

      // VENTAS
      if (ventas.isNotEmpty) {
        bytes += generator.text(
          'VENTAS (${ventas.length})',
          styles: const PosStyles(bold: true),
        );
        double totalVentas = 0;
        for (final m in ventas) {
          final hora = _hora(m.fechaMovimiento);
          final codigo = m.ventaCodigo ?? '-';
          final metodo = _metodoCorto(m.metodoPago.label);
          final monto = _money(m.monto);
          bytes += generator.text(
            _row('$hora $codigo $metodo', monto, charsPerLine),
          );
          totalVentas += m.monto;
        }
        bytes += generator.text(
          _row('  TOTAL VENTAS', _money(totalVentas), charsPerLine),
          styles: const PosStyles(bold: true),
        );
      }

      // EGRESOS
      if (egresos.isNotEmpty) {
        if (ventas.isNotEmpty) bytes += generator.feed(1);
        bytes += generator.text(
          'EGRESOS (${egresos.length})',
          styles: const PosStyles(bold: true),
        );
        double totalEgr = 0;
        for (final m in egresos) {
          final hora = _hora(m.fechaMovimiento);
          final cat = _categoriaCorta(m.categoria);
          final metodo = _metodoCorto(m.metodoPago.label);
          final monto = _money(m.monto);
          bytes +=
              generator.text(_row('$hora $cat $metodo', monto, charsPerLine));
          final desc = (m.descripcion ?? '').trim();
          if (desc.isNotEmpty) {
            bytes += generator.text('  $desc');
          }
          totalEgr += m.monto;
        }
        bytes += generator.text(
          _row('  TOTAL EGRESOS', _money(totalEgr), charsPerLine),
          styles: const PosStyles(bold: true),
        );
      }

      // OTROS INGRESOS (no venta)
      if (otrosIngresos.isNotEmpty) {
        if (ventas.isNotEmpty || egresos.isNotEmpty) {
          bytes += generator.feed(1);
        }
        bytes += generator.text(
          'OTROS INGRESOS (${otrosIngresos.length})',
          styles: const PosStyles(bold: true),
        );
        double totalOI = 0;
        for (final m in otrosIngresos) {
          final hora = _hora(m.fechaMovimiento);
          final cat = _categoriaCorta(m.categoria);
          final metodo = _metodoCorto(m.metodoPago.label);
          final monto = _money(m.monto);
          bytes +=
              generator.text(_row('$hora $cat $metodo', monto, charsPerLine));
          totalOI += m.monto;
        }
        bytes += generator.text(
          _row('  TOTAL OTROS', _money(totalOI), charsPerLine),
          styles: const PosStyles(bold: true),
        );
      }
    }

    // ── Firma cajero ──
    bytes += generator.feed(3);
    bytes += generator.text(
      '_______________________',
      styles: const PosStyles(align: PosAlign.center),
    );
    bytes += generator.text(
      'Firma del Cajero',
      styles: const PosStyles(align: PosAlign.center),
    );

    bytes += generator.feed(1);
    bytes += generator.text(
      'Emitido: ${DateFormatter.formatDateTime(DateTime.now())}',
      styles: const PosStyles(align: PosAlign.center),
    );

    bytes += generator.feed(2);
    bytes += generator.cut();
    return bytes;
  }

  /// Linea label + valor con padding manual (Generator.row falla en
  /// termicas baratas porque usa posicionamiento absoluto ESC $).
  static String _row(String label, String value, int chars) {
    if (label.length + value.length + 1 >= chars) {
      // No cabe en una linea: hacemos dos.
      return '$label\n${value.padLeft(chars)}';
    }
    final spaces = chars - label.length - value.length;
    return label + (' ' * spaces) + value;
  }

  /// Corta strings largos para que entren en la línea del ticket.
  static String _truncate(String s, int max) {
    if (s.length <= max) return s;
    return '${s.substring(0, max - 1)}.';
  }

  static String _money(double value) {
    final isNegative = value < 0;
    final abs = value.abs();
    final formatted = abs.toStringAsFixed(2);
    return isNegative ? 'S/ -$formatted' : 'S/ $formatted';
  }

  static String _formatDuracion(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    if (h > 0) return '${h}h ${m}m';
    return '${m}m';
  }

  /// HH:mm en hora local (ya convertida por DateFormatter).
  static String _hora(DateTime dt) {
    final local = dt.isUtc ? dt.toLocal() : dt;
    final hh = local.hour.toString().padLeft(2, '0');
    final mm = local.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  /// Abrevia métodos largos para que la línea quepa en 42/64 chars.
  static String _metodoCorto(String label) {
    switch (label.toUpperCase()) {
      case 'TRANSFERENCIA':
        return 'TRANSF';
      case 'EFECTIVO':
        return 'EFEC';
      default:
        return label.toUpperCase();
    }
  }

  /// Etiqueta corta para categorías de egreso (las usadas en el ticket).
  static String _categoriaCorta(CategoriaMovimientoCaja c) {
    switch (c) {
      case CategoriaMovimientoCaja.compra:
        return 'COMPRA';
      case CategoriaMovimientoCaja.devolucion:
        return 'DEVOL';
      case CategoriaMovimientoCaja.pagoProveedor:
        return 'PAGO PROV';
      case CategoriaMovimientoCaja.gastoOperativo:
        return 'GASTO OP';
      case CategoriaMovimientoCaja.otroEgreso:
        return 'OTRO EGR';
      case CategoriaMovimientoCaja.otroIngreso:
        return 'OTRO ING';
      case CategoriaMovimientoCaja.reposicionCajaChica:
        return 'REPO C.CH.';
      case CategoriaMovimientoCaja.adelantoServicio:
        return 'ADEL SERV';
      case CategoriaMovimientoCaja.pedidoMarketplace:
        return 'PEDIDO MKT';
      case CategoriaMovimientoCaja.venta:
        return 'VENTA';
      case CategoriaMovimientoCaja.depositoTesoreria:
        return 'DEP TES';
      case CategoriaMovimientoCaja.retiroTesoreria:
        return 'RET TES';
      case CategoriaMovimientoCaja.ajusteTesoreria:
        return 'AJU TES';
      case CategoriaMovimientoCaja.reversoCajaCerrada:
        return 'REV CAJA';
    }
  }
}


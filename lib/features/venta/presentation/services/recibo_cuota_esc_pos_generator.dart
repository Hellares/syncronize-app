import 'dart:typed_data';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:image/image.dart' as img;
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/utils/logo_termico.dart';
import '../../domain/entities/venta.dart';

/// Una cuota tocada por el pago, con cuánto se le aplicó y cómo quedó.
/// Se calcula diffeando las cuotas antes/después del pago: el backend
/// reparte el monto entre las cuotas pendientes en orden, así que un solo
/// pago puede cerrar varias.
class CuotaAplicada {
  final int numero;
  final double montoAplicado;
  final double saldoRestante;
  final DateTime fechaVencimiento;

  const CuotaAplicada({
    required this.numero,
    required this.montoAplicado,
    required this.saldoRestante,
    required this.fechaVencimiento,
  });

  bool get quedoPagada => saldoRestante <= 0.005;
}

/// Recibo térmico de cobranza de cuota(s) de una venta a crédito.
///
/// NO es un comprobante de pago electrónico: el comprobante fiscal (boleta
/// o factura) es el de la venta. Este papel es control interno — la
/// constancia que se le entrega al cliente cada vez que abona. Por eso el
/// pie lo dice explícitamente, para que nadie lo confunda con un documento
/// SUNAT.
class ReciboCuotaEscPosGenerator {
  static Future<List<int>> generate({
    required Venta venta,
    required List<CuotaAplicada> aplicaciones,
    required double montoPagado,
    required String metodoPago,
    String? referencia,
    required String empresaNombre,
    String? empresaRazonSocial,
    String? empresaRuc,
    String? empresaDireccion,
    String? empresaTelefono,
    String? sedeNombre,
    /// Quién cobró: se espera el ALIAS del cajero (el nombre completo solo
    /// como fallback), igual que el ticket de venta.
    String? cobradoPor,
    Uint8List? logoEmpresa,
    int paperWidth = 80,
    DateTime? fecha,
    /// Copia de un cobro anterior: se rotula REIMPRESION y el estado de la
    /// deuda se aclara que es "al dia de hoy" (no el del momento del pago,
    /// que no se guarda).
    bool esReimpresion = false,
    /// Desglose de la imputacion cuando el credito tiene interes/mora.
    double montoInteres = 0,
    double montoMora = 0,
  }) async {
    final profile = await CapabilityProfile.load();
    final paperSize = paperWidth == 58 ? PaperSize.mm58 : PaperSize.mm80;
    final generator = Generator(paperSize, profile);
    // fontB: 42 chars en 58mm, 64 en 80mm (igual que el ticket de venta).
    final chars = paperWidth == 58 ? 42 : 64;
    List<int> bytes = [];

    // Reset: limpia estilos residuales de impresiones previas.
    bytes += generator.reset();
    bytes += generator.setStyles(
      const PosStyles(fontType: PosFontType.fontB),
    );

    // ── Logo ──
    if (logoEmpresa != null) {
      try {
        final decoded = img.decodeImage(logoEmpresa);
        if (decoded != null) {
          var logo = prepararLogoTermico(decoded);
          final maxWidth = paperWidth == 58 ? 280 : 380;
          if (logo.width > maxWidth) {
            logo = img.copyResize(logo, width: maxWidth);
          }
          bytes += [0x1B, 0x33, 0x00]; // ESC 3 0 → interlineado 0 para el raster
          bytes += generator.image(logo, align: PosAlign.center);
          bytes += [0x1B, 0x32]; // ESC 2 → interlineado default
          bytes += generator.feed(1);
        }
      } catch (_) {}
    }

    // ── Encabezado ──
    bytes += generator.text(
      _ascii(empresaNombre),
      styles: const PosStyles(
        align: PosAlign.center,
        fontType: PosFontType.fontB,
        height: PosTextSize.size2,
      ),
    );
    bytes += generator.setStyles(
      const PosStyles(fontType: PosFontType.fontB),
    );
    if (empresaRazonSocial != null && empresaRazonSocial != empresaNombre) {
      bytes += _centro(generator, empresaRazonSocial);
    }
    if (empresaRuc != null) bytes += _centro(generator, 'RUC: $empresaRuc');
    if (sedeNombre != null) bytes += _centro(generator, 'Sede: $sedeNombre');
    if (empresaDireccion != null) bytes += _centro(generator, empresaDireccion);
    if (empresaTelefono != null) bytes += _centro(generator, 'Tel: $empresaTelefono');

    // ── Título ──
    bytes += generator.text('=' * chars);
    bytes += generator.text(
      'RECIBO DE PAGO',
      styles: const PosStyles(
        align: PosAlign.center,
        fontType: PosFontType.fontB,
        height: PosTextSize.size2,
      ),
    );
    bytes += generator.setStyles(const PosStyles(fontType: PosFontType.fontB));
    bytes += _centro(generator, _tituloCuotas(aplicaciones, venta.numeroCuotas));
    if (esReimpresion) bytes += _centro(generator, '** REIMPRESION **');
    bytes += generator.text('=' * chars);

    // ── Datos de la venta ──
    final f = fecha ?? DateTime.now();
    bytes += generator.text(_kv('Venta:', venta.codigo, chars));
    if (venta.codigoComprobante != null) {
      bytes += generator.text(_kv('Comprobante:', venta.codigoComprobante!, chars));
    }
    bytes += generator.text(
      _kv('Cliente:', _ascii(_recorta(venta.nombreCliente, chars - 12)), chars),
    );
    if ((venta.documentoCliente ?? '').isNotEmpty) {
      bytes += generator.text(_kv('Doc:', venta.documentoCliente!, chars));
    }
    bytes += generator.text(_kv('Fecha:', DateFormatter.formatDateTime(f), chars));
    if (cobradoPor != null && cobradoPor.trim().isNotEmpty) {
      bytes += generator.text(
        _kv('Cobro:', _ascii(_recorta(cobradoPor.trim(), chars - 10)), chars),
      );
    }

    // ── Monto pagado (el dato protagonista) ──
    bytes += generator.text('-' * chars);
    bytes += _centro(generator, 'MONTO PAGADO');
    bytes += generator.text(
      _money(montoPagado),
      styles: const PosStyles(
        align: PosAlign.center,
        fontType: PosFontType.fontB,
        height: PosTextSize.size2,
        width: PosTextSize.size2,
      ),
    );
    bytes += generator.setStyles(const PosStyles(fontType: PosFontType.fontB));
    bytes += generator.text('-' * chars);

    bytes += generator.text(_kv('Metodo:', metodoPago, chars));
    if (referencia != null && referencia.trim().isNotEmpty) {
      bytes += generator.text(_kv('Operacion:', referencia.trim(), chars));
    }
    // Desglose: qué parte del abono fue a mora/interés y qué parte bajó la
    // deuda. Sin esto el cliente no entiende por qué su saldo bajó menos.
    if (montoInteres > 0.005 || montoMora > 0.005) {
      final principal = montoPagado - montoInteres - montoMora;
      if (principal > 0.005) {
        bytes += generator.text(_kv('  A capital:', _money(principal), chars));
      }
      if (montoInteres > 0.005) {
        bytes += generator.text(_kv('  A interes:', _money(montoInteres), chars));
      }
      if (montoMora > 0.005) {
        bytes += generator.text(_kv('  A mora:', _money(montoMora), chars));
      }
    }

    // ── Detalle por cuota ──
    if (aplicaciones.isNotEmpty) {
      bytes += generator.text('-' * chars);
      bytes += generator.text('DETALLE:');
      for (final a in aplicaciones) {
        final estado = a.quedoPagada
            ? 'PAGADA'
            : 'parcial, resta ${_money(a.saldoRestante)}';
        bytes += generator.text(
          _kv(
            '  Cuota ${a.numero} (vence ${DateFormatter.formatDate(a.fechaVencimiento)})',
            _money(a.montoAplicado),
            chars,
          ),
        );
        bytes += generator.text('    $estado');
      }
    }

    // ── Estado de la deuda ──
    final cuotas = venta.cuotas ?? const [];
    final saldoTotal = cuotas.fold<double>(0, (s, c) => s + c.saldoPendiente);
    final pagadoTotal = cuotas.fold<double>(0, (s, c) => s + c.montoPagado);
    final pagadas = cuotas.where((c) => c.estado == 'PAGADA').length;

    bytes += generator.text('=' * chars);
    if (esReimpresion) {
      // El estado histórico del momento del pago no se persiste; lo honesto
      // es aclarar que estos números son de hoy.
      bytes += generator.text('ESTADO DE LA DEUDA (al dia de hoy):');
    }
    bytes += generator.text(_kv('Total venta:', _money(venta.total), chars));
    if (cuotas.isNotEmpty) {
      bytes += generator.text(_kv('Pagado a la fecha:', _money(pagadoTotal), chars));
      bytes += generator.text(_kv('Cuotas pagadas:', '$pagadas de ${cuotas.length}', chars));
    }

    if (saldoTotal > 0.005) {
      bytes += generator.text(_kv('SALDO PENDIENTE:', _money(saldoTotal), chars));
      // Próxima cuota por vencer: lo primero que el cliente pregunta.
      final pendientes = cuotas.where((c) => c.saldoPendiente > 0.005).toList()
        ..sort((a, b) => a.numero.compareTo(b.numero));
      if (pendientes.isNotEmpty) {
        final p = pendientes.first;
        bytes += generator.text('-' * chars);
        bytes += generator.text(
          _kv(
            'Proximo pago: cuota ${p.numero}',
            '${_money(p.saldoPendiente)} ${DateFormatter.formatDate(p.fechaVencimiento)}',
            chars,
          ),
        );
      }
    } else {
      bytes += generator.text('=' * chars);
      bytes += generator.text(
        'DEUDA CANCELADA',
        styles: const PosStyles(
          align: PosAlign.center,
          fontType: PosFontType.fontB,
          height: PosTextSize.size2,
        ),
      );
      bytes += generator.setStyles(const PosStyles(fontType: PosFontType.fontB));
    }

    // ── Pie legal + firma ──
    bytes += generator.text('=' * chars);
    bytes += _centro(generator, 'Documento interno de control.');
    bytes += _centro(generator, 'NO es comprobante de pago');
    bytes += _centro(generator, 'electronico.');
    bytes += generator.feed(2);
    bytes += _centro(generator, '_' * (chars ~/ 2));
    bytes += _centro(generator, 'Firma / conforme');

    bytes += generator.feed(3);
    bytes += generator.cut();

    return bytes;
  }

  /// "CUOTA 2 DE 4" o "CUOTAS 2-3 DE 4" cuando el pago cerró varias.
  static String _tituloCuotas(List<CuotaAplicada> aplicaciones, int? total) {
    if (aplicaciones.isEmpty) return 'ABONO A CUENTA';
    final sufijo = total != null && total > 0 ? ' DE $total' : '';
    if (aplicaciones.length == 1) {
      return 'CUOTA ${aplicaciones.first.numero}$sufijo';
    }
    final nums = aplicaciones.map((a) => a.numero).toList()..sort();
    return 'CUOTAS ${nums.first}-${nums.last}$sufijo';
  }

  static List<int> _centro(Generator g, String texto) => g.text(
        _ascii(texto),
        styles: const PosStyles(align: PosAlign.center),
      );

  static String _money(double v) => 'S/${v.toStringAsFixed(2)}';

  static String _recorta(String s, int max) =>
      s.length <= max ? s : s.substring(0, max);

  /// Caracteres tipográficos fuera de CP437/CP850 rompen la impresión.
  static String _ascii(String s) => s
      .replaceAll('—', '-')
      .replaceAll('–', '-')
      .replaceAll('·', '.')
      .replaceAll('“', '"')
      .replaceAll('”', '"')
      .replaceAll('’', "'")
      .replaceAll('‘', "'")
      .replaceAll('…', '...');

  /// Label a la izquierda, valor a la derecha, relleno manual en el medio.
  /// Las térmicas baratas fallan con `row()` de más de 2 columnas.
  static String _kv(String label, String valor, int charsPerLine) {
    final libres = charsPerLine - valor.length;
    if (libres <= 1) {
      return '$label\n${' ' * (charsPerLine - valor.length)}$valor';
    }
    final labelRecortado =
        label.length > libres - 1 ? label.substring(0, libres - 1) : label;
    final espacios = charsPerLine - labelRecortado.length - valor.length;
    return labelRecortado + ' ' * espacios + valor;
  }
}

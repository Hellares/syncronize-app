import 'dart:typed_data';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:image/image.dart' as img;
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/utils/logo_termico.dart';
import '../../../../core/utils/number_to_words.dart';
import '../../domain/entities/venta.dart';

class TicketVentaEscPosGenerator {
  /// Genera bytes ESC-POS de un ticket de venta tratando de replicar el
  /// diseño completo del PDF preview (logo, datos SUNAT, vendedor/cajero,
  /// operaciones gravada/exonerada/inafecta, ICBPER, monto en letras, QR,
  /// enlace de consulta del comprobante electrónico).
  ///
  /// Los parámetros nuevos son TODOS opcionales para no romper callers
  /// antiguos: si no se proveen, el ticket cae al modo simple anterior.
  static Future<List<int>> generate({
    required Venta venta,
    required String empresaNombre,
    String? empresaRazonSocial,
    String? empresaRuc,
    String? empresaDireccion,
    String? empresaTelefono,
    String? sedeNombre,
    Uint8List? logoEmpresa,
    int paperWidth = 80,
    String nombreImpuesto = 'IGV',
    // Pie configurable por la empresa (Configuración de Documentos:
    // textoPieVenta ?? textoPiePagina). null = texto por defecto.
    String? textoPie,
  }) async {
    final profile = await CapabilityProfile.load();
    final paperSize = paperWidth == 58 ? PaperSize.mm58 : PaperSize.mm80;
    final generator = Generator(paperSize, profile);
    List<int> bytes = [];

    // ── Reset físico de la impresora ──
    // Garantiza que cualquier estado residual (bold, underline, etc.)
    // de impresiones previas queda limpio antes de empezar. Sin esto,
    // si una impresión anterior dejó bold ON, persistía en el siguiente
    // ticket porque setStyles solo emite comandos al detectar diff.
    bytes += generator.reset();

    // ── Fuente más chica (fontB ~9x17 dots vs fontA ~12x24) ──
    // setStyles persiste el fontType en el state interno del generator.
    // Como mis PosStyles literales no setean fontType (queda null), el
    // setStyles posterior no lo pisa → todo el ticket usa fontB.
    // Por eso charsPerLine sube de 32→42 (58mm) y 48→64 (80mm).
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
          // image() (ESC *) imprime por bandas de 24 dots: si la impresora
          // mantiene su interlineado por defecto (~30 dots) mete aire entre
          // bandas y tras el logo (~1.5cm). ESC 3 0 fija interlineado 0
          // mientras dura el raster; ESC 2 lo restaura para el texto.
          // (GS v 0 / imageRaster NO está soportado por estas térmicas.)
          bytes += [0x1B, 0x33, 0x00]; // ESC 3 0 → line spacing 0
          bytes += generator.image(logo, align: PosAlign.center);
          bytes += [0x1B, 0x32]; // ESC 2 → line spacing default
          bytes += generator.feed(1);
        }
      } catch (_) {}
    }

    // ── Encabezado empresa ──
    // fontB + height x2, sin bold → destacado por el doble alto pero
    // sin el peso del bold.
    bytes += generator.text(
      empresaNombre,
      styles: const PosStyles(
        align: PosAlign.center,
        fontType: PosFontType.fontB,
        height: PosTextSize.size2,
        width: PosTextSize.size1,
      ),
    );
    bytes += generator.setStyles(
      const PosStyles(
        fontType: PosFontType.fontB,
        height: PosTextSize.size1,
        width: PosTextSize.size1,
      ),
    );
    if (empresaRazonSocial != null && empresaRazonSocial != empresaNombre) {
      // fontB (mismo tamaño que el resto del header — RUC, sede, etc.).
      // No se puede ir más chico en ESC-POS estándar; la lib no expone
      // condensed mode y los bytes raw (SI/DC2) son ignorados o se
      // imprimen como "$" en la Bienex.
      bytes += generator.text(
        empresaRazonSocial,
        styles: const PosStyles(align: PosAlign.center),
      );
    }
    if (empresaRuc != null) {
      bytes += generator.text(
        'RUC: $empresaRuc',
        styles: const PosStyles(align: PosAlign.center),
      );
    }
    if (sedeNombre != null) {
      bytes += generator.text(
        'Sede: $sedeNombre',
        styles: const PosStyles(align: PosAlign.center),
      );
    }
    if (empresaDireccion != null) {
      bytes += generator.text(
        empresaDireccion,
        styles: const PosStyles(align: PosAlign.center),
      );
    }
    if (empresaTelefono != null) {
      bytes += generator.text(
        'Tel: $empresaTelefono',
        styles: const PosStyles(align: PosAlign.center),
      );
    }

    bytes += generator.hr(ch: '-');

    // ── Tipo y código del comprobante ──
    // fontB (chico, igual que el body) centrado. Sin bold para
    // mantener el look limpio.
    final tituloDoc = _nombreTipoComprobante(venta.tipoComprobante);
    bytes += generator.text(
      tituloDoc,
      styles: const PosStyles(align: PosAlign.center),
    );
    bytes += generator.text(
      venta.codigoComprobante ?? venta.codigo,
      styles: const PosStyles(align: PosAlign.center),
    );

    bytes += generator.hr(ch: '-');

    // ── Metadata venta ──
    bytes += generator.text(
      'Fecha: ${DateFormatter.formatDate(venta.fechaVenta)}',
    );
    final vendedor = venta.vendedorAlias ?? venta.vendedorNombre;
    if (vendedor != null && vendedor.isNotEmpty) {
      bytes += generator.text('Vendedor: $vendedor');
    }
    final cajero = venta.cajeroAlias ?? venta.cajeroNombre;
    if (cajero != null && cajero.isNotEmpty) {
      bytes += generator.text('Cajero: $cajero');
    }
    // Codigo interno de venta (VTA-SED-XXXXX). En tickets simples ya se
    // imprime arriba como codigo principal (no hay codigoComprobante),
    // pero en boleta/factura el principal pasa a ser B001-XXX/F001-XXX
    // y el codigo interno desaparece. Lo agregamos aqui para que el
    // cajero siempre pueda referenciar la venta internamente.
    if (venta.codigoComprobante != null &&
        venta.codigoComprobante != venta.codigo) {
      bytes += generator.text('Cod. venta: ${venta.codigo}');
    }

    bytes += generator.hr(ch: '-');

    // ── Cliente ──
    bytes += generator.text('CLIENTE');
    bytes += generator.text('Nombre: ${venta.nombreCliente}');
    if (venta.documentoCliente != null) {
      bytes += generator.text('Doc: ${venta.documentoCliente}');
    }

    bytes += generator.hr(ch: '-');

    // ── Detalle como tabla armada manualmente con padding ──
    // Muchas térmicas baratas (Bienex, Xprinter, chinas genéricas) ignoran
    // el comando ESC-POS de posicionamiento absoluto que usa
    // Generator.row() internamente. Por eso los detalles con 4 columnas
    // se pegaban a la izquierda. Construir cada línea como texto plano
    // con padding garantiza que cualquier impresora la respete.
    final cols = _ColAnchos.forPaper(paperWidth);
    bytes += generator.text('DETALLE');
    bytes += generator.text(
      cols.formatear('CANT', 'DESCRIPCION', 'P.U.', 'TOTAL'),
    );
    bytes += generator.hr(ch: '-');

    if (venta.detalles != null) {
      String? lastCombo;
      for (final d in venta.detalles!) {
        // Header del combo cuando empieza un nuevo grupo.
        if (d.origenComboId != null && d.origenComboId != lastCombo) {
          double ahorroCombo = 0;
          for (final x in venta.detalles!) {
            if (x.origenComboId == d.origenComboId) {
              ahorroCombo += x.descuento;
            }
          }
          bytes += generator.text(
            '** COMBO: ${(d.origenComboNombre ?? 'Combo').toUpperCase()} **',
          );
          if (ahorroCombo > 0) {
            bytes += generator.text(
              '   Ahorro: -S/${ahorroCombo.toStringAsFixed(2)}',
            );
          }
          lastCombo = d.origenComboId;
        } else if (d.origenComboId == null) {
          lastCombo = null;
        }

        final qty = d.cantidad % 1 == 0
            ? d.cantidad.toInt().toString()
            : d.cantidad.toStringAsFixed(2);
        // Sangría visual en la descripción para items que vienen de un combo.
        // _ascii(): las térmicas usan code pages (CP437/CP850) sin "—", "·",
        // comillas tipográficas, etc. — un carácter fuera del code page
        // imprime basura o aborta el trabajo de impresión.
        final descripcion = _ascii(d.origenComboId != null
            ? '  ${d.descripcion}'
            : d.descripcion);
        final pu = d.precioUnitario.toStringAsFixed(2);
        final total = d.total.toStringAsFixed(2);

        // Si la descripción es más larga que su columna, envolver al
        // siguiente renglón indentada al inicio de la columna DESC.
        final chunks = _wrapEnAncho(descripcion, cols.desc);
        bytes += generator.text(
          cols.formatear(qty, chunks.first, pu, total),
        );
        for (var i = 1; i < chunks.length; i++) {
          bytes += generator.text(
            cols.formatear('', chunks[i], '', ''),
          );
        }

        if (d.descuento > 0) {
          bytes += generator.text(
            '  Desc: -S/${d.descuento.toStringAsFixed(2)}',
          );
        }

        // Línea que cobra una orden de servicio: la línea va por el COSTO
        // NETO del servicio (el comprobante sale por el total); aquí se
        // desglosa el historial: adelantos previos (con su método) y lo
        // efectivamente cobrado HOY (total − adelanto).
        if (d.esOrdenServicio && (d.ordenAdelanto ?? 0) > 0) {
          final metodo = d.ordenMetodoPagoAdelanto != null
              ? ' (${d.ordenMetodoPagoAdelanto})'
              : '';
          bytes += generator.text(
            '  Adelanto$metodo: -S/${d.ordenAdelanto!.toStringAsFixed(2)}',
          );
          final cobradoHoy = d.total - d.ordenAdelanto!;
          bytes += generator.text(
            '  Saldo cobrado hoy: S/${cobradoHoy.toStringAsFixed(2)}',
          );
        }
      }
    }

    bytes += generator.hr(ch: '-');

    // Ancho efectivo de la línea según el papel. Lo usamos para armar
    // las líneas label-valor con padding manual (las térmicas baratas
    // ignoran el posicionamiento absoluto que usa Generator.row).
    // Con fontB: 42 chars en 58mm, 64 en 80mm (vs 32/48 de fontA).
    final charsPerLine = paperWidth == 58 ? 42 : 64;

    // ── Condición ──
    bytes += generator.text(
      'Condicion: ${venta.esCredito ? "CREDITO" : "CONTADO"}',
    );

    // ── Operaciones tributarias (SUNAT) ──
    final tieneDesglose = venta.comprobanteGravada != null ||
        venta.comprobanteExonerada != null ||
        venta.comprobanteInafecta != null;

    if (tieneDesglose) {
      bytes += generator.text(
        _kv('Op. Gravada:', _money(venta.comprobanteGravada ?? 0), charsPerLine),
      );
      bytes += generator.text(
        _kv('Op. Exonerada:', _money(venta.comprobanteExonerada ?? 0), charsPerLine),
      );
      bytes += generator.text(
        _kv('Op. Inafecta:', _money(venta.comprobanteInafecta ?? 0), charsPerLine),
      );
    } else {
      bytes += generator.text(
        _kv('Subtotal:', _money(venta.subtotal), charsPerLine),
      );
    }

    if (venta.descuento > 0) {
      bytes += generator.text(
        _kv('Descuento:', '-${_money(venta.descuento)}', charsPerLine),
      );
    }

    final igv = venta.comprobanteIgv ?? venta.impuestos;
    bytes += generator.text(
      _kv('$nombreImpuesto:', _money(igv), charsPerLine),
    );

    final icbper = venta.comprobanteIcbper ?? 0;
    if (icbper > 0) {
      bytes += generator.text(
        _kv('ICBPER:', _money(icbper), charsPerLine),
      );
    }

    bytes += generator.hr();

    // ── TOTAL ──
    // fontA bold sin size2 → grande y nítido sin efecto pixelado.
    // El padding se calcula con charsPerLine de fontB pero la línea cabe
    // igual porque fontA es más ancha y el TOTAL es corto.
    // Ojo: aquí cambiamos charsPerLine al ancho de fontA (32 o 48) para
    // que el padding del "TOTAL:" y el monto queden alineados visualmente.
    final charsPerLineFontA = paperWidth == 58 ? 32 : 48;
    bytes += generator.text(
      _kv('TOTAL:', _money(venta.total), charsPerLineFontA),
      styles: const PosStyles(
        fontType: PosFontType.fontA,
      ),
    );
    bytes += generator.setStyles(
      const PosStyles(fontType: PosFontType.fontB),
    );

    // ── Monto en letras ──
    try {
      final enLetras = NumberToWords.convert(venta.total);
      bytes += generator.text(
        'SON: $enLetras',
        styles: const PosStyles(align: PosAlign.center),
      );
    } catch (_) {}

    bytes += generator.hr(ch: '-');

    // ── Pagos ──
    bytes += generator.text('PAGOS');
    if (venta.pagos != null && venta.pagos!.isNotEmpty) {
      for (final p in venta.pagos!) {
        bytes += generator.text(
          _kv(p.metodoPago.label, _money(p.monto), charsPerLine),
        );
      }
    } else if (venta.metodoPagoDisplay != null) {
      bytes += generator.text(
        _kv(venta.metodoPagoDisplay!, _money(venta.total), charsPerLine),
      );
    }
    if (venta.montoRecibido != null) {
      bytes += generator.text(
        _kv('Recibido:', _money(venta.montoRecibido!), charsPerLine),
      );
    }
    if (venta.montoCambio != null && venta.montoCambio! > 0) {
      bytes += generator.text(
        _kv('Cambio:', _money(venta.montoCambio!), charsPerLine),
      );
    }

    bytes += generator.hr(ch: '-');

    // ── QR + enlace consulta SUNAT (solo electrónicos con respuesta) ──
    final qrData = venta.comprobanteCadenaQR ?? venta.comprobanteEnlaceProveedor;
    if (qrData != null && qrData.isNotEmpty) {
      bytes += generator.qrcode(
        qrData,
        size: QRSize.size4,
        cor: QRCorrection.L,
      );
      bytes += generator.feed(1);
    }

    final esElectronico =
        venta.tipoComprobante == 'BOLETA' || venta.tipoComprobante == 'FACTURA';
    if (esElectronico) {
      bytes += generator.text(
        'Representacion impresa de la',
        styles: const PosStyles(align: PosAlign.center),
      );
      bytes += generator.text(
        tituloDoc,
        styles: const PosStyles(align: PosAlign.center),
      );
      if (venta.comprobanteEnlaceProveedor != null &&
          venta.comprobanteEnlaceProveedor!.isNotEmpty) {
        bytes += generator.text(
          'Consulte en:',
          styles: const PosStyles(align: PosAlign.center),
        );
        bytes += generator.text(
          venta.comprobanteEnlaceProveedor!,
          styles: const PosStyles(align: PosAlign.center),
        );
      }
      bytes += generator.feed(1);
    }

    // Pie configurado por la empresa (multi-línea) o texto por defecto.
    final pie = (textoPie?.trim().isNotEmpty ?? false)
        ? textoPie!.trim()
        : 'Gracias por su preferencia!';
    for (final linea in pie.split('\n')) {
      bytes += generator.text(
        _ascii(linea),
        styles: const PosStyles(align: PosAlign.center),
      );
    }

    bytes += generator.feed(3);
    bytes += generator.cut();

    return bytes;
  }

  /// Formatea monto como "S/12.34". Helper para evitar repetir el string.
  static String _money(double v) => 'S/${v.toStringAsFixed(2)}';

  /// Reemplaza caracteres tipográficos fuera de los code pages térmicos
  /// (CP437/CP850) por equivalentes ASCII. Sin esto, un "—" en la
  /// descripción (p.ej. líneas de orden de servicio ya persistidas)
  /// imprime basura o aborta el trabajo de impresión.
  static String _ascii(String s) => s
      .replaceAll('—', '-')
      .replaceAll('–', '-')
      .replaceAll('·', '.')
      .replaceAll('“', '"')
      .replaceAll('”', '"')
      .replaceAll('’', "'")
      .replaceAll('‘', "'")
      .replaceAll('…', '...');

  /// Línea label-valor con padding manual: label left, valor right,
  /// espacios en el medio. Total ocupa exactamente `charsPerLine` chars.
  /// Si label+valor exceden el ancho, recorta el label (preserva el valor).
  static String _kv(String label, String valor, int charsPerLine) {
    final libres = charsPerLine - valor.length;
    if (libres <= 1) {
      // Caso extremo: el valor solo casi llena la línea. Imprimimos
      // label y valor en líneas separadas en lugar de cortar el valor.
      return '$label\n${' ' * (charsPerLine - valor.length)}$valor';
    }
    final labelRecortado = label.length > libres - 1
        ? label.substring(0, libres - 1)
        : label;
    final espacios = charsPerLine - labelRecortado.length - valor.length;
    return labelRecortado + ' ' * espacios + valor;
  }

  /// Mapea el tipo de comprobante al título legible para el ticket.
  static String _nombreTipoComprobante(String? tipo) {
    switch (tipo) {
      case 'BOLETA':
        return 'BOLETA ELECTRONICA';
      case 'FACTURA':
        return 'FACTURA ELECTRONICA';
      case 'NOTA_CREDITO':
        return 'NOTA DE CREDITO';
      case 'NOTA_DEBITO':
        return 'NOTA DE DEBITO';
      case 'TICKET':
        return 'TICKET DE VENTA';
      default:
        return 'TICKET DE VENTA';
    }
  }

  /// Envuelve un texto al ancho dado partiendo por palabras si es posible.
  /// Si una palabra excede el ancho, la corta sin compasión (no hay mejor
  /// opción en una térmica monoespaciada).
  static List<String> _wrapEnAncho(String texto, int ancho) {
    if (texto.length <= ancho) return [texto];
    final out = <String>[];
    final palabras = texto.split(' ');
    var actual = '';
    for (final p in palabras) {
      final candidate = actual.isEmpty ? p : '$actual $p';
      if (candidate.length <= ancho) {
        actual = candidate;
      } else {
        if (actual.isNotEmpty) out.add(actual);
        // Si la palabra sola excede el ancho, partirla
        var rest = p;
        while (rest.length > ancho) {
          out.add(rest.substring(0, ancho));
          rest = rest.substring(ancho);
        }
        actual = rest;
      }
    }
    if (actual.isNotEmpty) out.add(actual);
    return out;
  }
}

/// Anchos de columna para la tabla de detalle, calculados según el ancho
/// del papel. Total cantidad de chars: 32 (58mm) o 48 (80mm) con fontA.
class _ColAnchos {
  final int cant;
  final int desc;
  final int pu;
  final int total;
  final int sepCant;
  final int sepDesc;
  final int sepPu;

  const _ColAnchos({
    required this.cant,
    required this.desc,
    required this.pu,
    required this.total,
    required this.sepCant,
    required this.sepDesc,
    required this.sepPu,
  });

  static _ColAnchos forPaper(int paperWidth) {
    // Con fontB el ancho útil cambia: 42 chars en 58mm, 64 en 80mm.
    if (paperWidth == 58) {
      // 4 + 2 + 18 + 2 + 7 + 2 + 7 = 42
      return const _ColAnchos(
        cant: 4, sepCant: 2, desc: 18, sepDesc: 2, pu: 7, sepPu: 2, total: 7,
      );
    }
    // 80mm = 64 chars: 5 + 3 + 32 + 3 + 9 + 3 + 9 = 64
    return const _ColAnchos(
      cant: 5, sepCant: 3, desc: 32, sepDesc: 3, pu: 9, sepPu: 3, total: 9,
    );
  }

  /// Arma una línea con padding fijo. cant left, desc left, pu y total right.
  String formatear(String cantStr, String descStr, String puStr, String totalStr) {
    final c = _padRight(cantStr, cant);
    final d = _padRight(descStr, desc);
    final p = _padLeft(puStr, pu);
    final t = _padLeft(totalStr, total);
    return '$c${' ' * sepCant}$d${' ' * sepDesc}$p${' ' * sepPu}$t';
  }

  static String _padRight(String s, int n) {
    if (s.length >= n) return s.substring(0, n);
    return s + ' ' * (n - s.length);
  }

  static String _padLeft(String s, int n) {
    if (s.length >= n) return s.substring(s.length - n);
    return ' ' * (n - s.length) + s;
  }
}

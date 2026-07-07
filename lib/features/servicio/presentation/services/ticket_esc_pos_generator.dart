import 'dart:typed_data';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:image/image.dart' as img;
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/utils/logo_termico.dart';
import '../../domain/entities/orden_servicio.dart';

class TicketEscPosGenerator {
  static Future<List<int>> generarTicket({
    required OrdenServicio orden,
    required String empresaNombre,
    String? empresaRazonSocial,
    String? empresaRuc,
    String? empresaDireccion,
    String? empresaTelefono,
    String? sedeNombre,
    Uint8List? logoEmpresa,
    int paperWidth = 80,
    // Términos/pie configurable por la empresa (Configuración de Documentos:
    // textoPieServicio ?? textoPiePagina). null = texto por defecto.
    String? textoPie,
  }) async {
    final profile = await CapabilityProfile.load();
    final paperSize = paperWidth == 58 ? PaperSize.mm58 : PaperSize.mm80;
    final generator = Generator(paperSize, profile);
    List<int> bytes = [];

    // Mismas convenciones visuales que el ticket de venta
    // (ticket_venta_esc_pos_generator.dart):
    //  - reset físico + fontB para todo el cuerpo
    //  - líneas label-valor con padding manual (las térmicas baratas
    //    ignoran el posicionamiento absoluto de Generator.row)
    //  - total final en fontA bold
    bytes += generator.reset();
    bytes += generator.setStyles(
      const PosStyles(fontType: PosFontType.fontB),
    );
    final charsPerLine = paperWidth == 58 ? 42 : 64;
    final charsPerLineFontA = paperWidth == 58 ? 32 : 48;

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

    // ── Encabezado empresa (estilo venta: fontB height x2, sin bold) ──
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
      bytes += generator.text(empresaRazonSocial,
          styles: const PosStyles(align: PosAlign.center));
    }
    if (empresaRuc != null) {
      bytes += generator.text('RUC: $empresaRuc',
          styles: const PosStyles(align: PosAlign.center));
    }
    if (sedeNombre != null) {
      bytes += generator.text('Sede: $sedeNombre',
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

    bytes += generator.hr(ch: '-');

    // ── Tipo y código del documento (estilo venta: centrado, sin bold) ──
    bytes += generator.text(
      'ORDEN DE SERVICIO',
      styles: const PosStyles(align: PosAlign.center),
    );
    bytes += generator.text(
      orden.codigo,
      styles: const PosStyles(align: PosAlign.center),
    );

    bytes += generator.hr(ch: '-');

    // ── Metadata ──
    bytes += generator.text(
      'Fecha: ${DateFormatter.formatDate(orden.creadoEn)}',
    );
    if (orden.cantidadReingresos > 0) {
      bytes += generator.text(
        '*** REINGRESO #${orden.cantidadReingresos} ***',
        styles: const PosStyles(align: PosAlign.center, bold: true),
      );
    }

    bytes += generator.hr(ch: '-');

    // ── Cliente (estilo venta: líneas planas 'Label: valor') ──
    if (orden.cliente != null) {
      bytes += generator.text('CLIENTE');
      bytes += generator.text(
          'Nombre: ${_ascii(orden.cliente!.nombreCompleto)}');
      if (orden.cliente!.documentoNumero != null) {
        bytes += generator.text('Doc: ${orden.cliente!.documentoNumero}');
      }
      if (orden.cliente!.telefono != null) {
        bytes += generator.text('Tel: ${orden.cliente!.telefono}');
      }
      if (orden.cliente!.email != null) {
        bytes += generator.text('Email: ${orden.cliente!.email}');
      }
      bytes += generator.hr(ch: '-');
    }

    // ── Detalle del servicio ──
    bytes += generator.text('DETALLE DEL SERVICIO');
    bytes += generator.text('Tipo: ${_tipoServicioLabel(orden.tipoServicio)}');
    bytes += generator.text('Estado: ${_estadoLabel(orden.estado)}');
    bytes += generator.text('Prioridad: ${orden.prioridad}');
    if (orden.tecnico != null) {
      bytes += generator.text(
          'Tecnico: ${_ascii(orden.tecnico!.nombreParaTicket)}');
    }

    // ── Equipo ──
    if (orden.tipoEquipo != null || orden.marcaEquipo != null || orden.numeroSerie != null) {
      bytes += generator.hr(ch: '-');
      bytes += generator.text('EQUIPO');
      if (orden.tipoEquipo != null) {
        bytes += generator.text('Tipo: ${_ascii(orden.tipoEquipo!)}');
      }
      if (orden.marcaEquipo != null) {
        bytes += generator.text('Marca: ${_ascii(orden.marcaEquipo!)}');
      }
      if (orden.numeroSerie != null) {
        bytes += generator.text('N/Serie: ${orden.numeroSerie}');
      }
      if (orden.condicionEquipo != null) {
        bytes += generator.text('Condicion: ${_ascii(orden.condicionEquipo!)}');
      }
    }

    // ── Datos personalizados ──
    if (orden.datosPersonalizados != null && orden.datosPersonalizados!.isNotEmpty) {
      bytes += generator.hr(ch: '-');
      bytes += generator.text('DATOS ADICIONALES');
      for (final entry in orden.datosPersonalizados!.entries) {
        if (!_isRelevantField(entry.value)) continue;
        final value = _formatFieldValue(entry.value);
        if (value.isEmpty) continue;
        bytes += generator.text('${_ascii(entry.key)}: ${_ascii(value)}');
      }
    }

    // ── Problema ──
    if (orden.descripcionProblema != null) {
      bytes += generator.hr(ch: '-');
      bytes += generator.text('PROBLEMA REPORTADO');
      bytes += generator.text(_ascii(orden.descripcionProblema!));
    }

    // ── Accesorios ──
    if (orden.accesorios != null) {
      bytes += generator.hr(ch: '-');
      bytes += generator.text('ACCESORIOS ENTREGADOS');
      bytes += generator.text(_ascii(_formatAccesorios(orden.accesorios)));
    }

    // ── Componentes ──
    if (orden.componentes != null && orden.componentes!.isNotEmpty) {
      bytes += generator.hr(ch: '-');
      bytes += generator.text('DETALLE DE TRABAJOS');
      for (final comp in orden.componentes!) {
        final nombre = comp.componente?.displayName ?? comp.componenteId;
        final costoTotal = (comp.costoAccion ?? 0) + (comp.costoRepuestos ?? 0);
        bytes += generator.text(_kv(
          _ascii('- $nombre (${comp.tipoAccion})'),
          costoTotal > 0 ? 'S/${costoTotal.toStringAsFixed(2)}' : '',
          charsPerLine,
        ));
        if (comp.descripcionAccion != null && comp.descripcionAccion!.isNotEmpty) {
          bytes += generator.text('  ${_ascii(comp.descripcionAccion!)}');
        }
        if (comp.costoAccion != null || comp.costoRepuestos != null) {
          final parts = <String>[];
          if (comp.costoAccion != null) parts.add('M.O: S/${comp.costoAccion!.toStringAsFixed(2)}');
          if (comp.costoRepuestos != null) parts.add('Rep: S/${comp.costoRepuestos!.toStringAsFixed(2)}');
          bytes += generator.text('  ${parts.join('  ')}');
        }
        if (comp.garantiaMeses != null) {
          bytes += generator.text('  Garantia: ${comp.garantiaMeses} meses');
        }
      }
    }

    // ── Notas ──
    if (orden.notas != null && orden.notas!.isNotEmpty) {
      bytes += generator.hr(ch: '-');
      bytes += generator.text('NOTAS');
      bytes += generator.text(_ascii(orden.notas!));
    }

    // ── Costos ──
    final comps = orden.componentes ?? [];
    double totalMO = 0;
    double totalRep = 0;
    for (final comp in comps) {
      totalMO += comp.costoAccion ?? 0;
      totalRep += comp.costoRepuestos ?? 0;
    }
    final subtotalComp = totalMO + totalRep;
    final hasCosts = subtotalComp > 0 || orden.costoTotal != null;

    if (hasCosts) {
      bytes += generator.hr(ch: '-');
      bytes += generator.text('COSTOS');

      if (totalMO > 0) {
        bytes += generator.text(
            _kv('Mano de obra:', 'S/${totalMO.toStringAsFixed(2)}', charsPerLine));
      }
      if (totalRep > 0) {
        bytes += generator.text(
            _kv('Repuestos:', 'S/${totalRep.toStringAsFixed(2)}', charsPerLine));
      }
      if (totalMO > 0 && totalRep > 0) {
        bytes += generator.text(
            _kv('Subtotal comp.:', 'S/${subtotalComp.toStringAsFixed(2)}', charsPerLine));
      }
      if (orden.costoTotal != null) {
        bytes += generator.text(
            _kv('Costo servicio:', 'S/${orden.costoTotal!.toStringAsFixed(2)}', charsPerLine));
      }
      if (orden.costoTotal != null && subtotalComp > 0) {
        bytes += generator.text(
            _kv('Subtotal:', 'S/${orden.subtotal!.toStringAsFixed(2)}', charsPerLine));
      }
      if (orden.descuento != null && orden.descuento! > 0) {
        bytes += generator.text(
            _kv('Descuento:', '-S/${orden.descuento!.toStringAsFixed(2)}', charsPerLine));
      }

      final costoFinal = orden.costoFinal;
      if (costoFinal != null) {
        bytes += generator.text(
            _kv('Costo final:', 'S/${costoFinal.toStringAsFixed(2)}', charsPerLine));
      }
      if (orden.adelanto != null && orden.adelanto! > 0) {
        final metodo = orden.metodoPagoAdelanto != null ? ' (${orden.metodoPagoAdelanto})' : '';
        bytes += generator.text(
            _kv('Adelanto$metodo:', 'S/${orden.adelanto!.toStringAsFixed(2)}', charsPerLine));
      }

      // Total destacado — mismo tratamiento que el TOTAL del ticket de
      // venta: fontA bold (grande y nítido, sin el pixelado de size2).
      final saldoPendiente = orden.saldoPendiente;
      final labelFinal = saldoPendiente != null
          ? (saldoPendiente <= 0 ? 'PAGADO:' : 'SALDO PENDIENTE:')
          : (orden.costoTotal == null && subtotalComp > 0 ? 'TOTAL:' : null);
      final montoFinal = saldoPendiente != null
          ? (saldoPendiente <= 0 ? 0.0 : saldoPendiente)
          : subtotalComp;
      if (labelFinal != null) {
        bytes += generator.hr();
        bytes += generator.text(
          _kv(labelFinal, 'S/${montoFinal.toStringAsFixed(2)}', charsPerLineFontA),
          styles: const PosStyles(fontType: PosFontType.fontA),
        );
        bytes += generator.setStyles(
          const PosStyles(fontType: PosFontType.fontB),
        );
      }
    }

    // ── QR Code ──
    bytes += generator.hr();
    bytes += generator.feed(1);
    bytes += generator.qrcode(
      '${orden.codigo}|${_estadoLabel(orden.estado)}|${DateFormatter.formatDate(orden.creadoEn)}',
      size: QRSize.size5,
      align: PosAlign.center,
    );
    bytes += generator.feed(1);

    // ── Firma ──
    bytes += generator.hr();
    bytes += generator.feed(3);
    bytes += generator.text(
      '________________________',
      styles: const PosStyles(align: PosAlign.center),
    );
    bytes += generator.text(
      'Firma del cliente',
      styles: const PosStyles(align: PosAlign.center),
    );

    bytes += generator.feed(1);
    // Términos/pie configurados por la empresa (multi-línea) o default.
    final pie = (textoPie?.trim().isNotEmpty ?? false)
        ? textoPie!.trim()
        : 'Gracias por su preferencia';
    for (final linea in pie.split('\n')) {
      bytes += generator.text(
        _ascii(linea),
        styles: const PosStyles(align: PosAlign.center, bold: true),
      );
    }

    bytes += generator.feed(2);
    bytes += generator.cut();

    return bytes;
  }

  // ── Helpers (mismas convenciones que ticket_venta_esc_pos_generator) ──


  /// Línea label-valor con padding manual: label left, valor right.
  /// Las térmicas baratas ignoran el posicionamiento absoluto de
  /// Generator.row — el padding con espacios funciona en todas.
  static String _kv(String label, String valor, int charsPerLine) {
    final maxLabel = charsPerLine - valor.length - 1;
    final lbl = label.length > maxLabel && maxLabel > 0
        ? label.substring(0, maxLabel)
        : label;
    final relleno = charsPerLine - lbl.length - valor.length;
    return '$lbl${' ' * (relleno > 0 ? relleno : 1)}$valor';
  }

  /// Reemplaza caracteres tipográficos fuera de los code pages térmicos
  /// (CP437/CP850) por equivalentes ASCII — un "—" imprime basura o
  /// aborta el trabajo de impresión.
  static String _ascii(String s) => s
      .replaceAll('—', '-')
      .replaceAll('–', '-')
      .replaceAll('·', '.')
      .replaceAll('“', '"')
      .replaceAll('”', '"')
      .replaceAll('’', "'")
      .replaceAll('‘', "'")
      .replaceAll('…', '...');

  static bool _isRelevantField(dynamic value) {
    if (value == null) return false;
    if (value is bool) return false;
    if (value is String) {
      final lower = value.toLowerCase();
      if (lower == 'true' || lower == 'false') return false;
    }
    return true;
  }

  static String _formatFieldValue(dynamic value) {
    if (value == null) return '';
    if (value is Map) {
      return value.entries
          .where((e) => e.value != null && e.value.toString().isNotEmpty)
          .map((e) => '${e.key}: ${e.value}')
          .join(' | ');
    }
    if (value is List) {
      return value.map((e) => _formatFieldValue(e)).join(', ');
    }
    return value.toString();
  }

  static String _formatAccesorios(dynamic accesorios) {
    if (accesorios == null) return '';
    if (accesorios is List) return accesorios.map((e) => e.toString()).join(', ');
    if (accesorios is Map) return accesorios.entries.map((e) => '${e.key}: ${e.value}').join(', ');
    return accesorios.toString();
  }

  static String _tipoServicioLabel(String tipo) {
    const labels = {
      'REPARACION': 'Reparacion',
      'MANTENIMIENTO': 'Mantenimiento',
      'INSTALACION': 'Instalacion',
      'DIAGNOSTICO': 'Diagnostico',
      'ACTUALIZACION': 'Actualizacion',
      'LIMPIEZA': 'Limpieza',
      'RECUPERACION_DATOS': 'Recuperacion de datos',
      'CONFIGURACION': 'Configuracion',
      'CONSULTORIA': 'Consultoria',
      'FORMACION': 'Formacion',
      'SOPORTE': 'Soporte',
    };
    return labels[tipo] ?? tipo;
  }

  static String _estadoLabel(String estado) {
    const labels = {
      'RECIBIDO': 'Recibido',
      'EN_DIAGNOSTICO': 'En Diagnostico',
      'ESPERANDO_APROBACION': 'Esperando Aprobacion',
      'EN_REPARACION': 'En Reparacion',
      'PENDIENTE_PIEZAS': 'Pendiente Piezas',
      'REPARADO': 'Reparado',
      'LISTO_ENTREGA': 'Listo para Entrega',
      'ENTREGADO': 'Entregado',
      'FINALIZADO': 'Finalizado',
      'CANCELADO': 'Cancelado',
    };
    return labels[estado] ?? estado;
  }
}

import 'dart:typed_data';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:image/image.dart' as img;
import '../../../../core/utils/date_formatter.dart';
import '../../domain/entities/orden_servicio.dart';

class TicketEscPosGenerator {
  static Future<List<int>> generarTicket({
    required OrdenServicio orden,
    required String empresaNombre,
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
    List<int> bytes = [];

    // ── Logo ──
    if (logoEmpresa != null) {
      try {
        final decoded = img.decodeImage(logoEmpresa);
        if (decoded != null) {
          final resized = img.copyResize(decoded, width: paperWidth == 58 ? 200 : 300);
          bytes += generator.imageRaster(resized, align: PosAlign.center);
          bytes += generator.feed(1);
        }
      } catch (_) {}
    }

    // ── Header empresa ──
    bytes += generator.text(
      empresaNombre,
      styles: const PosStyles(align: PosAlign.center, bold: true, height: PosTextSize.size2, width: PosTextSize.size1),
    );
    if (sedeNombre != null) {
      bytes += generator.text(sedeNombre, styles: const PosStyles(align: PosAlign.center));
    }
    if (empresaRuc != null) {
      bytes += generator.text('RUC: $empresaRuc', styles: const PosStyles(align: PosAlign.center));
    }
    if (empresaDireccion != null) {
      bytes += generator.text(empresaDireccion, styles: const PosStyles(align: PosAlign.center));
    }
    if (empresaTelefono != null) {
      bytes += generator.text('Tel: $empresaTelefono', styles: const PosStyles(align: PosAlign.center));
    }

    bytes += generator.hr(ch: '=');

    // ── Titulo ──
    bytes += generator.text(
      'ORDEN DE SERVICIO',
      styles: const PosStyles(align: PosAlign.center, bold: true, height: PosTextSize.size2, width: PosTextSize.size1),
    );
    bytes += generator.text(
      orden.codigo,
      styles: const PosStyles(align: PosAlign.center, bold: true),
    );
    bytes += generator.text(
      'Fecha: ${DateFormatter.formatDate(orden.creadoEn)}',
      styles: const PosStyles(align: PosAlign.center),
    );

    if (orden.cantidadReingresos > 0) {
      bytes += generator.text(
        '*** REINGRESO #${orden.cantidadReingresos} ***',
        styles: const PosStyles(align: PosAlign.center, bold: true),
      );
    }

    bytes += generator.hr();

    // ── Cliente ──
    if (orden.cliente != null) {
      bytes += generator.text('CLIENTE', styles: const PosStyles(bold: true));
      bytes += generator.row([
        PosColumn(text: 'Nombre:', width: 4, styles: const PosStyles(bold: true)),
        PosColumn(text: orden.cliente!.nombreCompleto, width: 8),
      ]);
      if (orden.cliente!.documentoNumero != null) {
        bytes += generator.row([
          PosColumn(text: 'Doc:', width: 4, styles: const PosStyles(bold: true)),
          PosColumn(text: orden.cliente!.documentoNumero!, width: 8),
        ]);
      }
      if (orden.cliente!.telefono != null) {
        bytes += generator.row([
          PosColumn(text: 'Tel:', width: 4, styles: const PosStyles(bold: true)),
          PosColumn(text: orden.cliente!.telefono!, width: 8),
        ]);
      }
      if (orden.cliente!.email != null) {
        bytes += generator.row([
          PosColumn(text: 'Email:', width: 4, styles: const PosStyles(bold: true)),
          PosColumn(text: orden.cliente!.email!, width: 8),
        ]);
      }
      bytes += generator.hr();
    }

    // ── Detalle del servicio ──
    bytes += generator.text('DETALLE DEL SERVICIO', styles: const PosStyles(bold: true));
    bytes += generator.row([
      PosColumn(text: 'Tipo:', width: 4, styles: const PosStyles(bold: true)),
      PosColumn(text: _tipoServicioLabel(orden.tipoServicio), width: 8),
    ]);
    bytes += generator.row([
      PosColumn(text: 'Estado:', width: 4, styles: const PosStyles(bold: true)),
      PosColumn(text: _estadoLabel(orden.estado), width: 8),
    ]);
    bytes += generator.row([
      PosColumn(text: 'Prioridad:', width: 4, styles: const PosStyles(bold: true)),
      PosColumn(text: orden.prioridad, width: 8),
    ]);
    if (orden.tecnico != null) {
      bytes += generator.row([
        PosColumn(text: 'Tecnico:', width: 4, styles: const PosStyles(bold: true)),
        PosColumn(text: orden.tecnico!.nombreCompleto, width: 8),
      ]);
    }

    // ── Equipo ──
    if (orden.tipoEquipo != null || orden.marcaEquipo != null || orden.numeroSerie != null) {
      bytes += generator.hr();
      bytes += generator.text('EQUIPO', styles: const PosStyles(bold: true));
      if (orden.tipoEquipo != null) {
        bytes += generator.row([
          PosColumn(text: 'Tipo:', width: 4, styles: const PosStyles(bold: true)),
          PosColumn(text: orden.tipoEquipo!, width: 8),
        ]);
      }
      if (orden.marcaEquipo != null) {
        bytes += generator.row([
          PosColumn(text: 'Marca:', width: 4, styles: const PosStyles(bold: true)),
          PosColumn(text: orden.marcaEquipo!, width: 8),
        ]);
      }
      if (orden.numeroSerie != null) {
        bytes += generator.row([
          PosColumn(text: 'N/Serie:', width: 4, styles: const PosStyles(bold: true)),
          PosColumn(text: orden.numeroSerie!, width: 8),
        ]);
      }
      if (orden.condicionEquipo != null) {
        bytes += generator.row([
          PosColumn(text: 'Condicion:', width: 4, styles: const PosStyles(bold: true)),
          PosColumn(text: orden.condicionEquipo!, width: 8),
        ]);
      }
    }

    // ── Datos personalizados ──
    if (orden.datosPersonalizados != null && orden.datosPersonalizados!.isNotEmpty) {
      bytes += generator.hr();
      bytes += generator.text('DATOS ADICIONALES', styles: const PosStyles(bold: true));
      for (final entry in orden.datosPersonalizados!.entries) {
        if (!_isRelevantField(entry.value)) continue;
        final value = _formatFieldValue(entry.value);
        if (value.isEmpty) continue;
        bytes += generator.row([
          PosColumn(text: '${entry.key}:', width: 4, styles: const PosStyles(bold: true)),
          PosColumn(text: value, width: 8),
        ]);
      }
    }

    // ── Problema ──
    if (orden.descripcionProblema != null) {
      bytes += generator.hr();
      bytes += generator.text('PROBLEMA REPORTADO', styles: const PosStyles(bold: true));
      bytes += generator.text(orden.descripcionProblema!);
    }

    // ── Accesorios ──
    if (orden.accesorios != null) {
      bytes += generator.hr();
      bytes += generator.text('ACCESORIOS ENTREGADOS', styles: const PosStyles(bold: true));
      bytes += generator.text(_formatAccesorios(orden.accesorios));
    }

    // ── Componentes ──
    if (orden.componentes != null && orden.componentes!.isNotEmpty) {
      bytes += generator.hr();
      bytes += generator.text('DETALLE DE TRABAJOS', styles: const PosStyles(bold: true));
      for (final comp in orden.componentes!) {
        final nombre = comp.componente?.displayName ?? comp.componenteId;
        final costoTotal = (comp.costoAccion ?? 0) + (comp.costoRepuestos ?? 0);
        bytes += generator.row([
          PosColumn(text: '- $nombre (${comp.tipoAccion})', width: 8, styles: const PosStyles(bold: true)),
          PosColumn(
            text: costoTotal > 0 ? 'S/ ${costoTotal.toStringAsFixed(2)}' : '',
            width: 4,
            styles: const PosStyles(align: PosAlign.right, bold: true),
          ),
        ]);
        if (comp.descripcionAccion != null && comp.descripcionAccion!.isNotEmpty) {
          bytes += generator.text('  ${comp.descripcionAccion!}');
        }
        if (comp.costoAccion != null || comp.costoRepuestos != null) {
          final parts = <String>[];
          if (comp.costoAccion != null) parts.add('M.O: S/ ${comp.costoAccion!.toStringAsFixed(2)}');
          if (comp.costoRepuestos != null) parts.add('Rep: S/ ${comp.costoRepuestos!.toStringAsFixed(2)}');
          bytes += generator.text('  ${parts.join('  ')}');
        }
        if (comp.garantiaMeses != null) {
          bytes += generator.text('  Garantia: ${comp.garantiaMeses} meses');
        }
      }
    }

    // ── Notas ──
    if (orden.notas != null && orden.notas!.isNotEmpty) {
      bytes += generator.hr();
      bytes += generator.text('NOTAS', styles: const PosStyles(bold: true));
      bytes += generator.text(orden.notas!);
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
      bytes += generator.hr(ch: '=');
      bytes += generator.text('COSTOS', styles: const PosStyles(bold: true));

      if (totalMO > 0) {
        bytes += _costLine(generator, 'Mano de obra', 'S/ ${totalMO.toStringAsFixed(2)}');
      }
      if (totalRep > 0) {
        bytes += _costLine(generator, 'Repuestos', 'S/ ${totalRep.toStringAsFixed(2)}');
      }
      if (totalMO > 0 && totalRep > 0) {
        bytes += _costLine(generator, 'Subtotal comp.', 'S/ ${subtotalComp.toStringAsFixed(2)}');
      }
      if (orden.costoTotal != null) {
        bytes += _costLine(generator, 'Costo servicio', 'S/ ${orden.costoTotal!.toStringAsFixed(2)}');
      }
      if (orden.costoTotal != null && subtotalComp > 0) {
        bytes += _costLine(generator, 'Subtotal', 'S/ ${orden.subtotal!.toStringAsFixed(2)}', bold: true);
      }
      if (orden.descuento != null && orden.descuento! > 0) {
        bytes += _costLine(generator, 'Descuento', '- S/ ${orden.descuento!.toStringAsFixed(2)}');
      }

      final costoFinal = orden.costoFinal;
      if (costoFinal != null) {
        bytes += _costLine(generator, 'COSTO FINAL', 'S/ ${costoFinal.toStringAsFixed(2)}', bold: true);
      }
      if (orden.adelanto != null && orden.adelanto! > 0) {
        final metodo = orden.metodoPagoAdelanto != null ? ' (${orden.metodoPagoAdelanto})' : '';
        bytes += _costLine(generator, 'Adelanto$metodo', 'S/ ${orden.adelanto!.toStringAsFixed(2)}');
      }

      final saldoPendiente = orden.saldoPendiente;
      if (saldoPendiente != null) {
        bytes += generator.hr();
        bytes += generator.row([
          PosColumn(
            text: saldoPendiente <= 0 ? 'PAGADO' : 'SALDO PENDIENTE',
            width: 7,
            styles: const PosStyles(bold: true, height: PosTextSize.size2, width: PosTextSize.size1),
          ),
          PosColumn(
            text: 'S/ ${saldoPendiente <= 0 ? "0.00" : saldoPendiente.toStringAsFixed(2)}',
            width: 5,
            styles: const PosStyles(align: PosAlign.right, bold: true, height: PosTextSize.size2, width: PosTextSize.size1),
          ),
        ]);
      } else if (orden.costoTotal == null && subtotalComp > 0) {
        bytes += generator.hr();
        bytes += generator.row([
          PosColumn(text: 'TOTAL', width: 7, styles: const PosStyles(bold: true, height: PosTextSize.size2, width: PosTextSize.size1)),
          PosColumn(
            text: 'S/ ${subtotalComp.toStringAsFixed(2)}',
            width: 5,
            styles: const PosStyles(align: PosAlign.right, bold: true, height: PosTextSize.size2, width: PosTextSize.size1),
          ),
        ]);
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
    bytes += generator.text(
      'Gracias por su preferencia',
      styles: const PosStyles(align: PosAlign.center, bold: true),
    );

    bytes += generator.feed(2);
    bytes += generator.cut();

    return bytes;
  }

  // ── Helpers ──

  static List<int> _costLine(Generator gen, String label, String value, {bool bold = false}) {
    return gen.row([
      PosColumn(text: label, width: 7, styles: PosStyles(bold: bold)),
      PosColumn(text: value, width: 5, styles: PosStyles(align: PosAlign.right, bold: bold)),
    ]);
  }

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

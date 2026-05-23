import '../../domain/entities/caja_auditoria.dart';
import '../../domain/entities/movimiento_caja.dart';
import '../../domain/entities/resumen_caja.dart';
import 'arqueo_caja_model.dart';
import 'caja_model.dart';
import 'cierre_caja_model.dart';

class CajaAuditoriaModel extends CajaAuditoria {
  const CajaAuditoriaModel({
    required super.caja,
    required super.resumenActual,
    super.cierre,
    required super.arqueos,
    required super.movimientos,
  });

  factory CajaAuditoriaModel.fromJson(Map<String, dynamic> json) {
    final cajaJson = Map<String, dynamic>.from(json['caja'] as Map);
    // El cierre viene en json['cierre'] (top-level del response). El CajaModel
    // de listados tiene `cierre` en la caja; replicamos esa convención.
    final cierreJson = json['cierre'] as Map<String, dynamic>?;
    if (cierreJson != null) {
      cajaJson['cierre'] = cierreJson;
    }
    final caja = CajaModel.fromJson(cajaJson);

    final resumenJson = json['resumenActual'] as Map<String, dynamic>;
    final detallesJson = (resumenJson['detallesPorMetodo'] as List?) ?? const [];
    final detalles = detallesJson
        .whereType<Map<String, dynamic>>()
        .map((d) => DetalleMetodoCaja(
              metodoPago: MetodoPago.fromString(d['metodoPago'] as String),
              apertura: _toDouble(d['apertura']),
              ingresos: _toDouble(d['ingresos']),
              egresos: _toDouble(d['egresos']),
              saldo: _toDouble(d['saldo']),
            ))
        .toList();

    final egresosCatJson =
        (resumenJson['egresosPorCategoria'] as List?) ?? const [];
    final egresosPorCategoria = egresosCatJson
        .whereType<Map<String, dynamic>>()
        .map((m) => EgresoPorCategoria(
              categoria: m['categoria']?.toString() ?? '',
              label: m['label']?.toString() ??
                  m['categoria']?.toString() ??
                  '',
              total: _toDouble(m['total']),
              cantidad: (m['cantidad'] as int?) ?? 0,
            ))
        .toList();

    final resumenActual = ResumenActualCaja(
      montoApertura: _toDouble(resumenJson['montoApertura']),
      totalIngresos: _toDouble(resumenJson['totalIngresos']),
      totalEgresos: _toDouble(resumenJson['totalEgresos']),
      saldoActual: _toDouble(resumenJson['saldoActual']),
      saldoEfectivo: _toDouble(resumenJson['saldoEfectivo']),
      detallesPorMetodo: detalles,
      egresoAnulacionVenta: _toDouble(resumenJson['egresoAnulacionVenta']),
      cantidadAnulaciones: (resumenJson['cantidadAnulaciones'] as int?) ?? 0,
      egresosPorCategoria: egresosPorCategoria,
    );

    final arqueosJson = (json['arqueos'] as List?) ?? const [];
    final arqueos = arqueosJson
        .whereType<Map<String, dynamic>>()
        .map(ArqueoCajaModel.fromJson)
        .toList();

    final movsJson = (json['movimientos'] as List?) ?? const [];
    final movimientos = movsJson
        .whereType<Map<String, dynamic>>()
        .map(_parseMovimiento)
        .toList();

    return CajaAuditoriaModel(
      caja: caja,
      resumenActual: resumenActual,
      cierre: cierreJson != null ? CierreCajaModel.fromJson(cierreJson) : null,
      arqueos: arqueos,
      movimientos: movimientos,
    );
  }

  static MovimientoAuditoria _parseMovimiento(Map<String, dynamic> json) {
    final venta = json['venta'] as Map<String, dynamic>?;
    final pedido = json['pedido'] as Map<String, dynamic>?;
    final categoriaGasto = json['categoriaGasto'] as Map<String, dynamic>?;
    final anuladoPor = json['anuladoPor'] as Map<String, dynamic>?;

    String? anuladoPorNombre;
    if (anuladoPor != null) {
      final persona = anuladoPor['persona'] as Map<String, dynamic>?;
      if (persona != null) {
        final nombre =
            '${persona['nombres'] ?? ''} ${persona['apellidos'] ?? ''}'.trim();
        if (nombre.isNotEmpty) anuladoPorNombre = nombre;
      }
    }

    return MovimientoAuditoria(
      id: json['id'] as String,
      cajaId: json['cajaId'] as String,
      tipo: TipoMovimientoCaja.fromString(json['tipo'] as String),
      categoria: CategoriaMovimientoCaja.fromString(json['categoria'] as String),
      metodoPago: MetodoPago.fromString(json['metodoPago'] as String),
      monto: _toDouble(json['monto']),
      descripcion: json['descripcion'] as String?,
      categoriaGastoId: json['categoriaGastoId'] as String? ??
          categoriaGasto?['id'] as String?,
      categoriaGastoNombre: categoriaGasto?['nombre'] as String?,
      esManual: json['esManual'] as bool? ?? false,
      fechaMovimiento: DateTime.parse(json['fechaMovimiento'] as String),
      ventaId: venta?['id'] as String? ?? json['ventaId'] as String?,
      ventaCodigo: venta?['codigo'] as String? ?? json['ventaCodigo'] as String?,
      pedidoCodigo: pedido?['codigo'] as String?,
      anulado: json['anulado'] as bool? ?? false,
      motivoAnulacion: json['motivoAnulacion'] as String?,
      esContrapartida: json['esContrapartida'] as bool? ?? false,
      anuladoPorNombre: anuladoPorNombre,
    );
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }
}

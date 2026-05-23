import '../../domain/entities/movimiento_caja.dart';
import '../../domain/entities/resumen_caja.dart';

class ResumenMetodoPagoModel extends ResumenMetodoPago {
  const ResumenMetodoPagoModel({
    required super.metodoPago,
    required super.totalIngresos,
    required super.totalEgresos,
    required super.saldo,
  });

  factory ResumenMetodoPagoModel.fromJson(Map<String, dynamic> json) {
    return ResumenMetodoPagoModel(
      metodoPago: MetodoPago.fromString(json['metodoPago'] as String),
      totalIngresos: _toDouble(json['totalIngresos']),
      totalEgresos: _toDouble(json['totalEgresos']),
      saldo: _toDouble(json['saldo']),
    );
  }

  ResumenMetodoPago toEntity() => this;

  static double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }
}

class ResumenCajaModel extends ResumenCaja {
  const ResumenCajaModel({
    required super.totalIngresos,
    required super.totalEgresos,
    required super.saldo,
    required super.saldoEfectivo,
    required super.detalles,
    super.egresoAnulacionVenta,
    super.cantidadAnulaciones,
    super.egresosPorCategoria,
  });

  factory ResumenCajaModel.fromJson(Map<String, dynamic> json) {
    final detallesJson = json['detalles'] as List? ?? [];
    final detalles = detallesJson
        .map((e) =>
            ResumenMetodoPagoModel.fromJson(e as Map<String, dynamic>))
        .toList();

    // Fallback: si el backend aun no expone saldoEfectivo (deploy en curso),
    // derivamos del detalle EFECTIVO; si tampoco hay, cae a 0.
    final saldoEfectivoBackend = json['saldoEfectivo'];
    final saldoEfectivo = saldoEfectivoBackend != null
        ? _toDouble(saldoEfectivoBackend)
        : detalles
            .firstWhere(
              (d) => d.metodoPago == MetodoPago.efectivo,
              orElse: () => const ResumenMetodoPagoModel(
                metodoPago: MetodoPago.efectivo,
                totalIngresos: 0,
                totalEgresos: 0,
                saldo: 0,
              ),
            )
            .saldo;

    final egresosCatJson = json['egresosPorCategoria'] as List? ?? [];
    final egresosPorCategoria = egresosCatJson
        .map((e) {
          final m = e as Map<String, dynamic>;
          return EgresoPorCategoria(
            categoria: m['categoria']?.toString() ?? '',
            label: m['label']?.toString() ?? m['categoria']?.toString() ?? '',
            total: _toDouble(m['total']),
            cantidad: (m['cantidad'] as int?) ?? 0,
          );
        })
        .toList();

    return ResumenCajaModel(
      totalIngresos: _toDouble(json['totalIngresos']),
      totalEgresos: _toDouble(json['totalEgresos']),
      saldo: _toDouble(json['saldo']),
      saldoEfectivo: saldoEfectivo,
      detalles: detalles,
      egresoAnulacionVenta: _toDouble(json['egresoAnulacionVenta']),
      cantidadAnulaciones: (json['cantidadAnulaciones'] as int?) ?? 0,
      egresosPorCategoria: egresosPorCategoria,
    );
  }

  ResumenCaja toEntity() => this;

  static double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }
}

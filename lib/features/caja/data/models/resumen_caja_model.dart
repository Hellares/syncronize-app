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
    required super.detalles,
  });

  factory ResumenCajaModel.fromJson(Map<String, dynamic> json) {
    final detallesJson = json['detalles'] as List? ?? [];
    final detalles = detallesJson
        .map((e) =>
            ResumenMetodoPagoModel.fromJson(e as Map<String, dynamic>))
        .toList();

    return ResumenCajaModel(
      totalIngresos: _toDouble(json['totalIngresos']),
      totalEgresos: _toDouble(json['totalEgresos']),
      saldo: _toDouble(json['saldo']),
      detalles: detalles,
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

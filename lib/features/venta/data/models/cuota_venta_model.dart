import '../../domain/entities/cuota_venta.dart';

class CuotaVentaModel extends CuotaVenta {
  const CuotaVentaModel({
    required super.id,
    required super.ventaId,
    required super.numero,
    required super.monto,
    required super.montoPagado,
    required super.saldoPendiente,
    required super.fechaVencimiento,
    required super.estado,
    super.montoMora,
    super.diasVencido,
    super.montoPrincipal,
    super.montoInteresCuota,
    super.montoPagadoPrincipal,
    super.montoPagadoInteres,
    super.montoPagadoMora,
  });

  factory CuotaVentaModel.fromJson(Map<String, dynamic> json) {
    return CuotaVentaModel(
      id: json['id'] as String,
      ventaId: json['ventaId'] as String? ?? '',
      numero: json['numero'] as int? ?? 0,
      monto: _toDouble(json['monto']),
      montoPagado: _toDouble(json['montoPagado']),
      saldoPendiente: _toDouble(json['saldoPendiente']),
      fechaVencimiento: DateTime.parse(json['fechaVencimiento'] as String),
      estado: json['estado'] as String? ?? 'PENDIENTE',
      montoMora: _toDouble(json['montoMora']),
      diasVencido: json['diasVencido'] as int? ?? 0,
      montoPrincipal: _toDouble(json['montoPrincipal']),
      montoInteresCuota: _toDouble(json['montoInteresCuota']),
      montoPagadoPrincipal: _toDouble(json['montoPagadoPrincipal']),
      montoPagadoInteres: _toDouble(json['montoPagadoInteres']),
      montoPagadoMora: _toDouble(json['montoPagadoMora']),
    );
  }

  CuotaVenta toEntity() => this;

  static double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }
}

import '../../domain/entities/pago_venta.dart';
import '../../domain/entities/venta.dart';

class PagoVentaModel extends PagoVenta {
  const PagoVentaModel({
    required super.id,
    required super.ventaId,
    required super.metodoPago,
    required super.monto,
    super.referencia,
    required super.fechaPago,
    super.monedaOriginal,
    super.montoOriginal,
    super.tipoCambio,
  });

  factory PagoVentaModel.fromJson(Map<String, dynamic> json) {
    return PagoVentaModel(
      id: json['id'] as String,
      ventaId: json['ventaId'] as String,
      metodoPago: MetodoPago.fromString(json['metodoPago'] as String),
      monto: _toDouble(json['monto']),
      referencia: json['referencia'] as String?,
      fechaPago: DateTime.parse(json['fechaPago'] as String),
      monedaOriginal: json['monedaOriginal'] as String?,
      montoOriginal: json['montoOriginal'] != null ? _toDouble(json['montoOriginal']) : null,
      tipoCambio: json['tipoCambio'] != null ? _toDouble(json['tipoCambio']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ventaId': ventaId,
      'metodoPago': metodoPago.apiValue,
      'monto': monto,
      if (referencia != null) 'referencia': referencia,
      'fechaPago': fechaPago.toIso8601String(),
    };
  }

  PagoVenta toEntity() => this;

  static double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }
}

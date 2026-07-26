import '../../../../core/utils/date_formatter.dart';
import '../../domain/entities/pago_venta.dart';
import '../../domain/entities/venta.dart';

class PagoVentaModel extends PagoVenta {
  const PagoVentaModel({
    required super.id,
    required super.ventaId,
    required super.metodoPago,
    required super.monto,
    super.referencia,
    super.banco,
    required super.fechaPago,
    super.monedaOriginal,
    super.montoOriginal,
    super.tipoCambio,
    super.cuotaVentaId,
    super.montoPrincipal,
    super.montoInteres,
    super.montoMora,
    super.anulado,
    super.fuente,
  });

  factory PagoVentaModel.fromJson(Map<String, dynamic> json) {
    return PagoVentaModel(
      id: json['id'] as String,
      ventaId: json['ventaId'] as String,
      metodoPago: MetodoPago.fromString(json['metodoPago'] as String),
      monto: _toDouble(json['monto']),
      referencia: json['referencia'] as String?,
      banco: json['banco'] as String?,
      fechaPago: DateTime.parse(json['fechaPago'] as String),
      monedaOriginal: json['monedaOriginal'] as String?,
      montoOriginal: json['montoOriginal'] != null ? _toDouble(json['montoOriginal']) : null,
      tipoCambio: json['tipoCambio'] != null ? _toDouble(json['tipoCambio']) : null,
      cuotaVentaId: json['cuotaVentaId'] as String?,
      montoPrincipal: _toDouble(json['montoPrincipal']),
      montoInteres: _toDouble(json['montoInteres']),
      montoMora: _toDouble(json['montoMora']),
      anulado: json['anulado'] as bool? ?? false,
      fuente: json['fuente'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ventaId': ventaId,
      'metodoPago': metodoPago.apiValue,
      'monto': monto,
      if (referencia != null) 'referencia': referencia,
      if (banco != null) 'banco': banco,
      'fechaPago': DateFormatter.toUtcIso(fechaPago),
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

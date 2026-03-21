import '../../domain/entities/movimiento_caja.dart';

class MovimientoCajaModel extends MovimientoCaja {
  const MovimientoCajaModel({
    required super.id,
    required super.cajaId,
    required super.tipo,
    required super.categoria,
    required super.metodoPago,
    required super.monto,
    super.descripcion,
    super.categoriaGastoId,
    super.categoriaGastoNombre,
    super.esManual,
    required super.fechaMovimiento,
    super.ventaCodigo,
    super.pedidoCodigo,
    super.anulado,
    super.motivoAnulacion,
  });

  factory MovimientoCajaModel.fromJson(Map<String, dynamic> json) {
    final venta = json['venta'] as Map<String, dynamic>?;
    final pedido = json['pedido'] as Map<String, dynamic>?;
    final categoriaGasto = json['categoriaGasto'] as Map<String, dynamic>?;

    return MovimientoCajaModel(
      id: json['id'] as String,
      cajaId: json['cajaId'] as String,
      tipo: TipoMovimientoCaja.fromString(json['tipo'] as String),
      categoria:
          CategoriaMovimientoCaja.fromString(json['categoria'] as String),
      metodoPago: MetodoPago.fromString(json['metodoPago'] as String),
      monto: _toDouble(json['monto']),
      descripcion: json['descripcion'] as String?,
      categoriaGastoId: json['categoriaGastoId'] as String? ?? categoriaGasto?['id'] as String?,
      categoriaGastoNombre: categoriaGasto?['nombre'] as String?,
      esManual: json['esManual'] as bool? ?? false,
      fechaMovimiento: DateTime.parse(json['fechaMovimiento'] as String),
      ventaCodigo: venta?['codigo'] as String? ?? json['ventaCodigo'] as String?,
      pedidoCodigo:
          pedido?['codigo'] as String? ?? json['pedidoCodigo'] as String?,
      anulado: json['anulado'] as bool? ?? false,
      motivoAnulacion: json['motivoAnulacion'] as String?,
    );
  }

  MovimientoCaja toEntity() => this;

  static double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }
}

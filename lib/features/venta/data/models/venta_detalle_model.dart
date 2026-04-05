import '../../domain/entities/venta_detalle.dart';

class VentaDetalleModel extends VentaDetalle {
  const VentaDetalleModel({
    required super.id,
    required super.ventaId,
    super.productoId,
    super.varianteId,
    super.servicioId,
    super.comboId,
    required super.descripcion,
    required super.cantidad,
    required super.precioUnitario,
    super.descuento,
    super.tipoAfectacion,
    super.porcentajeIGV,
    super.igv,
    super.icbper,
    required super.subtotal,
    required super.total,
    super.orden,
    super.productoNombre,
    super.productoCodigo,
    super.varianteNombre,
    super.varianteSku,
    super.servicioNombre,
    super.servicioCodigo,
  });

  factory VentaDetalleModel.fromJson(Map<String, dynamic> json) {
    final producto = json['producto'] as Map<String, dynamic>?;
    final variante = json['variante'] as Map<String, dynamic>?;
    final servicio = json['servicio'] as Map<String, dynamic>?;

    return VentaDetalleModel(
      id: json['id'] as String,
      ventaId: json['ventaId'] as String,
      productoId: json['productoId'] as String?,
      varianteId: json['varianteId'] as String?,
      servicioId: json['servicioId'] as String?,
      comboId: json['comboId'] as String?,
      descripcion: json['descripcion'] as String,
      cantidad: _toDouble(json['cantidad']),
      precioUnitario: _toDouble(json['precioUnitario']),
      descuento: _toDouble(json['descuento'] ?? 0),
      tipoAfectacion: json['tipoAfectacion'] as String? ?? '10',
      porcentajeIGV: _toDouble(json['porcentajeIGV'] ?? 18),
      igv: _toDouble(json['igv'] ?? 0),
      icbper: _toDouble(json['icbper'] ?? 0),
      subtotal: _toDouble(json['subtotal']),
      total: _toDouble(json['total']),
      orden: json['orden'] as int? ?? 0,
      productoNombre: producto?['nombre'] as String?,
      productoCodigo: producto?['codigoEmpresa'] as String?,
      varianteNombre: variante?['nombre'] as String?,
      varianteSku: variante?['sku'] as String?,
      servicioNombre: servicio?['nombre'] as String?,
      servicioCodigo: servicio?['codigoEmpresa'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ventaId': ventaId,
      if (productoId != null) 'productoId': productoId,
      if (varianteId != null) 'varianteId': varianteId,
      if (servicioId != null) 'servicioId': servicioId,
      if (comboId != null) 'comboId': comboId,
      'descripcion': descripcion,
      'cantidad': cantidad,
      'precioUnitario': precioUnitario,
      'descuento': descuento,
      'porcentajeIGV': porcentajeIGV,
      'igv': igv,
      'subtotal': subtotal,
      'total': total,
      'orden': orden,
    };
  }

  Map<String, dynamic> toCreateJson() {
    return {
      if (productoId != null) 'productoId': productoId,
      if (varianteId != null) 'varianteId': varianteId,
      if (servicioId != null) 'servicioId': servicioId,
      if (comboId != null) 'comboId': comboId,
      'descripcion': descripcion,
      'cantidad': cantidad,
      'precioUnitario': precioUnitario,
      if (descuento > 0) 'descuento': descuento,
      'porcentajeIGV': porcentajeIGV,
    };
  }

  VentaDetalle toEntity() => this;

  static double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }
}

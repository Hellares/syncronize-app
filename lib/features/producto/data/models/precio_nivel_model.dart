import '../../domain/entities/precio_nivel.dart';

class PrecioNivelModel extends PrecioNivel {
  const PrecioNivelModel({
    required super.id,
    super.productoId,
    super.varianteId,
    required super.nombre,
    required super.cantidadMinima,
    super.cantidadMaxima,
    required super.tipoPrecio,
    super.precio,
    super.porcentajeDesc,
    super.descripcion,
    required super.orden,
    required super.isActive,
    required super.creadoEn,
    required super.actualizadoEn,
  });

  factory PrecioNivelModel.fromJson(Map<String, dynamic> json) {
    return PrecioNivelModel(
      id: json['id'] as String? ?? '',
      productoId: json['productoId'] as String?,
      varianteId: json['varianteId'] as String?,
      nombre: json['nombre'] as String? ?? '',
      cantidadMinima: _toInt(json['cantidadMinima']),
      cantidadMaxima: json['cantidadMaxima'] != null
          ? _toInt(json['cantidadMaxima'])
          : null,
      tipoPrecio: TipoPrecioNivel.fromString(
        json['tipoPrecio'] as String? ?? 'PRECIO_FIJO',
      ),
      precio: json['precio'] != null ? _toDouble(json['precio']) : null,
      porcentajeDesc: json['porcentajeDesc'] != null
          ? _toDouble(json['porcentajeDesc'])
          : null,
      descripcion: json['descripcion'] as String?,
      orden: _toInt(json['orden']),
      isActive: json['isActive'] as bool? ?? true,
      creadoEn: json['creadoEn'] != null
          ? DateTime.parse(json['creadoEn'] as String)
          : DateTime.now(),
      actualizadoEn: json['actualizadoEn'] != null
          ? DateTime.parse(json['actualizadoEn'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (productoId != null) 'productoId': productoId,
      if (varianteId != null) 'varianteId': varianteId,
      'nombre': nombre,
      'cantidadMinima': cantidadMinima,
      if (cantidadMaxima != null) 'cantidadMaxima': cantidadMaxima,
      'tipoPrecio': tipoPrecio.value,
      if (precio != null) 'precio': precio,
      if (porcentajeDesc != null) 'porcentajeDesc': porcentajeDesc,
      if (descripcion != null) 'descripcion': descripcion,
      'orden': orden,
      'isActive': isActive,
      'creadoEn': creadoEn.toIso8601String(),
      'actualizadoEn': actualizadoEn.toIso8601String(),
    };
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  static int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}

class CalculoPrecioResultModel extends CalculoPrecioResult {
  const CalculoPrecioResultModel({
    required super.precioUnitario,
    required super.nivelAplicado,
    required super.descuentoAplicado,
    required super.precioBase,
  });

  factory CalculoPrecioResultModel.fromJson(Map<String, dynamic> json) {
    return CalculoPrecioResultModel(
      precioUnitario: _toDouble(json['precioUnitario']),
      nivelAplicado: json['nivelAplicado'] as String? ?? 'Precio base',
      descuentoAplicado: _toDouble(json['descuentoAplicado']),
      precioBase: _toDouble(json['precioBase']),
    );
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}

/// DTO para crear/actualizar precio nivel
class PrecioNivelDto {
  final String nombre;
  final int cantidadMinima;
  final int? cantidadMaxima;
  final TipoPrecioNivel tipoPrecio;
  final double? precio;
  final double? porcentajeDesc;
  final String? descripcion;
  final int? orden;

  const PrecioNivelDto({
    required this.nombre,
    required this.cantidadMinima,
    this.cantidadMaxima,
    required this.tipoPrecio,
    this.precio,
    this.porcentajeDesc,
    this.descripcion,
    this.orden,
  });

  Map<String, dynamic> toJson() {
    return {
      'nombre': nombre,
      'cantidadMinima': cantidadMinima,
      if (cantidadMaxima != null) 'cantidadMaxima': cantidadMaxima,
      'tipoPrecio': tipoPrecio.value,
      if (precio != null) 'precio': precio,
      if (porcentajeDesc != null) 'porcentajeDesc': porcentajeDesc,
      if (descripcion != null) 'descripcion': descripcion,
      if (orden != null) 'orden': orden,
    };
  }
}

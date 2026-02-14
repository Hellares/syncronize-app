import 'package:syncronize/core/utils/type_converters.dart';
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
    final id = json['id'] as String?;
    final nombre = json['nombre'] as String?;
    final tipoPrecio = json['tipoPrecio'] as String?;
    if (id == null || id.isEmpty) {
      throw FormatException('PrecioNivel: campo "id" es requerido', json);
    }
    if (nombre == null || nombre.isEmpty) {
      throw FormatException('PrecioNivel: campo "nombre" es requerido', json);
    }
    if (tipoPrecio == null || tipoPrecio.isEmpty) {
      throw FormatException('PrecioNivel: campo "tipoPrecio" es requerido', json);
    }

    return PrecioNivelModel(
      id: id,
      productoId: json['productoId'] as String?,
      varianteId: json['varianteId'] as String?,
      nombre: nombre,
      cantidadMinima: toSafeInt(json['cantidadMinima']),
      cantidadMaxima: json['cantidadMaxima'] != null
          ? toSafeInt(json['cantidadMaxima'])
          : null,
      tipoPrecio: TipoPrecioNivel.fromString(tipoPrecio),
      precio: json['precio'] != null ? toSafeDouble(json['precio']) : null,
      porcentajeDesc: json['porcentajeDesc'] != null
          ? toSafeDouble(json['porcentajeDesc'])
          : null,
      descripcion: json['descripcion'] as String?,
      orden: toSafeInt(json['orden']),
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
      precioUnitario: toSafeDouble(json['precioUnitario']),
      nivelAplicado: json['nivelAplicado'] as String? ?? 'Precio base',
      descuentoAplicado: toSafeDouble(json['descuentoAplicado']),
      precioBase: toSafeDouble(json['precioBase']),
    );
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

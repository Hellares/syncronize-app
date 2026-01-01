import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/configuracion_precio.dart';
import '../../domain/entities/precio_nivel.dart';

part 'configuracion_precio_model.g.dart';

/// Converter para el enum TipoPrecioNivel
class TipoPrecioNivelConverter implements JsonConverter<TipoPrecioNivel, String> {
  const TipoPrecioNivelConverter();

  @override
  TipoPrecioNivel fromJson(String json) => TipoPrecioNivel.fromString(json);

  @override
  String toJson(TipoPrecioNivel object) => object.value;
}

@JsonSerializable(explicitToJson: true)
class ConfiguracionPrecioModel extends ConfiguracionPrecio {
  @override
  @JsonKey(name: 'niveles')
  // ignore: overridden_fields
  final List<ConfiguracionPrecioNivelModel> niveles;

  const ConfiguracionPrecioModel({
    required super.id,
    required super.empresaId,
    required super.nombre,
    super.descripcion,
    required super.isActive,
    required this.niveles,
    required super.creadoEn,
    required super.actualizadoEn,
    super.cantidadProductosUsando,
  }) : super(niveles: niveles);

  factory ConfiguracionPrecioModel.fromJson(Map<String, dynamic> json) =>
      _$ConfiguracionPrecioModelFromJson(json);

  Map<String, dynamic> toJson() => _$ConfiguracionPrecioModelToJson(this);
}

@JsonSerializable()
class ConfiguracionPrecioNivelModel extends ConfiguracionPrecioNivel {
  @override
  @TipoPrecioNivelConverter()
  // ignore: overridden_fields
  final TipoPrecioNivel tipoPrecio;

  const ConfiguracionPrecioNivelModel({
    required super.id,
    required super.nombre,
    required super.cantidadMinima,
    super.cantidadMaxima,
    required this.tipoPrecio,
    super.porcentajeDesc,
    super.descripcion,
    required super.orden,
  }) : super(tipoPrecio: tipoPrecio);

  factory ConfiguracionPrecioNivelModel.fromJson(Map<String, dynamic> json) =>
      _$ConfiguracionPrecioNivelModelFromJson(json);

  Map<String, dynamic> toJson() => _$ConfiguracionPrecioNivelModelToJson(this);
}

/// DTO para crear/actualizar una configuración de precios
@JsonSerializable(includeIfNull: false)
class ConfiguracionPrecioDto {
  final String nombre;
  final String? descripcion;
  final List<ConfiguracionPrecioNivelDto> niveles;

  const ConfiguracionPrecioDto({
    required this.nombre,
    this.descripcion,
    required this.niveles,
  });

  factory ConfiguracionPrecioDto.fromJson(Map<String, dynamic> json) =>
      _$ConfiguracionPrecioDtoFromJson(json);

  Map<String, dynamic> toJson() => _$ConfiguracionPrecioDtoToJson(this);
}

/// DTO para crear/actualizar un nivel dentro de una configuración
@JsonSerializable(includeIfNull: false)
class ConfiguracionPrecioNivelDto {
  final String nombre;
  final int cantidadMinima;
  final int? cantidadMaxima;
  final String tipoPrecio; // 'PRECIO_FIJO' o 'PORCENTAJE_DESCUENTO'
  final double? porcentajeDesc;
  final String? descripcion;
  final int? orden;

  const ConfiguracionPrecioNivelDto({
    required this.nombre,
    required this.cantidadMinima,
    this.cantidadMaxima,
    required this.tipoPrecio,
    this.porcentajeDesc,
    this.descripcion,
    this.orden,
  });

  factory ConfiguracionPrecioNivelDto.fromJson(Map<String, dynamic> json) =>
      _$ConfiguracionPrecioNivelDtoFromJson(json);

  Map<String, dynamic> toJson() => _$ConfiguracionPrecioNivelDtoToJson(this);

  /// Crea un DTO desde una entidad
  factory ConfiguracionPrecioNivelDto.fromEntity(
      ConfiguracionPrecioNivel nivel) {
    return ConfiguracionPrecioNivelDto(
      nombre: nivel.nombre,
      cantidadMinima: nivel.cantidadMinima,
      cantidadMaxima: nivel.cantidadMaxima,
      tipoPrecio: nivel.tipoPrecio == TipoPrecioNivel.precioFijo
          ? 'PRECIO_FIJO'
          : 'PORCENTAJE_DESCUENTO',
      porcentajeDesc: nivel.porcentajeDesc,
      descripcion: nivel.descripcion,
      orden: nivel.orden,
    );
  }
}

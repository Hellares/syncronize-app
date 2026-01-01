// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'configuracion_precio_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ConfiguracionPrecioModel _$ConfiguracionPrecioModelFromJson(
  Map<String, dynamic> json,
) => ConfiguracionPrecioModel(
  id: json['id'] as String,
  empresaId: json['empresaId'] as String,
  nombre: json['nombre'] as String,
  descripcion: json['descripcion'] as String?,
  isActive: json['isActive'] as bool,
  niveles: (json['niveles'] as List<dynamic>)
      .map(
        (e) =>
            ConfiguracionPrecioNivelModel.fromJson(e as Map<String, dynamic>),
      )
      .toList(),
  creadoEn: DateTime.parse(json['creadoEn'] as String),
  actualizadoEn: DateTime.parse(json['actualizadoEn'] as String),
  cantidadProductosUsando: (json['cantidadProductosUsando'] as num?)?.toInt(),
);

Map<String, dynamic> _$ConfiguracionPrecioModelToJson(
  ConfiguracionPrecioModel instance,
) => <String, dynamic>{
  'id': instance.id,
  'empresaId': instance.empresaId,
  'nombre': instance.nombre,
  'descripcion': instance.descripcion,
  'isActive': instance.isActive,
  'creadoEn': instance.creadoEn.toIso8601String(),
  'actualizadoEn': instance.actualizadoEn.toIso8601String(),
  'cantidadProductosUsando': instance.cantidadProductosUsando,
  'niveles': instance.niveles.map((e) => e.toJson()).toList(),
};

ConfiguracionPrecioNivelModel _$ConfiguracionPrecioNivelModelFromJson(
  Map<String, dynamic> json,
) => ConfiguracionPrecioNivelModel(
  id: json['id'] as String,
  nombre: json['nombre'] as String,
  cantidadMinima: (json['cantidadMinima'] as num).toInt(),
  cantidadMaxima: (json['cantidadMaxima'] as num?)?.toInt(),
  tipoPrecio: const TipoPrecioNivelConverter().fromJson(
    json['tipoPrecio'] as String,
  ),
  porcentajeDesc: (json['porcentajeDesc'] as num?)?.toDouble(),
  descripcion: json['descripcion'] as String?,
  orden: (json['orden'] as num).toInt(),
);

Map<String, dynamic> _$ConfiguracionPrecioNivelModelToJson(
  ConfiguracionPrecioNivelModel instance,
) => <String, dynamic>{
  'id': instance.id,
  'nombre': instance.nombre,
  'cantidadMinima': instance.cantidadMinima,
  'cantidadMaxima': instance.cantidadMaxima,
  'porcentajeDesc': instance.porcentajeDesc,
  'descripcion': instance.descripcion,
  'orden': instance.orden,
  'tipoPrecio': const TipoPrecioNivelConverter().toJson(instance.tipoPrecio),
};

ConfiguracionPrecioDto _$ConfiguracionPrecioDtoFromJson(
  Map<String, dynamic> json,
) => ConfiguracionPrecioDto(
  nombre: json['nombre'] as String,
  descripcion: json['descripcion'] as String?,
  niveles: (json['niveles'] as List<dynamic>)
      .map(
        (e) => ConfiguracionPrecioNivelDto.fromJson(e as Map<String, dynamic>),
      )
      .toList(),
);

Map<String, dynamic> _$ConfiguracionPrecioDtoToJson(
  ConfiguracionPrecioDto instance,
) => <String, dynamic>{
  'nombre': instance.nombre,
  'descripcion': ?instance.descripcion,
  'niveles': instance.niveles,
};

ConfiguracionPrecioNivelDto _$ConfiguracionPrecioNivelDtoFromJson(
  Map<String, dynamic> json,
) => ConfiguracionPrecioNivelDto(
  nombre: json['nombre'] as String,
  cantidadMinima: (json['cantidadMinima'] as num).toInt(),
  cantidadMaxima: (json['cantidadMaxima'] as num?)?.toInt(),
  tipoPrecio: json['tipoPrecio'] as String,
  porcentajeDesc: (json['porcentajeDesc'] as num?)?.toDouble(),
  descripcion: json['descripcion'] as String?,
  orden: (json['orden'] as num?)?.toInt(),
);

Map<String, dynamic> _$ConfiguracionPrecioNivelDtoToJson(
  ConfiguracionPrecioNivelDto instance,
) => <String, dynamic>{
  'nombre': instance.nombre,
  'cantidadMinima': instance.cantidadMinima,
  'cantidadMaxima': ?instance.cantidadMaxima,
  'tipoPrecio': instance.tipoPrecio,
  'porcentajeDesc': ?instance.porcentajeDesc,
  'descripcion': ?instance.descripcion,
  'orden': ?instance.orden,
};

import '../../domain/entities/configuracion_campo.dart';

class ConfiguracionCampoModel extends ConfiguracionCampo {
  ConfiguracionCampoModel({
    required super.id,
    required super.empresaId,
    required super.nombre,
    required super.tipoCampo,
    super.categoria,
    super.descripcion,
    super.placeholder,
    super.esRequerido,
    super.defaultValue,
    super.opciones,
    super.permiteOtro,
    super.isActive,
    super.orden,
    required super.creadoEn,
    required super.actualizadoEn,
  });

  factory ConfiguracionCampoModel.fromJson(Map<String, dynamic> json) {
    return ConfiguracionCampoModel(
      id: json['id'] as String,
      empresaId: json['empresaId'] as String,
      nombre: json['nombre'] as String,
      tipoCampo: json['tipoCampo'] as String,
      categoria: json['categoria'] as String?,
      descripcion: json['descripcion'] as String?,
      placeholder: json['placeholder'] as String?,
      esRequerido: json['esRequerido'] as bool? ?? false,
      defaultValue: json['defaultValue'] as String?,
      opciones: json['opciones'],
      permiteOtro: json['permiteOtro'] as bool? ?? false,
      isActive: json['isActive'] as bool? ?? true,
      orden: json['orden'] as int?,
      creadoEn: DateTime.parse(json['creadoEn'] as String),
      actualizadoEn: DateTime.parse(json['actualizadoEn'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nombre': nombre,
      'tipoCampo': tipoCampo,
      if (categoria != null) 'categoria': categoria,
      if (descripcion != null) 'descripcion': descripcion,
      if (placeholder != null) 'placeholder': placeholder,
      'esRequerido': esRequerido,
      if (defaultValue != null) 'defaultValue': defaultValue,
      if (opciones != null) 'opciones': opciones,
      'permiteOtro': permiteOtro,
      if (orden != null) 'orden': orden,
    };
  }
}

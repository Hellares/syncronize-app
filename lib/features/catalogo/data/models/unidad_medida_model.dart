import '../../domain/entities/unidad_medida.dart';

/// Model para UnidadMedidaMaestra (catálogo SUNAT)
class UnidadMedidaMaestraModel extends UnidadMedidaMaestra {
  const UnidadMedidaMaestraModel({
    required super.id,
    required super.codigo,
    required super.nombre,
    super.simbolo,
    super.descripcion,
    required super.categoria,
    super.esPopular = false,
    super.orden,
    super.isActive = true,
    required super.creadoEn,
    required super.actualizadoEn,
  });

  factory UnidadMedidaMaestraModel.fromJson(Map<String, dynamic> json) {
    return UnidadMedidaMaestraModel(
      id: json['id'] as String,
      codigo: json['codigo'] as String,
      nombre: json['nombre'] as String,
      simbolo: json['simbolo'] as String?,
      descripcion: json['descripcion'] as String?,
      categoria: CategoriaUnidad.fromString(json['categoria'] as String),
      esPopular: json['esPopular'] as bool? ?? false,
      orden: json['orden'] as int?,
      isActive: json['isActive'] as bool? ?? true,
      creadoEn: DateTime.parse(json['creadoEn'] as String),
      actualizadoEn: DateTime.parse(json['actualizadoEn'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'codigo': codigo,
      'nombre': nombre,
      'simbolo': simbolo,
      'descripcion': descripcion,
      'categoria': categoria.value,
      'esPopular': esPopular,
      'orden': orden,
      'isActive': isActive,
      'creadoEn': creadoEn.toIso8601String(),
      'actualizadoEn': actualizadoEn.toIso8601String(),
    };
  }

  /// Convierte de entity a model
  factory UnidadMedidaMaestraModel.fromEntity(UnidadMedidaMaestra entity) {
    return UnidadMedidaMaestraModel(
      id: entity.id,
      codigo: entity.codigo,
      nombre: entity.nombre,
      simbolo: entity.simbolo,
      descripcion: entity.descripcion,
      categoria: entity.categoria,
      esPopular: entity.esPopular,
      orden: entity.orden,
      isActive: entity.isActive,
      creadoEn: entity.creadoEn,
      actualizadoEn: entity.actualizadoEn,
    );
  }
}

/// Model para EmpresaUnidadMedida (unidades activadas por empresa)
class EmpresaUnidadMedidaModel extends EmpresaUnidadMedida {
  const EmpresaUnidadMedidaModel({
    required super.id,
    required super.empresaId,
    super.unidadMaestraId,
    super.nombrePersonalizado,
    super.simboloPersonalizado,
    super.codigoPersonalizado,
    super.descripcion,
    super.nombreLocal,
    super.simboloLocal,
    super.orden,
    super.isVisible = true,
    super.isActive = true,
    super.deletedAt,
    required super.creadoEn,
    required super.actualizadoEn,
    super.unidadMaestra,
  });

  factory EmpresaUnidadMedidaModel.fromJson(Map<String, dynamic> json) {
    return EmpresaUnidadMedidaModel(
      id: json['id'] as String,
      empresaId: json['empresaId'] as String,
      unidadMaestraId: json['unidadMaestraId'] as String?,
      nombrePersonalizado: json['nombrePersonalizado'] as String?,
      simboloPersonalizado: json['simboloPersonalizado'] as String?,
      codigoPersonalizado: json['codigoPersonalizado'] as String?,
      descripcion: json['descripcion'] as String?,
      nombreLocal: json['nombreLocal'] as String?,
      simboloLocal: json['simboloLocal'] as String?,
      orden: json['orden'] as int?,
      isVisible: json['isVisible'] as bool? ?? true,
      isActive: json['isActive'] as bool? ?? true,
      deletedAt: json['deletedAt'] != null
          ? DateTime.parse(json['deletedAt'] as String)
          : null,
      creadoEn: DateTime.parse(json['creadoEn'] as String),
      actualizadoEn: DateTime.parse(json['actualizadoEn'] as String),
      unidadMaestra: json['unidadMaestra'] != null
          ? UnidadMedidaMaestraModel.fromJson(
              json['unidadMaestra'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'empresaId': empresaId,
      'unidadMaestraId': unidadMaestraId,
      'nombrePersonalizado': nombrePersonalizado,
      'simboloPersonalizado': simboloPersonalizado,
      'codigoPersonalizado': codigoPersonalizado,
      'descripcion': descripcion,
      'nombreLocal': nombreLocal,
      'simboloLocal': simboloLocal,
      'orden': orden,
      'isVisible': isVisible,
      'isActive': isActive,
      'deletedAt': deletedAt?.toIso8601String(),
      'creadoEn': creadoEn.toIso8601String(),
      'actualizadoEn': actualizadoEn.toIso8601String(),
      'unidadMaestra': unidadMaestra != null
          ? UnidadMedidaMaestraModel.fromEntity(
                  unidadMaestra as UnidadMedidaMaestra)
              .toJson()
          : null,
    };
  }

  /// Convierte de entity a model
  factory EmpresaUnidadMedidaModel.fromEntity(EmpresaUnidadMedida entity) {
    return EmpresaUnidadMedidaModel(
      id: entity.id,
      empresaId: entity.empresaId,
      unidadMaestraId: entity.unidadMaestraId,
      nombrePersonalizado: entity.nombrePersonalizado,
      simboloPersonalizado: entity.simboloPersonalizado,
      codigoPersonalizado: entity.codigoPersonalizado,
      descripcion: entity.descripcion,
      nombreLocal: entity.nombreLocal,
      simboloLocal: entity.simboloLocal,
      orden: entity.orden,
      isVisible: entity.isVisible,
      isActive: entity.isActive,
      deletedAt: entity.deletedAt,
      creadoEn: entity.creadoEn,
      actualizadoEn: entity.actualizadoEn,
      unidadMaestra: entity.unidadMaestra,
    );
  }

  /// Crea un DTO para activar unidad (sin unidadMaestra anidada)
  Map<String, dynamic> toActivarDto() {
    return {
      'empresaId': empresaId,
      if (unidadMaestraId != null) 'unidadMaestraId': unidadMaestraId,
      if (nombrePersonalizado != null)
        'nombrePersonalizado': nombrePersonalizado,
      if (simboloPersonalizado != null)
        'simboloPersonalizado': simboloPersonalizado,
      if (codigoPersonalizado != null)
        'codigoPersonalizado': codigoPersonalizado,
      if (descripcion != null) 'descripcion': descripcion,
      if (nombreLocal != null) 'nombreLocal': nombreLocal,
      if (simboloLocal != null) 'simboloLocal': simboloLocal,
      if (orden != null) 'orden': orden,
    };
  }
}

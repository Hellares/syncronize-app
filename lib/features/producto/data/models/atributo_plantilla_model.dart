import '../../domain/entities/atributo_plantilla.dart';

/// Model para PlantillaAtributo
class PlantillaAtributoModel extends PlantillaAtributo {
  const PlantillaAtributoModel({
    required super.id,
    required super.atributoId,
    required super.orden,
    super.requeridoOverride,
    super.valoresOverride,
    required super.atributo,
  });

  factory PlantillaAtributoModel.fromJson(Map<String, dynamic> json) {
    return PlantillaAtributoModel(
      id: json['id'] as String,
      atributoId: json['atributoId'] as String,
      orden: json['orden'] as int,
      requeridoOverride: json['requeridoOverride'] as bool?,
      valoresOverride: (json['valoresOverride'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      atributo: AtributoInfoModel.fromJson(json['atributo'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'atributoId': atributoId,
      'orden': orden,
      if (requeridoOverride != null) 'requeridoOverride': requeridoOverride,
      if (valoresOverride != null && valoresOverride!.isNotEmpty)
        'valoresOverride': valoresOverride,
      'atributo': (atributo as AtributoInfoModel).toJson(),
    };
  }
}

/// Model para AtributoInfo
class AtributoInfoModel extends AtributoInfo {
  const AtributoInfoModel({
    required super.id,
    required super.nombre,
    required super.clave,
    required super.tipo,
    required super.requerido,
    super.descripcion,
    super.unidad,
    required super.valores,
  });

  factory AtributoInfoModel.fromJson(Map<String, dynamic> json) {
    return AtributoInfoModel(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      clave: json['clave'] as String,
      tipo: json['tipo'] as String,
      requerido: json['requerido'] as bool,
      descripcion: json['descripcion'] as String?,
      unidad: json['unidad'] as String?,
      valores: (json['valores'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'clave': clave,
      'tipo': tipo,
      'requerido': requerido,
      if (descripcion != null) 'descripcion': descripcion,
      if (unidad != null) 'unidad': unidad,
      'valores': valores,
    };
  }
}

/// Model para CategoriaInfo
class CategoriaInfoModel extends CategoriaInfo {
  const CategoriaInfoModel({
    required super.id,
    super.nombreLocal,
    super.nombrePersonalizado,
  });

  factory CategoriaInfoModel.fromJson(Map<String, dynamic> json) {
    return CategoriaInfoModel(
      id: json['id'] as String,
      nombreLocal: json['nombreLocal'] as String?,
      nombrePersonalizado: json['nombrePersonalizado'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (nombreLocal != null) 'nombreLocal': nombreLocal,
      if (nombrePersonalizado != null) 'nombrePersonalizado': nombrePersonalizado,
    };
  }
}

/// Model para AtributoPlantilla
class AtributoPlantillaModel extends AtributoPlantilla {
  const AtributoPlantillaModel({
    required super.id,
    required super.empresaId,
    super.categoriaId,
    required super.nombre,
    super.descripcion,
    super.icono,
    required super.esPredefinida,
    required super.orden,
    required super.isActive,
    required super.creadoEn,
    required super.actualizadoEn,
    required super.atributos,
    super.categoria,
  });

  factory AtributoPlantillaModel.fromJson(Map<String, dynamic> json) {
    return AtributoPlantillaModel(
      id: json['id'] as String,
      empresaId: json['empresaId'] as String,
      categoriaId: json['categoriaId'] as String?,
      nombre: json['nombre'] as String,
      descripcion: json['descripcion'] as String?,
      icono: json['icono'] as String?,
      esPredefinida: json['esPredefinida'] as bool? ?? false,
      orden: json['orden'] as int? ?? 0,
      isActive: json['isActive'] as bool? ?? true,
      creadoEn: DateTime.parse(json['creadoEn'] as String),
      actualizadoEn: DateTime.parse(json['actualizadoEn'] as String),
      atributos: (json['atributos'] as List<dynamic>?)
              ?.map((e) => PlantillaAtributoModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      categoria: json['categoria'] != null
          ? CategoriaInfoModel.fromJson(json['categoria'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'empresaId': empresaId,
      if (categoriaId != null) 'categoriaId': categoriaId,
      'nombre': nombre,
      if (descripcion != null) 'descripcion': descripcion,
      if (icono != null) 'icono': icono,
      'esPredefinida': esPredefinida,
      'orden': orden,
      'isActive': isActive,
      'creadoEn': creadoEn.toIso8601String(),
      'actualizadoEn': actualizadoEn.toIso8601String(),
      'atributos': atributos
          .map((a) => (a as PlantillaAtributoModel).toJson())
          .toList(),
      if (categoria != null) 'categoria': (categoria as CategoriaInfoModel).toJson(),
    };
  }

  factory AtributoPlantillaModel.fromEntity(AtributoPlantilla entity) {
    return AtributoPlantillaModel(
      id: entity.id,
      empresaId: entity.empresaId,
      categoriaId: entity.categoriaId,
      nombre: entity.nombre,
      descripcion: entity.descripcion,
      icono: entity.icono,
      esPredefinida: entity.esPredefinida,
      orden: entity.orden,
      isActive: entity.isActive,
      creadoEn: entity.creadoEn,
      actualizadoEn: entity.actualizadoEn,
      atributos: entity.atributos,
      categoria: entity.categoria,
    );
  }

  AtributoPlantilla toEntity() => this;
}

/// DTO para crear plantilla
class CreatePlantillaDto {
  final String nombre;
  final String? descripcion;
  final String? icono;
  final String? categoriaId;
  final int? orden;
  final List<PlantillaAtributoCreateDto> atributos;

  const CreatePlantillaDto({
    required this.nombre,
    this.descripcion,
    this.icono,
    this.categoriaId,
    this.orden,
    required this.atributos,
  });

  Map<String, dynamic> toJson() {
    return {
      'nombre': nombre,
      if (descripcion != null) 'descripcion': descripcion,
      if (icono != null) 'icono': icono,
      if (categoriaId != null) 'categoriaId': categoriaId,
      if (orden != null) 'orden': orden,
      'atributos': atributos.map((a) => a.toJson()).toList(),
    };
  }
}

/// DTO para actualizar plantilla
class UpdatePlantillaDto {
  final String? nombre;
  final String? descripcion;
  final String? icono;
  final String? categoriaId;
  final int? orden;
  final List<PlantillaAtributoCreateDto>? atributos;

  const UpdatePlantillaDto({
    this.nombre,
    this.descripcion,
    this.icono,
    this.categoriaId,
    this.orden,
    this.atributos,
  });

  Map<String, dynamic> toJson() {
    return {
      if (nombre != null) 'nombre': nombre,
      if (descripcion != null) 'descripcion': descripcion,
      if (icono != null) 'icono': icono,
      if (categoriaId != null) 'categoriaId': categoriaId,
      if (orden != null) 'orden': orden,
      if (atributos != null) 'atributos': atributos!.map((a) => a.toJson()).toList(),
    };
  }
}

/// DTO para atributo al crear/actualizar plantilla
class PlantillaAtributoCreateDto {
  final String atributoId;
  final int? orden;
  final bool? requeridoOverride;
  final List<String>? valoresOverride;

  const PlantillaAtributoCreateDto({
    required this.atributoId,
    this.orden,
    this.requeridoOverride,
    this.valoresOverride,
  });

  Map<String, dynamic> toJson() {
    return {
      'atributoId': atributoId,
      if (orden != null) 'orden': orden,
      if (requeridoOverride != null) 'requeridoOverride': requeridoOverride,
      if (valoresOverride != null && valoresOverride!.isNotEmpty)
        'valoresOverride': valoresOverride,
    };
  }
}

/// DTO para aplicar plantilla a producto/variante
class AplicarPlantillaDto {
  final String plantillaId;
  final String? productoId;
  final String? varianteId;

  const AplicarPlantillaDto({
    required this.plantillaId,
    this.productoId,
    this.varianteId,
  });

  Map<String, dynamic> toJson() {
    return {
      'plantillaId': plantillaId,
      if (productoId != null) 'productoId': productoId,
      if (varianteId != null) 'varianteId': varianteId,
    };
  }
}

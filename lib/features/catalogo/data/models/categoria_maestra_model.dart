import '../../domain/entities/categoria_maestra.dart';

class CategoriaMaestraModel extends CategoriaMaestra {
  const CategoriaMaestraModel({
    required super.id,
    required super.nombre,
    required super.slug,
    super.descripcion,
    super.icono,
    super.imagen,
    super.padreId,
    required super.nivel,
    super.orden,
    required super.esPopular,
    required super.isActive,
    required super.creadoEn,
    required super.actualizadoEn,
  });

  factory CategoriaMaestraModel.fromJson(Map<String, dynamic> json) {
    return CategoriaMaestraModel(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      slug: json['slug'] as String,
      descripcion: json['descripcion'] as String?,
      icono: json['icono'] as String?,
      imagen: json['imagen'] as String?,
      padreId: json['padreId'] as String?,
      nivel: json['nivel'] as int? ?? 0,
      orden: json['orden'] as int?,
      esPopular: json['esPopular'] as bool? ?? false,
      isActive: json['isActive'] as bool? ?? true,
      creadoEn: DateTime.parse(json['creadoEn'] as String),
      actualizadoEn: DateTime.parse(json['actualizadoEn'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'slug': slug,
      if (descripcion != null) 'descripcion': descripcion,
      if (icono != null) 'icono': icono,
      if (imagen != null) 'imagen': imagen,
      if (padreId != null) 'padreId': padreId,
      'nivel': nivel,
      if (orden != null) 'orden': orden,
      'esPopular': esPopular,
      'isActive': isActive,
      'creadoEn': creadoEn.toIso8601String(),
      'actualizadoEn': actualizadoEn.toIso8601String(),
    };
  }

  CategoriaMaestra toEntity() => this;

  factory CategoriaMaestraModel.fromEntity(CategoriaMaestra entity) {
    return CategoriaMaestraModel(
      id: entity.id,
      nombre: entity.nombre,
      slug: entity.slug,
      descripcion: entity.descripcion,
      icono: entity.icono,
      imagen: entity.imagen,
      padreId: entity.padreId,
      nivel: entity.nivel,
      orden: entity.orden,
      esPopular: entity.esPopular,
      isActive: entity.isActive,
      creadoEn: entity.creadoEn,
      actualizadoEn: entity.actualizadoEn,
    );
  }
}

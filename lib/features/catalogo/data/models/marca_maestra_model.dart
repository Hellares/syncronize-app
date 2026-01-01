import '../../domain/entities/marca_maestra.dart';

class MarcaMaestraModel extends MarcaMaestra {
  const MarcaMaestraModel({
    required super.id,
    required super.nombre,
    required super.slug,
    super.descripcion,
    super.logo,
    super.sitioWeb,
    super.paisOrigen,
    required super.esPopular,
    required super.isActive,
    required super.creadoEn,
    required super.actualizadoEn,
  });

  factory MarcaMaestraModel.fromJson(Map<String, dynamic> json) {
    return MarcaMaestraModel(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      slug: json['slug'] as String,
      descripcion: json['descripcion'] as String?,
      logo: json['logo'] as String?,
      sitioWeb: json['sitioWeb'] as String?,
      paisOrigen: json['paisOrigen'] as String?,
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
      if (logo != null) 'logo': logo,
      if (sitioWeb != null) 'sitioWeb': sitioWeb,
      if (paisOrigen != null) 'paisOrigen': paisOrigen,
      'esPopular': esPopular,
      'isActive': isActive,
      'creadoEn': creadoEn.toIso8601String(),
      'actualizadoEn': actualizadoEn.toIso8601String(),
    };
  }

  MarcaMaestra toEntity() => this;

  factory MarcaMaestraModel.fromEntity(MarcaMaestra entity) {
    return MarcaMaestraModel(
      id: entity.id,
      nombre: entity.nombre,
      slug: entity.slug,
      descripcion: entity.descripcion,
      logo: entity.logo,
      sitioWeb: entity.sitioWeb,
      paisOrigen: entity.paisOrigen,
      esPopular: entity.esPopular,
      isActive: entity.isActive,
      creadoEn: entity.creadoEn,
      actualizadoEn: entity.actualizadoEn,
    );
  }
}

import '../../domain/entities/catalogo_preview.dart';

/// Modelo para preview de categoría maestra
class CategoriaMaestraPreviewModel extends CategoriaMaestraPreview {
  const CategoriaMaestraPreviewModel({
    required super.id,
    required super.nombre,
    required super.slug,
    super.icono,
    super.descripcion,
  });

  factory CategoriaMaestraPreviewModel.fromJson(Map<String, dynamic> json) {
    return CategoriaMaestraPreviewModel(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      slug: json['slug'] as String,
      icono: json['icono'] as String?,
      descripcion: json['descripcion'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'slug': slug,
      'icono': icono,
      'descripcion': descripcion,
    };
  }

  CategoriaMaestraPreview toEntity() {
    return CategoriaMaestraPreview(
      id: id,
      nombre: nombre,
      slug: slug,
      icono: icono,
      descripcion: descripcion,
    );
  }

  factory CategoriaMaestraPreviewModel.fromEntity(
      CategoriaMaestraPreview entity) {
    return CategoriaMaestraPreviewModel(
      id: entity.id,
      nombre: entity.nombre,
      slug: entity.slug,
      icono: entity.icono,
      descripcion: entity.descripcion,
    );
  }
}

/// Modelo para preview de marca maestra
class MarcaMaestraPreviewModel extends MarcaMaestraPreview {
  const MarcaMaestraPreviewModel({
    required super.id,
    required super.nombre,
    required super.slug,
    super.logo,
    super.descripcion,
  });

  factory MarcaMaestraPreviewModel.fromJson(Map<String, dynamic> json) {
    return MarcaMaestraPreviewModel(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      slug: json['slug'] as String,
      logo: json['logo'] as String?,
      descripcion: json['descripcion'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'slug': slug,
      'logo': logo,
      'descripcion': descripcion,
    };
  }

  MarcaMaestraPreview toEntity() {
    return MarcaMaestraPreview(
      id: id,
      nombre: nombre,
      slug: slug,
      logo: logo,
      descripcion: descripcion,
    );
  }

  factory MarcaMaestraPreviewModel.fromEntity(MarcaMaestraPreview entity) {
    return MarcaMaestraPreviewModel(
      id: entity.id,
      nombre: entity.nombre,
      slug: entity.slug,
      logo: entity.logo,
      descripcion: entity.descripcion,
    );
  }
}

/// Modelo para el preview completo de catálogos
class CatalogoPreviewModel extends CatalogoPreview {
  const CatalogoPreviewModel({
    required super.rubro,
    required super.categorias,
    required super.marcas,
    required super.total,
  });

  factory CatalogoPreviewModel.fromJson(Map<String, dynamic> json) {
    return CatalogoPreviewModel(
      rubro: json['rubro'] as String,
      categorias: (json['categorias'] as List<dynamic>)
          .map((e) =>
              CategoriaMaestraPreviewModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      marcas: (json['marcas'] as List<dynamic>)
          .map((e) =>
              MarcaMaestraPreviewModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: json['total'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'rubro': rubro,
      'categorias': categorias
          .map((e) => CategoriaMaestraPreviewModel.fromEntity(e).toJson())
          .toList(),
      'marcas': marcas
          .map((e) => MarcaMaestraPreviewModel.fromEntity(e).toJson())
          .toList(),
      'total': total,
    };
  }

  CatalogoPreview toEntity() {
    return CatalogoPreview(
      rubro: rubro,
      categorias: categorias,
      marcas: marcas,
      total: total,
    );
  }

  factory CatalogoPreviewModel.fromEntity(CatalogoPreview entity) {
    return CatalogoPreviewModel(
      rubro: entity.rubro,
      categorias: entity.categorias,
      marcas: entity.marcas,
      total: entity.total,
    );
  }
}

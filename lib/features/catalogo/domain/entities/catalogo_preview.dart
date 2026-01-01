import 'package:equatable/equatable.dart';

/// Entidad para preview simple de categoría maestra
class CategoriaMaestraPreview extends Equatable {
  final String id;
  final String nombre;
  final String slug;
  final String? icono;
  final String? descripcion;

  const CategoriaMaestraPreview({
    required this.id,
    required this.nombre,
    required this.slug,
    this.icono,
    this.descripcion,
  });

  @override
  List<Object?> get props => [id, nombre, slug, icono, descripcion];
}

/// Entidad para preview simple de marca maestra
class MarcaMaestraPreview extends Equatable {
  final String id;
  final String nombre;
  final String slug;
  final String? logo;
  final String? descripcion;

  const MarcaMaestraPreview({
    required this.id,
    required this.nombre,
    required this.slug,
    this.logo,
    this.descripcion,
  });

  @override
  List<Object?> get props => [id, nombre, slug, logo, descripcion];
}

/// Entidad para el preview completo de catálogos según rubro
class CatalogoPreview extends Equatable {
  final String rubro;
  final List<CategoriaMaestraPreview> categorias;
  final List<MarcaMaestraPreview> marcas;
  final int total;

  const CatalogoPreview({
    required this.rubro,
    required this.categorias,
    required this.marcas,
    required this.total,
  });

  @override
  List<Object?> get props => [rubro, categorias, marcas, total];
}

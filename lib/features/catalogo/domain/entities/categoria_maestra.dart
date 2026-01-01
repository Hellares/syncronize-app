import 'package:equatable/equatable.dart';

/// Entity que representa una categoría maestra del catálogo global
class CategoriaMaestra extends Equatable {
  final String id;
  final String nombre;
  final String slug;
  final String? descripcion;
  final String? icono;
  final String? imagen;
  final String? padreId;
  final int nivel;
  final int? orden;
  final bool esPopular;
  final bool isActive;
  final DateTime creadoEn;
  final DateTime actualizadoEn;

  const CategoriaMaestra({
    required this.id,
    required this.nombre,
    required this.slug,
    this.descripcion,
    this.icono,
    this.imagen,
    this.padreId,
    required this.nivel,
    this.orden,
    required this.esPopular,
    required this.isActive,
    required this.creadoEn,
    required this.actualizadoEn,
  });

  /// Verifica si es una categoría raíz (sin padre)
  bool get isRoot => padreId == null;

  /// Verifica si es una subcategoría
  bool get isSubcategory => padreId != null;

  @override
  List<Object?> get props => [
        id,
        nombre,
        slug,
        descripcion,
        icono,
        imagen,
        padreId,
        nivel,
        orden,
        esPopular,
        isActive,
        creadoEn,
        actualizadoEn,
      ];
}

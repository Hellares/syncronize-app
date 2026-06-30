import '../../domain/entities/categoria_marketplace.dart';

class CategoriaMarketplaceModel {
  final String id;
  final String nombre;
  final String? slug;
  final String? icono;
  final String? padreId;

  const CategoriaMarketplaceModel({
    required this.id,
    required this.nombre,
    this.slug,
    this.icono,
    this.padreId,
  });

  factory CategoriaMarketplaceModel.fromJson(Map<String, dynamic> json) {
    return CategoriaMarketplaceModel(
      id: json['id'] as String? ?? '',
      nombre: json['nombre'] as String? ?? '',
      slug: json['slug'] as String?,
      icono: json['icono'] as String?,
      padreId: json['padreId'] as String?,
    );
  }

  CategoriaMarketplace toEntity() => CategoriaMarketplace(
        id: id,
        nombre: nombre,
        slug: slug,
        icono: icono,
        padreId: padreId,
      );
}

import 'package:equatable/equatable.dart';

/// Categoría maestra usada en los chips de filtro y cards del marketplace.
class CategoriaMarketplace extends Equatable {
  final String id;
  final String nombre;
  final String? slug;
  final String? icono;
  final String? padreId;

  const CategoriaMarketplace({
    required this.id,
    required this.nombre,
    this.slug,
    this.icono,
    this.padreId,
  });

  @override
  List<Object?> get props => [id, nombre, slug, icono, padreId];
}

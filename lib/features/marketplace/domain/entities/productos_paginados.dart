import 'package:equatable/equatable.dart';
import 'producto_marketplace.dart';

/// Resultado paginado de la búsqueda de productos del marketplace.
class ProductosPaginados extends Equatable {
  final List<ProductoMarketplace> productos;
  final int total;
  final int page;
  final int totalPages;

  const ProductosPaginados({
    required this.productos,
    required this.total,
    required this.page,
    required this.totalPages,
  });

  /// Si quedan más páginas por cargar (paginación infinita).
  bool get hasMore => page < totalPages;

  @override
  List<Object?> get props => [productos, total, page, totalPages];
}

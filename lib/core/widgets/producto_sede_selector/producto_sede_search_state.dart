import 'package:equatable/equatable.dart';
import '../../../features/producto/domain/entities/producto_list_item.dart';

/// Estados base para búsqueda de productos
abstract class ProductoSedeSearchState extends Equatable {
  const ProductoSedeSearchState();

  /// Productos previos para mantener en pantalla durante loading/debouncing
  List<ProductoListItem> get productosActuales => const [];

  @override
  List<Object?> get props => [];
}

/// Estado inicial
class ProductoSedeSearchInitial extends ProductoSedeSearchState {}

/// Estado de debouncing (usuario todavía escribiendo)
class ProductoSedeSearchDebouncing extends ProductoSedeSearchState {
  final String? query;
  final List<ProductoListItem> _productosAnteriores;

  const ProductoSedeSearchDebouncing({
    this.query,
    List<ProductoListItem> productosAnteriores = const [],
  }) : _productosAnteriores = productosAnteriores;

  @override
  List<ProductoListItem> get productosActuales => _productosAnteriores;

  @override
  List<Object?> get props => [query, _productosAnteriores];
}

/// Estado de carga (ejecutando búsqueda)
class ProductoSedeSearchLoading extends ProductoSedeSearchState {
  final String? query;
  final List<ProductoListItem> _productosAnteriores;

  const ProductoSedeSearchLoading({
    this.query,
    List<ProductoListItem> productosAnteriores = const [],
  }) : _productosAnteriores = productosAnteriores;

  @override
  List<ProductoListItem> get productosActuales => _productosAnteriores;

  @override
  List<Object?> get props => [query, _productosAnteriores];
}

/// Estado de productos cargados
class ProductoSedeSearchLoaded extends ProductoSedeSearchState {
  final List<ProductoListItem> productos;
  final String? query;
  final bool hasMore;

  const ProductoSedeSearchLoaded({
    required this.productos,
    this.query,
    this.hasMore = false,
  });

  @override
  List<ProductoListItem> get productosActuales => productos;

  @override
  List<Object?> get props => [productos, query, hasMore];
}

/// Estado de error
class ProductoSedeSearchError extends ProductoSedeSearchState {
  final String message;
  final String? query;
  final List<ProductoListItem> _productosAnteriores;

  const ProductoSedeSearchError({
    required this.message,
    this.query,
    List<ProductoListItem> productosAnteriores = const [],
  }) : _productosAnteriores = productosAnteriores;

  @override
  List<ProductoListItem> get productosActuales => _productosAnteriores;

  @override
  List<Object?> get props => [message, query, _productosAnteriores];
}

import 'package:equatable/equatable.dart';
import '../../../domain/entities/producto_list_item.dart';
import '../../../domain/entities/producto_filtros.dart';

/// Estados de la lista de productos
abstract class ProductoListState extends Equatable {
  const ProductoListState();

  @override
  List<Object?> get props => [];
}

/// Estado inicial
class ProductoListInitial extends ProductoListState {
  const ProductoListInitial();
}

/// Estado de carga
class ProductoListLoading extends ProductoListState {
  const ProductoListLoading();
}

/// Estado de carga de más productos (paginación)
class ProductoListLoadingMore extends ProductoListState {
  final List<ProductoListItem> currentProducts;

  const ProductoListLoadingMore(this.currentProducts);

  @override
  List<Object?> get props => [currentProducts];
}

/// Estado de éxito con productos cargados.
///
/// `isFiltering` indica que un filtro nuevo está en curso pero los productos
/// previos siguen visibles (sin parpadeo). La UI debe mostrar un indicador
/// sutil (LinearProgressIndicator) en lugar de reemplazar la lista por un
/// spinner.
class ProductoListLoaded extends ProductoListState {
  final List<ProductoListItem> productos;
  final int total;
  final int currentPage;
  final int totalPages;
  final bool hasMore;
  final ProductoFiltros filtros;
  final bool isFiltering;

  const ProductoListLoaded({
    required this.productos,
    required this.total,
    required this.currentPage,
    required this.totalPages,
    required this.hasMore,
    required this.filtros,
    this.isFiltering = false,
  });

  ProductoListLoaded copyWith({
    List<ProductoListItem>? productos,
    int? total,
    int? currentPage,
    int? totalPages,
    bool? hasMore,
    ProductoFiltros? filtros,
    bool? isFiltering,
  }) {
    return ProductoListLoaded(
      productos: productos ?? this.productos,
      total: total ?? this.total,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      hasMore: hasMore ?? this.hasMore,
      filtros: filtros ?? this.filtros,
      isFiltering: isFiltering ?? this.isFiltering,
    );
  }

  @override
  List<Object?> get props => [
        productos,
        total,
        currentPage,
        totalPages,
        hasMore,
        filtros,
        isFiltering,
      ];
}

/// Estado de error
class ProductoListError extends ProductoListState {
  final String message;
  final String? errorCode;

  const ProductoListError(this.message, {this.errorCode});

  @override
  List<Object?> get props => [message, errorCode];
}

import 'package:equatable/equatable.dart';
import '../../../domain/entities/producto.dart';
import '../../../domain/entities/producto_list_item.dart';

/// Estados del ProductoSearchCubit
abstract class ProductoSearchState extends Equatable {
  const ProductoSearchState();

  @override
  List<Object?> get props => [];
}

/// Estado inicial - Sin búsqueda aún
class ProductoSearchInitial extends ProductoSearchState {
  const ProductoSearchInitial();
}

/// Estado de carga - Buscando productos
class ProductoSearchLoading extends ProductoSearchState {
  const ProductoSearchLoading();
}

/// Estado de carga adicional - Paginación
class ProductoSearchLoadingMore extends ProductoSearchState {
  final List<ProductoListItem> currentResults;
  final int currentPage;
  final bool hasMore;

  const ProductoSearchLoadingMore({
    required this.currentResults,
    required this.currentPage,
    required this.hasMore,
  });

  @override
  List<Object?> get props => [currentResults, currentPage, hasMore];
}

/// Estado exitoso - Resultados encontrados
class ProductoSearchLoaded extends ProductoSearchState {
  final List<ProductoListItem> productos;
  final String query;
  final int currentPage;
  final int totalResults;
  final bool hasMore;
  final Map<String, Producto>? productosCache; // Cache de productos completos

  const ProductoSearchLoaded({
    required this.productos,
    required this.query,
    required this.currentPage,
    required this.totalResults,
    required this.hasMore,
    this.productosCache,
  });

  @override
  List<Object?> get props => [
        productos,
        query,
        currentPage,
        totalResults,
        hasMore,
        productosCache,
      ];

  /// Verifica si está vacío
  bool get isEmpty => productos.isEmpty;

  /// Verifica si tiene resultados
  bool get hasResults => productos.isNotEmpty;

  /// Copia con nuevos valores
  ProductoSearchLoaded copyWith({
    List<ProductoListItem>? productos,
    String? query,
    int? currentPage,
    int? totalResults,
    bool? hasMore,
    Map<String, Producto>? productosCache,
  }) {
    return ProductoSearchLoaded(
      productos: productos ?? this.productos,
      query: query ?? this.query,
      currentPage: currentPage ?? this.currentPage,
      totalResults: totalResults ?? this.totalResults,
      hasMore: hasMore ?? this.hasMore,
      productosCache: productosCache ?? this.productosCache,
    );
  }
}

/// Estado de error
class ProductoSearchError extends ProductoSearchState {
  final String message;
  final String? errorCode;

  const ProductoSearchError(this.message, {this.errorCode});

  @override
  List<Object?> get props => [message, errorCode];
}

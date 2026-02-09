import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../../../../core/utils/resource.dart';
import '../../../domain/entities/producto.dart';
import '../../../domain/entities/producto_filtros.dart';
import '../../../domain/entities/producto_list_item.dart';
import '../../../domain/usecases/get_productos_usecase.dart';
import 'producto_search_state.dart';

@injectable
class ProductoSearchCubit extends Cubit<ProductoSearchState> {
  final GetProductosUseCase _getProductosUseCase;

  ProductoSearchCubit(
    this._getProductosUseCase,
  ) : super(const ProductoSearchInitial());

  // Estado actual de búsqueda
  String? _currentQuery;
  String? _empresaId;
  String? _sedeId;
  int _currentPage = 1;
  final Map<String, Producto> _productosCache = {};

  /// Realiza una búsqueda de productos
  Future<void> search({
    required String query,
    required String empresaId,
    String? sedeId,
  }) async {
    // Si el query está vacío, resetear
    if (query.trim().isEmpty) {
      emit(const ProductoSearchInitial());
      _currentQuery = null;
      _currentPage = 1;
      _productosCache.clear();
      return;
    }

    // Guardar contexto
    _currentQuery = query;
    _empresaId = empresaId;
    _sedeId = sedeId;
    _currentPage = 1;
    _productosCache.clear();

    // Emitir estado de carga
    emit(const ProductoSearchLoading());

    // Crear filtros
    final filtros = ProductoFiltros(
      search: query,
      page: _currentPage,
      limit: 20,
    );

    // Ejecutar búsqueda
    final result = await _getProductosUseCase(
      empresaId: empresaId,
      sedeId: sedeId,
      filtros: filtros,
    );

    // Manejar resultado
    if (isClosed) return;

    if (result is Success<ProductosPaginados>) {
      final data = result.data;

      // Cachear productos completos si existen
      if (data.fullProductosCache != null) {
        _productosCache.addAll(data.fullProductosCache!.cast<String, Producto>());
      }

      emit(ProductoSearchLoaded(
        productos: data.data.cast<ProductoListItem>(),
        query: query,
        currentPage: data.page,
        totalResults: data.total,
        hasMore: data.hasNext,
        productosCache: Map.from(_productosCache),
      ));
    } else if (result is Error<ProductosPaginados>) {
      emit(ProductoSearchError(
        result.message,
        errorCode: result.errorCode,
      ));
    }
  }

  /// Carga más resultados (paginación)
  Future<void> loadMore() async {
    final currentState = state;

    // Solo cargar más si estamos en estado loaded y hay más resultados
    if (currentState is! ProductoSearchLoaded) return;
    if (!currentState.hasMore) return;
    if (_currentQuery == null || _empresaId == null) return;

    // Emitir estado de carga adicional
    emit(ProductoSearchLoadingMore(
      currentResults: currentState.productos,
      currentPage: currentState.currentPage,
      hasMore: currentState.hasMore,
    ));

    // Incrementar página
    _currentPage = currentState.currentPage + 1;

    // Crear filtros
    final filtros = ProductoFiltros(
      search: _currentQuery!,
      page: _currentPage,
      limit: 20,
    );

    // Ejecutar búsqueda
    final result = await _getProductosUseCase(
      empresaId: _empresaId!,
      sedeId: _sedeId,
      filtros: filtros,
    );

    // Manejar resultado
    if (isClosed) return;

    if (result is Success<ProductosPaginados>) {
      final data = result.data;

      // Cachear productos completos si existen
      if (data.fullProductosCache != null) {
        _productosCache.addAll(data.fullProductosCache!.cast<String, Producto>());
      }

      // Combinar resultados anteriores con nuevos
      final allProductos = [
        ...currentState.productos,
        ...data.data.cast<ProductoListItem>(),
      ];

      emit(ProductoSearchLoaded(
        productos: allProductos,
        query: _currentQuery!,
        currentPage: data.page,
        totalResults: data.total,
        hasMore: data.hasNext,
        productosCache: Map.from(_productosCache),
      ));
    } else if (result is Error<ProductosPaginados>) {
      // Volver al estado anterior en caso de error
      emit(currentState);
    }
  }

  /// Limpia el estado de búsqueda
  void clear() {
    _currentQuery = null;
    _empresaId = null;
    _sedeId = null;
    _currentPage = 1;
    _productosCache.clear();
    emit(const ProductoSearchInitial());
  }

  /// Obtiene un producto del cache
  Producto? getProductoFromCache(String productoId) {
    return _productosCache[productoId];
  }

  /// Verifica si hay productos cacheados
  bool get hasCache => _productosCache.isNotEmpty;

  /// Query actual
  String? get currentQuery => _currentQuery;
}

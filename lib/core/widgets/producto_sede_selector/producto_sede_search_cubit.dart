import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../../features/producto/domain/entities/producto_list_item.dart';
import '../../../features/producto/domain/entities/producto_filtros.dart';
import '../../../features/producto/domain/usecases/get_productos_usecase.dart';
import '../../utils/resource.dart';
import 'producto_sede_search_state.dart';

/// Cubit para búsqueda de productos con debouncing y paginación
@injectable
class ProductoSedeSearchCubit extends Cubit<ProductoSedeSearchState> {
  final GetProductosUseCase _getProductos;
  Timer? _debounceTimer;

  /// Cache con límite para evitar memory leaks
  final Map<String, List<ProductoListItem>> _cache = {};
  static const int _maxCacheEntries = 50;

  ProductoSedeSearchCubit(this._getProductos) : super(ProductoSedeSearchInitial());

  /// Productos del estado actual (para preservar durante loading)
  List<ProductoListItem> get _productosActuales => state.productosActuales;

  /// Busca productos con debouncing (300ms)
  void searchProductos({
    required String empresaId,
    String? sedeId,
    String? query,
    int page = 1,
    int limit = 20,
    bool soloProductos = true,
  }) {
    _debounceTimer?.cancel();

    if (query != null && query.isNotEmpty) {
      emit(ProductoSedeSearchDebouncing(
        query: query,
        productosAnteriores: _productosActuales,
      ));

      _debounceTimer = Timer(const Duration(milliseconds: 300), () {
        _executeSearch(
          empresaId: empresaId,
          sedeId: sedeId,
          query: query,
          page: page,
          limit: limit,
          soloProductos: soloProductos,
        );
      });
    } else {
      _executeSearch(
        empresaId: empresaId,
        sedeId: sedeId,
        query: query,
        page: page,
        limit: limit,
        soloProductos: soloProductos,
      );
    }
  }

  /// Ejecuta la búsqueda real
  Future<void> _executeSearch({
    required String empresaId,
    String? sedeId,
    String? query,
    required int page,
    required int limit,
    required bool soloProductos,
  }) async {
    emit(ProductoSedeSearchLoading(
      query: query,
      productosAnteriores: _productosActuales,
    ));

    final cacheKey = '$empresaId-$sedeId-$query-$page-$limit-$soloProductos';

    if (_cache.containsKey(cacheKey)) {
      emit(ProductoSedeSearchLoaded(
        productos: _cache[cacheKey]!,
        query: query,
        hasMore: _cache[cacheKey]!.length >= limit,
      ));
      return;
    }

    final filtros = ProductoFiltros(
      page: page,
      limit: limit,
      search: query,
      soloProductos: soloProductos,
    );

    final result = await _getProductos(
      empresaId: empresaId,
      sedeId: sedeId,
      filtros: filtros,
    );

    if (result is Success<ProductosPaginados>) {
      final productos = result.data.data.cast<ProductoListItem>();

      // Controlar tamaño del cache
      if (_cache.length >= _maxCacheEntries) {
        _cache.remove(_cache.keys.first);
      }
      _cache[cacheKey] = productos;

      emit(ProductoSedeSearchLoaded(
        productos: productos,
        query: query,
        hasMore: result.data.hasMore,
      ));
    } else if (result is Error) {
      final error = result as Error;
      emit(ProductoSedeSearchError(
        message: error.message,
        query: query,
        productosAnteriores: _productosActuales,
      ));
    }
  }

  /// Limpia el cache de búsquedas
  void clearCache() {
    _cache.clear();
  }

  /// Resetea el estado a inicial
  void reset() {
    _debounceTimer?.cancel();
    _cache.clear();
    emit(ProductoSedeSearchInitial());
  }

  @override
  Future<void> close() {
    _debounceTimer?.cancel();
    return super.close();
  }
}

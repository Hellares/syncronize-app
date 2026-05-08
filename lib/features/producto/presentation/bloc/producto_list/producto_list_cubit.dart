import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../../../../core/utils/resource.dart';
import '../../../domain/entities/producto_filtros.dart';
import '../../../domain/entities/producto_list_item.dart';
import '../../../domain/entities/producto.dart';
import '../../../domain/usecases/get_productos_usecase.dart';
import 'producto_list_state.dart';

@injectable
class ProductoListCubit extends Cubit<ProductoListState> {
  final GetProductosUseCase _getProductosUseCase;

  ProductoListCubit(
    this._getProductosUseCase,
  ) : super(const ProductoListInitial());

  String? _currentEmpresaId;
  String? _currentSedeId;
  ProductoFiltros _currentFiltros = const ProductoFiltros();
  List<ProductoListItem> _allProductos = [];

  /// Token monotónico de request. Cada `loadProductos`/`applyFiltros` lo
  /// incrementa. Cuando llega una respuesta y el token capturado al inicio
  /// ya no coincide con el actual, se descarta — evita que respuestas
  /// obsoletas (ej. tipear rápido en el search) sobreescriban el estado
  /// de un request más reciente.
  int _requestSeq = 0;

  /// Cache de productos completos (para evitar peticiones duplicadas)
  final Map<String, Producto> _productosFullCache = {};

  /// Carga la lista de productos.
  ///
  /// Si ya hay productos cargados y `keepListWhileFiltering=true`, mantiene
  /// la lista visible y emite `Loaded(isFiltering: true)` en vez de Loading
  /// (evita parpadeo del grid al filtrar).
  Future<void> loadProductos({
    required String empresaId,
    String? sedeId,
    ProductoFiltros? filtros,
    bool keepListWhileFiltering = false,
  }) async {
    _currentEmpresaId = empresaId;
    _currentSedeId = sedeId;
    _currentFiltros = filtros ?? const ProductoFiltros();

    final mySeq = ++_requestSeq;

    final currentState = state;
    if (keepListWhileFiltering && currentState is ProductoListLoaded) {
      // Mantener la lista actual visible, solo marcar isFiltering=true.
      emit(currentState.copyWith(isFiltering: true));
    } else {
      _allProductos = [];
      _productosFullCache.clear();
      emit(const ProductoListLoading());
    }

    final result = await _getProductosUseCase(
      empresaId: empresaId,
      sedeId: sedeId,
      filtros: _currentFiltros,
    );

    if (isClosed) return;
    // Descartar si llegó otra request más reciente.
    if (mySeq != _requestSeq) return;

    if (result is Success<ProductosPaginados>) {
      final data = result.data;
      _allProductos = data.data.cast<ProductoListItem>();

      // Almacenar productos completos en cache (si existen)
      if (data.fullProductosCache != null) {
        _productosFullCache
          ..clear()
          ..addAll(data.fullProductosCache!);
      }

      emit(ProductoListLoaded(
        productos: _allProductos,
        total: data.total,
        currentPage: data.page,
        totalPages: data.totalPages,
        hasMore: data.hasNext,
        filtros: _currentFiltros,
        isFiltering: false,
      ));
    } else if (result is Error<ProductosPaginados>) {
      emit(ProductoListError(result.message, errorCode: result.errorCode));
    }
  }

  /// Carga más productos (paginación). No incrementa `_requestSeq` para no
  /// invalidar refrescos en curso, pero igualmente captura el seq actual y
  /// descarta si el usuario gatilló un nuevo filtro mientras tanto.
  Future<void> loadMore() async {
    final currentState = state;
    if (currentState is! ProductoListLoaded) return;
    if (!currentState.hasMore) return;
    if (currentState.isFiltering) return; // ya hay un filtro en curso
    if (_currentEmpresaId == null) return;

    final mySeq = _requestSeq;
    emit(ProductoListLoadingMore(_allProductos));

    final nextPage = currentState.currentPage + 1;
    final nextFiltros = _currentFiltros.copyWith(page: nextPage);

    final result = await _getProductosUseCase(
      empresaId: _currentEmpresaId!,
      sedeId: _currentSedeId,
      filtros: nextFiltros,
    );

    if (isClosed) return;
    // Si entre tanto un filtro nuevo invalidó la lista, no agregamos esta
    // página (correspondería a otra búsqueda).
    if (mySeq != _requestSeq) return;

    if (result is Success<ProductosPaginados>) {
      final data = result.data;
      _allProductos.addAll(data.data.cast<ProductoListItem>());

      // Almacenar productos completos en cache (si existen)
      if (data.fullProductosCache != null) {
        _productosFullCache.addAll(data.fullProductosCache!);
      }

      emit(ProductoListLoaded(
        productos: _allProductos,
        total: data.total,
        currentPage: data.page,
        totalPages: data.totalPages,
        hasMore: data.hasNext,
        filtros: nextFiltros,
      ));
    } else if (result is Error<ProductosPaginados>) {
      // Volver al estado anterior en caso de error
      emit(currentState);
    }
  }

  /// Aplica filtros y recarga la lista. Mantiene la lista actual visible
  /// con un indicador de "filtrando" para evitar parpadeo (UX SaaS).
  Future<void> applyFiltros(ProductoFiltros filtros, {String? sedeId}) async {
    if (_currentEmpresaId == null) return;
    await loadProductos(
      empresaId: _currentEmpresaId!,
      sedeId: sedeId ?? _currentSedeId,
      filtros: filtros,
      keepListWhileFiltering: true,
    );
  }

  /// Resetea los filtros
  Future<void> resetFiltros({String? sedeId}) async {
    if (_currentEmpresaId == null) return;
    await loadProductos(
      empresaId: _currentEmpresaId!,
      sedeId: sedeId ?? _currentSedeId,
      filtros: const ProductoFiltros(),
      keepListWhileFiltering: true,
    );
  }

  /// Recarga la lista actual
  Future<void> reload({String? sedeId}) async {
    if (_currentEmpresaId == null) return;
    await loadProductos(
      empresaId: _currentEmpresaId!,
      sedeId: sedeId ?? _currentSedeId,
      filtros: _currentFiltros.copyWith(page: 1),
    );
  }

  /// Limpia el estado
  void clear() {
    _currentEmpresaId = null;
    _currentSedeId = null;
    _currentFiltros = const ProductoFiltros();
    _allProductos = [];
    _productosFullCache.clear();
    emit(const ProductoListInitial());
  }

  /// Invalida el cache local (llamar cuando se crea/actualiza/elimina producto)
  /// Esto sincroniza con la invalidación de cache de Redis en el backend
  void invalidateCache() {
    _productosFullCache.clear();
  }

  /// Elimina un producto específico del cache (invalidación selectiva)
  /// Usado cuando se crea/edita un producto para que el detalle haga una petición fresca
  void removeFromCache(String productoId) {
    _productosFullCache.remove(productoId);
  }

  /// Almacena un producto completo en el cache
  void cacheProductoCompleto(Producto producto) {
    _productosFullCache[producto.id] = producto;
  }

  /// Obtiene un producto completo del cache (si existe)
  Producto? getProductoFromCache(String productoId) {
    return _productosFullCache[productoId];
  }
}

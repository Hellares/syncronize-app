import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../../../../core/utils/resource.dart';
import '../../../domain/entities/producto_filtros.dart';
import '../../../domain/entities/producto_list_item.dart';
import '../../../domain/usecases/get_productos_usecase.dart';
import 'producto_list_state.dart';

@injectable
class ProductoListCubit extends Cubit<ProductoListState> {
  final GetProductosUseCase _getProductosUseCase;

  ProductoListCubit(
    this._getProductosUseCase,
  ) : super(const ProductoListInitial());

  String? _currentEmpresaId;
  ProductoFiltros _currentFiltros = const ProductoFiltros();
  List<ProductoListItem> _allProductos = [];

  /// Carga la lista de productos
  Future<void> loadProductos({
    required String empresaId,
    ProductoFiltros? filtros,
  }) async {
    _currentEmpresaId = empresaId;
    _currentFiltros = filtros ?? const ProductoFiltros();
    _allProductos = [];

    emit(const ProductoListLoading());

    final result = await _getProductosUseCase(
      empresaId: empresaId,
      filtros: _currentFiltros,
    );

    if (isClosed) return;

    if (result is Success<ProductosPaginados>) {
      final data = result.data;
      _allProductos = data.data.cast<ProductoListItem>();

      emit(ProductoListLoaded(
        productos: _allProductos,
        total: data.total,
        currentPage: data.page,
        totalPages: data.totalPages,
        hasMore: data.hasNext,
        filtros: _currentFiltros,
      ));
    } else if (result is Error<ProductosPaginados>) {
      emit(ProductoListError(result.message, errorCode: result.errorCode));
    }
  }

  /// Carga más productos (paginación)
  Future<void> loadMore() async {
    final currentState = state;
    if (currentState is! ProductoListLoaded) return;
    if (!currentState.hasMore) return;
    if (_currentEmpresaId == null) return;

    emit(ProductoListLoadingMore(_allProductos));

    final nextPage = currentState.currentPage + 1;
    final nextFiltros = _currentFiltros.copyWith(page: nextPage);

    final result = await _getProductosUseCase(
      empresaId: _currentEmpresaId!,
      filtros: nextFiltros,
    );

    if (isClosed) return;

    if (result is Success<ProductosPaginados>) {
      final data = result.data;
      _allProductos.addAll(data.data.cast<ProductoListItem>());

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

  /// Aplica filtros y recarga la lista
  Future<void> applyFiltros(ProductoFiltros filtros) async {
    if (_currentEmpresaId == null) return;
    await loadProductos(empresaId: _currentEmpresaId!, filtros: filtros);
  }

  /// Resetea los filtros
  Future<void> resetFiltros() async {
    if (_currentEmpresaId == null) return;
    await loadProductos(
      empresaId: _currentEmpresaId!,
      filtros: const ProductoFiltros(),
    );
  }

  /// Recarga la lista actual
  Future<void> reload() async {
    if (_currentEmpresaId == null) return;
    await loadProductos(
      empresaId: _currentEmpresaId!,
      filtros: _currentFiltros.copyWith(page: 1),
    );
  }

  /// Limpia el estado
  void clear() {
    _currentEmpresaId = null;
    _currentFiltros = const ProductoFiltros();
    _allProductos = [];
    emit(const ProductoListInitial());
  }
}

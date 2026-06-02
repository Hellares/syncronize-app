import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/services/location_service.dart';
import '../../data/datasources/marketplace_remote_datasource.dart';

part 'marketplace_search_state.dart';

@injectable
class MarketplaceSearchCubit extends Cubit<MarketplaceSearchState> {
  final MarketplaceRemoteDataSource _dataSource;

  MarketplaceSearchCubit(this._dataSource) : super(const MarketplaceSearchInitial());

  String? _currentSearch;
  String? _currentCategoriaId;
  String? _currentOrden;
  String? _currentMarcaId;
  double? _currentPrecioMin;
  double? _currentPrecioMax;
  String? _currentDepartamento;
  double? _currentLat;
  double? _currentLng;
  int _currentPage = 1;
  List<dynamic>? _categorias;

  // Getters para pre-cargar el sheet de filtros con lo aplicado.
  String? get ordenActual => _currentOrden;
  double? get precioMinActual => _currentPrecioMin;
  double? get precioMaxActual => _currentPrecioMax;
  String? get departamentoActual => _currentDepartamento;
  bool get tieneFiltrosActivos =>
      _currentOrden != null ||
      _currentPrecioMin != null ||
      _currentPrecioMax != null ||
      _currentDepartamento != null ||
      _currentMarcaId != null;

  /// Núcleo de búsqueda: usa SIEMPRE el estado actual de filtros (`_current*`).
  /// Así buscar/elegir categoría no pisa los filtros avanzados aplicados.
  Future<void> _buscar({int page = 1}) async {
    _currentPage = page;

    if (page == 1) {
      emit(const MarketplaceSearchLoading());
    }

    try {
      // Usar ubicación manual si la hay, si no última posición GPS conocida
      double? lat = _currentLat;
      double? lng = _currentLng;
      if (lat == null || lng == null) {
        final lastPos = LocationService.lastPosition;
        lat = lastPos?.latitude;
        lng = lastPos?.longitude;
        // Obtener GPS en background para la próxima búsqueda
        if (lastPos == null) {
          LocationService.getCurrentLocation();
        }
      }

      final result = await _dataSource.searchProductos(
        search: _currentSearch,
        categoriaId: _currentCategoriaId,
        marcaId: _currentMarcaId,
        precioMin: _currentPrecioMin,
        precioMax: _currentPrecioMax,
        departamento: _currentDepartamento,
        orden: _currentOrden,
        lat: lat,
        lng: lng,
        page: page,
        limit: 20,
      );

      final productos = (result['data'] as List<dynamic>?) ?? [];
      final total = result['total'] as int? ?? 0;
      final totalPages = result['totalPages'] as int? ?? 1;

      if (page == 1) {
        emit(MarketplaceSearchLoaded(
          productos: productos,
          total: total,
          page: page,
          totalPages: totalPages,
          search: _currentSearch,
          categoriaId: _currentCategoriaId,
          categorias: _categorias,
        ));
      } else {
        final currentState = state;
        if (currentState is MarketplaceSearchLoaded) {
          emit(MarketplaceSearchLoaded(
            productos: [...currentState.productos, ...productos],
            total: total,
            page: page,
            totalPages: totalPages,
            search: _currentSearch,
            categoriaId: _currentCategoriaId,
            categorias: _categorias,
          ));
        }
      }
    } catch (e) {
      emit(MarketplaceSearchError(e.toString()));
    }
  }

  void setUbicacion(double? lat, double? lng) {
    _currentLat = lat;
    _currentLng = lng;
    _buscar();
  }

  /// Búsqueda por texto/categoría. Conserva los filtros avanzados aplicados
  /// (precio, marca, departamento, orden) — esos solo cambian vía aplicarFiltros.
  Future<void> searchProductos({
    String? search,
    String? categoriaId,
    String? orden,
    int page = 1,
  }) async {
    _currentSearch = search;
    _currentCategoriaId = categoriaId;
    if (orden != null) _currentOrden = orden;
    await _buscar(page: page);
  }

  Future<void> loadMore() async {
    final currentState = state;
    if (currentState is! MarketplaceSearchLoaded) return;
    if (currentState.page >= currentState.totalPages) return;

    await _buscar(page: _currentPage + 1);
  }

  Future<void> filterByCategoria(String? categoriaId) async {
    _currentCategoriaId = categoriaId;
    await _buscar();
  }

  /// Aplica los filtros avanzados del sheet (precio, marca, departamento, orden).
  Future<void> aplicarFiltros({
    String? marcaId,
    double? precioMin,
    double? precioMax,
    String? departamento,
    String? orden,
  }) async {
    _currentMarcaId = marcaId;
    _currentPrecioMin = precioMin;
    _currentPrecioMax = precioMax;
    _currentDepartamento = departamento;
    _currentOrden = orden;
    await _buscar();
  }

  Future<void> limpiarFiltros() async {
    _currentMarcaId = null;
    _currentPrecioMin = null;
    _currentPrecioMax = null;
    _currentDepartamento = null;
    _currentOrden = null;
    await _buscar();
  }

  Future<void> refresh() async {
    await _buscar();
  }

  Future<void> loadCategorias() async {
    try {
      final categorias = await _dataSource.getCategorias();
      _categorias = categorias;

      if (state is MarketplaceSearchLoaded) {
        emit((state as MarketplaceSearchLoaded).copyWith(categorias: categorias));
      }
    } catch (_) {}
  }
}

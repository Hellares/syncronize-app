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
  double? _currentLat;
  double? _currentLng;
  int _currentPage = 1;
  List<dynamic>? _categorias;

  void setUbicacion(double? lat, double? lng) {
    _currentLat = lat;
    _currentLng = lng;
    searchProductos(
      search: _currentSearch,
      categoriaId: _currentCategoriaId,
      orden: _currentOrden,
    );
  }

  Future<void> searchProductos({
    String? search,
    String? categoriaId,
    String? orden,
    int page = 1,
  }) async {
    _currentSearch = search;
    _currentCategoriaId = categoriaId;
    _currentOrden = orden;
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
        search: search,
        categoriaId: categoriaId,
        orden: orden,
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
          search: search,
          categoriaId: categoriaId,
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
            search: search,
            categoriaId: categoriaId,
            categorias: _categorias,
          ));
        }
      }
    } catch (e) {
      emit(MarketplaceSearchError(e.toString()));
    }
  }

  Future<void> loadMore() async {
    final currentState = state;
    if (currentState is! MarketplaceSearchLoaded) return;
    if (currentState.page >= currentState.totalPages) return;

    await searchProductos(
      search: _currentSearch,
      categoriaId: _currentCategoriaId,
      orden: _currentOrden,
      page: _currentPage + 1,
    );
  }

  Future<void> filterByCategoria(String? categoriaId) async {
    await searchProductos(
      search: _currentSearch,
      categoriaId: categoriaId,
      orden: _currentOrden,
    );
  }

  Future<void> refresh() async {
    await searchProductos(
      search: _currentSearch,
      categoriaId: _currentCategoriaId,
      orden: _currentOrden,
    );
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

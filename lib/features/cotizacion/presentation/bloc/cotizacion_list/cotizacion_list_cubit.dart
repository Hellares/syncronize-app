import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../../../../core/utils/resource.dart';
import '../../../domain/entities/cotizacion.dart';
import '../../../domain/entities/cotizaciones_page.dart';
import '../../../domain/usecases/get_cotizaciones_usecase.dart';
import 'cotizacion_list_state.dart';

/// Lista de cotizaciones con paginación por CURSOR (patrón estándar de
/// listas transaccionales: primera página chica → scroll infinito).
/// El search/filtros son server-side (índices trigram) y resetean el cursor.
@injectable
class CotizacionListCubit extends Cubit<CotizacionListState> {
  final GetCotizacionesUseCase _getCotizacionesUseCase;

  CotizacionListCubit(this._getCotizacionesUseCase)
      : super(const CotizacionListInitial());

  /// Tamaño de página: chico para que la primera pinte rápido; el resto
  /// llega solo con el scroll.
  static const int _pageSize = 30;

  String? _currentEmpresaId;
  EstadoCotizacion? _filtroEstado;
  String? _filtroSedeId;
  String? _searchQuery;
  String? _nextCursor;

  /// Token monotónico: cada carga nueva lo incrementa; las respuestas en
  /// vuelo de cargas viejas (cambio de filtro/búsqueda en el medio) se
  /// descartan comparando su token con el vigente.
  int _loadId = 0;

  /// Carga la PRIMERA página (resetea cursor). Filtros/search van al server.
  Future<void> loadCotizaciones({
    required String empresaId,
    EstadoCotizacion? estado,
    String? sedeId,
    String? search,
  }) async {
    if (empresaId.isEmpty) {
      emit(const CotizacionListError('ID de empresa no valido'));
      return;
    }

    final myId = ++_loadId;
    _currentEmpresaId = empresaId;
    _filtroEstado = estado;
    _filtroSedeId = sedeId;
    _searchQuery = search;
    _nextCursor = null;

    emit(const CotizacionListLoading());

    final result = await _getCotizacionesUseCase.paginado(
      sedeId: sedeId,
      estado: estado?.apiValue,
      search: search,
      limit: _pageSize,
    );
    if (isClosed || myId != _loadId) return;

    if (result is Success<CotizacionesPage>) {
      _nextCursor = result.data.nextCursor;
      emit(CotizacionListLoaded(
        cotizaciones: result.data.cotizaciones,
        filtroEstado: estado,
        filtroSedeId: sedeId,
        hasMore: result.data.hasMore,
      ));
    } else if (result is Error<CotizacionesPage>) {
      emit(CotizacionListError(result.message));
    }
  }

  /// Trae la siguiente página y la appendea (scroll infinito).
  Future<void> loadMore() async {
    final actual = state;
    if (actual is! CotizacionListLoaded) return;
    if (!actual.hasMore || actual.isLoadingMore) return;
    if (_nextCursor == null) return;

    final myId = _loadId;
    emit(actual.copyWith(isLoadingMore: true));

    final result = await _getCotizacionesUseCase.paginado(
      sedeId: _filtroSedeId,
      estado: _filtroEstado?.apiValue,
      search: _searchQuery,
      limit: _pageSize,
      cursor: _nextCursor,
    );
    // Si cambió el filtro/búsqueda mientras esta página volaba, descartar.
    if (isClosed || myId != _loadId) return;

    if (result is Success<CotizacionesPage>) {
      _nextCursor = result.data.nextCursor;
      emit(actual.copyWith(
        cotizaciones: [...actual.cotizaciones, ...result.data.cotizaciones],
        hasMore: result.data.hasMore,
        isLoadingMore: false,
      ));
    } else {
      // Falla al paginar: se conserva lo cargado y se re-habilita el footer.
      emit(actual.copyWith(isLoadingMore: false));
    }
  }

  /// Recarga desde la primera página (pull-to-refresh).
  Future<void> reload() async {
    if (_currentEmpresaId == null) return;

    await loadCotizaciones(
      empresaId: _currentEmpresaId!,
      estado: _filtroEstado,
      sedeId: _filtroSedeId,
      search: _searchQuery,
    );
  }

  /// Buscar cotizaciones (server-side, resetea cursor)
  Future<void> search(String query) async {
    if (_currentEmpresaId == null) return;

    await loadCotizaciones(
      empresaId: _currentEmpresaId!,
      estado: _filtroEstado,
      sedeId: _filtroSedeId,
      search: query.isEmpty ? null : query,
    );
  }

  /// Filtrar por estado
  Future<void> filterByEstado(EstadoCotizacion? estado) async {
    if (_currentEmpresaId == null) return;

    await loadCotizaciones(
      empresaId: _currentEmpresaId!,
      estado: estado,
      sedeId: _filtroSedeId,
      search: _searchQuery,
    );
  }

  /// Filtrar por sede
  Future<void> filterBySede(String? sedeId) async {
    if (_currentEmpresaId == null) return;

    await loadCotizaciones(
      empresaId: _currentEmpresaId!,
      estado: _filtroEstado,
      sedeId: sedeId,
      search: _searchQuery,
    );
  }
}

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../../../../core/utils/resource.dart';
import '../../../../../core/utils/date_formatter.dart';
import '../../../domain/entities/venta.dart';
import '../../../domain/entities/ventas_page.dart';
import '../../../domain/usecases/get_ventas_usecase.dart';
import 'venta_list_state.dart';

/// Lista de ventas con paginación por CURSOR + resumen agregado server-side
/// (patrón estándar de listas transaccionales — ver cotizaciones). Todos los
/// filtros (estado, sede, fechas, canal, search) van al server y resetean el
/// cursor; el chip del total se alimenta del `resumen` (exacto aunque haya
/// páginas sin cargar).
@injectable
class VentaListCubit extends Cubit<VentaListState> {
  final GetVentasUseCase _getVentasUseCase;

  VentaListCubit(this._getVentasUseCase) : super(const VentaListInitial());

  static const int _pageSize = 30;

  String? _currentEmpresaId;
  EstadoVenta? _filtroEstado;
  String? _filtroSedeId;
  String? _searchQuery;
  DateTime? _filtroFechaDesde;
  DateTime? _filtroFechaHasta;
  String? _filtroCanal;
  String? _nextCursor;

  /// Token monotónico: descarta respuestas en vuelo de cargas viejas
  /// cuando el usuario cambia filtros/búsqueda en el medio.
  int _loadId = 0;

  Future<void> loadVentas({
    required String empresaId,
    EstadoVenta? estado,
    String? sedeId,
    String? search,
    DateTime? fechaDesde,
    DateTime? fechaHasta,
    String? canalVenta,
  }) async {
    if (empresaId.isEmpty) {
      emit(const VentaListError('ID de empresa no valido'));
      return;
    }

    final myId = ++_loadId;
    _currentEmpresaId = empresaId;
    _filtroEstado = estado;
    _filtroSedeId = sedeId;
    _searchQuery = search;
    _filtroFechaDesde = fechaDesde;
    _filtroFechaHasta = fechaHasta;
    _filtroCanal = canalVenta;
    _nextCursor = null;

    emit(const VentaListLoading());

    final result = await _getVentasUseCase.paginado(
      sedeId: sedeId,
      estado: estado?.apiValue,
      search: search,
      fechaDesde: _toUtcIsoDayStart(fechaDesde),
      fechaHasta: _toUtcIsoDayEnd(fechaHasta),
      canalVenta: canalVenta,
      limit: _pageSize,
    );
    if (isClosed || myId != _loadId) return;

    if (result is Success<VentasPage>) {
      _nextCursor = result.data.nextCursor;
      emit(VentaListLoaded(
        ventas: result.data.ventas,
        filtroEstado: estado,
        filtroSedeId: sedeId,
        filtroFechaDesde: fechaDesde,
        filtroFechaHasta: fechaHasta,
        filtroCanal: canalVenta,
        hasMore: result.data.hasMore,
        resumen: result.data.resumen,
      ));
    } else if (result is Error<VentasPage>) {
      emit(VentaListError(result.message));
    }
  }

  /// Trae la siguiente página y la appendea (scroll infinito).
  Future<void> loadMore() async {
    final actual = state;
    if (actual is! VentaListLoaded) return;
    if (!actual.hasMore || actual.isLoadingMore) return;
    if (_nextCursor == null) return;

    final myId = _loadId;
    emit(actual.copyWith(isLoadingMore: true));

    final result = await _getVentasUseCase.paginado(
      sedeId: _filtroSedeId,
      estado: _filtroEstado?.apiValue,
      search: _searchQuery,
      fechaDesde: _toUtcIsoDayStart(_filtroFechaDesde),
      fechaHasta: _toUtcIsoDayEnd(_filtroFechaHasta),
      canalVenta: _filtroCanal,
      limit: _pageSize,
      cursor: _nextCursor,
    );
    if (isClosed || myId != _loadId) return;

    if (result is Success<VentasPage>) {
      _nextCursor = result.data.nextCursor;
      emit(actual.copyWith(
        ventas: [...actual.ventas, ...result.data.ventas],
        hasMore: result.data.hasMore,
        isLoadingMore: false,
        resumen: result.data.resumen,
      ));
    } else {
      // Falla al paginar: conserva lo cargado y re-habilita el footer.
      emit(actual.copyWith(isLoadingMore: false));
    }
  }

  Future<void> reload() async {
    if (_currentEmpresaId == null) return;
    await loadVentas(
      empresaId: _currentEmpresaId!,
      estado: _filtroEstado,
      sedeId: _filtroSedeId,
      search: _searchQuery,
      fechaDesde: _filtroFechaDesde,
      fechaHasta: _filtroFechaHasta,
      canalVenta: _filtroCanal,
    );
  }

  Future<void> search(String query) async {
    if (_currentEmpresaId == null) return;
    await loadVentas(
      empresaId: _currentEmpresaId!,
      estado: _filtroEstado,
      sedeId: _filtroSedeId,
      search: query.isEmpty ? null : query,
      fechaDesde: _filtroFechaDesde,
      fechaHasta: _filtroFechaHasta,
      canalVenta: _filtroCanal,
    );
  }

  Future<void> filterByEstado(EstadoVenta? estado) async {
    if (_currentEmpresaId == null) return;
    await loadVentas(
      empresaId: _currentEmpresaId!,
      estado: estado,
      sedeId: _filtroSedeId,
      search: _searchQuery,
      fechaDesde: _filtroFechaDesde,
      fechaHasta: _filtroFechaHasta,
      canalVenta: _filtroCanal,
    );
  }

  Future<void> filterBySede(String? sedeId) async {
    if (_currentEmpresaId == null) return;
    await loadVentas(
      empresaId: _currentEmpresaId!,
      estado: _filtroEstado,
      sedeId: sedeId,
      search: _searchQuery,
      fechaDesde: _filtroFechaDesde,
      fechaHasta: _filtroFechaHasta,
      canalVenta: _filtroCanal,
    );
  }

  /// Filtra por canal (Mostrador/Marketplace/Cotización) — SERVER-side:
  /// con paginación el filtro local dejaría totales inconsistentes.
  Future<void> filterByCanal(String? canalVenta) async {
    if (_currentEmpresaId == null) return;
    await loadVentas(
      empresaId: _currentEmpresaId!,
      estado: _filtroEstado,
      sedeId: _filtroSedeId,
      search: _searchQuery,
      fechaDesde: _filtroFechaDesde,
      fechaHasta: _filtroFechaHasta,
      canalVenta: canalVenta,
    );
  }

  /// Filtra el listado por un rango de fechas. Si ambos son null, limpia
  /// el filtro. Si solo se pasa `desde` o solo `hasta`, el otro extremo
  /// queda abierto (backend respeta `gte`/`lte` independientes).
  Future<void> filterByFechas(DateTime? desde, DateTime? hasta) async {
    if (_currentEmpresaId == null) return;
    await loadVentas(
      empresaId: _currentEmpresaId!,
      estado: _filtroEstado,
      sedeId: _filtroSedeId,
      search: _searchQuery,
      fechaDesde: desde,
      fechaHasta: hasta,
      canalVenta: _filtroCanal,
    );
  }

  /// Convierte una fecha local al inicio del día (00:00 hora local) en UTC.
  /// Usar `DateTime.utc(y,m,d)` directo plantaba los números locales en UTC,
  /// corriendo el rango por el offset TZ (en Perú: filtro "Hoy" buscaba ayer
  /// 19:00 → hoy 18:59 UTC, perdiendo ventas de la noche).
  String? _toUtcIsoDayStart(DateTime? date) {
    if (date == null) return null;
    return DateFormatter.toUtcIso(DateFormatter.startOfDay(date));
  }

  /// Convierte una fecha local al fin del día (23:59:59 hora local) en UTC.
  String? _toUtcIsoDayEnd(DateTime? date) {
    if (date == null) return null;
    return DateFormatter.toUtcIso(DateFormatter.endOfDay(date));
  }
}

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../../../../core/utils/resource.dart';
import '../../../domain/entities/venta.dart';
import '../../../domain/usecases/get_ventas_usecase.dart';
import 'venta_list_state.dart';

@injectable
class VentaListCubit extends Cubit<VentaListState> {
  final GetVentasUseCase _getVentasUseCase;

  VentaListCubit(this._getVentasUseCase) : super(const VentaListInitial());

  String? _currentEmpresaId;
  EstadoVenta? _filtroEstado;
  String? _filtroSedeId;
  String? _searchQuery;
  DateTime? _filtroFechaDesde;
  DateTime? _filtroFechaHasta;

  Future<void> loadVentas({
    required String empresaId,
    EstadoVenta? estado,
    String? sedeId,
    String? search,
    DateTime? fechaDesde,
    DateTime? fechaHasta,
  }) async {
    if (empresaId.isEmpty) {
      emit(const VentaListError('ID de empresa no valido'));
      return;
    }

    _currentEmpresaId = empresaId;
    _filtroEstado = estado;
    _filtroSedeId = sedeId;
    _searchQuery = search;
    _filtroFechaDesde = fechaDesde;
    _filtroFechaHasta = fechaHasta;

    emit(const VentaListLoading());

    final result = await _getVentasUseCase(
      sedeId: sedeId,
      estado: estado?.apiValue,
      search: search,
      fechaDesde: _toUtcIsoDayStart(fechaDesde),
      fechaHasta: _toUtcIsoDayEnd(fechaHasta),
    );
    if (isClosed) return;

    if (result is Success<List<Venta>>) {
      emit(VentaListLoaded(
        ventas: result.data,
        filtroEstado: estado,
        filtroSedeId: sedeId,
        filtroFechaDesde: fechaDesde,
        filtroFechaHasta: fechaHasta,
      ));
    } else if (result is Error<List<Venta>>) {
      emit(VentaListError(result.message));
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
    );
  }

  /// Convierte una fecha local al inicio del día en UTC ISO 8601.
  /// El backend hace `new Date(string)` y compara con `fechaVenta` (timestamp
  /// con TZ). Para que "1 mayo" incluya las ventas del día completo, mandamos
  /// 00:00:00 del día en UTC.
  String? _toUtcIsoDayStart(DateTime? date) {
    if (date == null) return null;
    return DateTime.utc(date.year, date.month, date.day).toIso8601String();
  }

  /// Convierte una fecha local al fin del día (23:59:59.999) en UTC ISO 8601.
  /// Garantiza que las ventas del último día del rango queden incluidas.
  String? _toUtcIsoDayEnd(DateTime? date) {
    if (date == null) return null;
    return DateTime.utc(date.year, date.month, date.day, 23, 59, 59, 999)
        .toIso8601String();
  }
}

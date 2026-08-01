import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../../../../core/utils/date_formatter.dart';
import '../../../../../core/utils/resource.dart';
import '../../../domain/entities/orden_servicio.dart';
import '../../../domain/entities/servicio_filtros.dart';
import '../../../domain/usecases/get_ordenes_servicio_usecase.dart';
import 'orden_servicio_list_state.dart';

@injectable
class OrdenServicioListCubit extends Cubit<OrdenServicioListState> {
  final GetOrdenesServicioUseCase _getOrdenesUseCase;

  OrdenServicioListCubit(this._getOrdenesUseCase)
      : super(const OrdenServicioListInitial());

  String? _currentEmpresaId;
  OrdenServicioFiltros _currentFiltros = const OrdenServicioFiltros();
  List<OrdenServicio> _allOrdenes = [];
  bool _isLoadingMore = false;
  bool _isClienteMode = false;

  Future<void> loadOrdenes({
    required String empresaId,
    OrdenServicioFiltros? filtros,
    bool asCliente = false,
  }) async {
    _currentEmpresaId = empresaId;
    _currentFiltros = filtros ?? const OrdenServicioFiltros();
    _allOrdenes = [];
    _isClienteMode = asCliente;

    emit(const OrdenServicioListLoading());

    final result = await _getOrdenesUseCase(
      empresaId: empresaId,
      filtros: _currentFiltros,
      asCliente: asCliente,
    );

    if (isClosed) return;

    if (result is Success<OrdenesServicioPaginadas>) {
      final data = result.data;
      _allOrdenes = data.data;

      emit(OrdenServicioListLoaded(
        ordenes: _allOrdenes,
        total: data.total,
        hasMore: data.hasNext,
        nextCursor: data.nextCursor,
        filtros: _currentFiltros,
      ));
    } else if (result is Error<OrdenesServicioPaginadas>) {
      emit(OrdenServicioListError(result.message, errorCode: result.errorCode));
    }
  }

  Future<void> loadMore() async {
    final currentState = state;
    if (currentState is! OrdenServicioListLoaded) return;
    if (!currentState.hasMore || currentState.nextCursor == null) return;
    if (_currentEmpresaId == null) return;
    if (_isLoadingMore) return;
    _isLoadingMore = true;

    emit(OrdenServicioListLoadingMore(_allOrdenes));

    final nextFiltros = _currentFiltros.copyWith(cursor: currentState.nextCursor);
    final result = await _getOrdenesUseCase(
      empresaId: _currentEmpresaId!,
      filtros: nextFiltros,
      asCliente: _isClienteMode,
    );

    if (isClosed) {
      _isLoadingMore = false;
      return;
    }
    _isLoadingMore = false;

    if (result is Success<OrdenesServicioPaginadas>) {
      final data = result.data;
      _allOrdenes = [..._allOrdenes, ...data.data];

      emit(OrdenServicioListLoaded(
        ordenes: _allOrdenes,
        total: data.total,
        hasMore: data.hasNext,
        nextCursor: data.nextCursor,
        filtros: _currentFiltros,
      ));
    } else if (result is Error<OrdenesServicioPaginadas>) {
      // Conserva la lista y el cursor (reintentable), pero avisa del fallo.
      emit(OrdenServicioListLoaded(
        ordenes: _allOrdenes,
        total: currentState.total,
        hasMore: currentState.hasMore,
        nextCursor: currentState.nextCursor,
        filtros: _currentFiltros,
        loadMoreError: result.message,
      ));
    }
  }

  Future<void> applyFiltros(OrdenServicioFiltros filtros) async {
    if (_currentEmpresaId == null) return;
    await loadOrdenes(
      empresaId: _currentEmpresaId!,
      filtros: filtros.copyWith(clearCursor: true),
      asCliente: _isClienteMode,
    );
  }

  Future<void> filterByEstado(String? estado) async {
    if (_currentEmpresaId == null) return;
    final filtros = estado != null
        ? _currentFiltros.copyWith(estado: estado, clearCursor: true)
        : _currentFiltros.copyWith(clearEstado: true, clearCursor: true);
    await loadOrdenes(
      empresaId: _currentEmpresaId!,
      filtros: filtros,
      asCliente: _isClienteMode,
    );
  }

  /// Filtra por rango de fechas (atajos Hoy / Ayer / Esta semana / Este mes).
  /// Pasar ambos en null limpia el filtro.
  Future<void> filterByFechas(DateTime? desde, DateTime? hasta) async {
    if (_currentEmpresaId == null) return;
    final filtros = _currentFiltros.copyWith(
      fechaDesde: _toUtcIsoDayStart(desde),
      fechaHasta: _toUtcIsoDayEnd(hasta),
      clearFechaDesde: desde == null,
      clearFechaHasta: hasta == null,
      clearCursor: true,
    );
    await loadOrdenes(
      empresaId: _currentEmpresaId!,
      filtros: filtros,
      asCliente: _isClienteMode,
    );
  }

  /// Inicio del día en hora LOCAL, serializado en UTC. Mandar `yyyy-MM-dd`
  /// pelado hace que el backend lo lea como medianoche UTC y en Perú el rango
  /// arranque a las 19:00 del día anterior. Mismo criterio que ventas.
  static String? _toUtcIsoDayStart(DateTime? date) =>
      date == null ? null : DateFormatter.toUtcIso(DateFormatter.startOfDay(date));

  /// Fin del día en hora LOCAL (23:59:59), serializado en UTC.
  static String? _toUtcIsoDayEnd(DateTime? date) =>
      date == null ? null : DateFormatter.toUtcIso(DateFormatter.endOfDay(date));

  Future<void> refresh() async {
    if (_currentEmpresaId == null) return;
    await loadOrdenes(
      empresaId: _currentEmpresaId!,
      filtros: _currentFiltros.copyWith(clearCursor: true),
      asCliente: _isClienteMode,
    );
  }
}

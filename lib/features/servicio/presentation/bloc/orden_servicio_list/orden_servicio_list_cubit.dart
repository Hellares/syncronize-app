import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
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

  Future<void> loadOrdenes({
    required String empresaId,
    OrdenServicioFiltros? filtros,
  }) async {
    _currentEmpresaId = empresaId;
    _currentFiltros = filtros ?? const OrdenServicioFiltros();
    _allOrdenes = [];

    emit(const OrdenServicioListLoading());

    final result = await _getOrdenesUseCase(
      empresaId: empresaId,
      filtros: _currentFiltros,
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
      emit(OrdenServicioListError(result.message, errorCode: result.errorCode));
    }
  }

  Future<void> applyFiltros(OrdenServicioFiltros filtros) async {
    if (_currentEmpresaId == null) return;
    await loadOrdenes(empresaId: _currentEmpresaId!, filtros: filtros.copyWith(clearCursor: true));
  }

  Future<void> filterByEstado(String? estado) async {
    if (_currentEmpresaId == null) return;
    final filtros = estado != null
        ? _currentFiltros.copyWith(estado: estado, clearCursor: true)
        : _currentFiltros.copyWith(clearEstado: true, clearCursor: true);
    await loadOrdenes(empresaId: _currentEmpresaId!, filtros: filtros);
  }

  Future<void> refresh() async {
    if (_currentEmpresaId == null) return;
    await loadOrdenes(empresaId: _currentEmpresaId!, filtros: _currentFiltros.copyWith(clearCursor: true));
  }
}

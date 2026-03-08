import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../../../../core/utils/resource.dart';
import '../../../domain/entities/servicio.dart';
import '../../../domain/entities/servicio_filtros.dart';
import '../../../domain/usecases/get_servicios_usecase.dart';
import 'servicio_list_state.dart';

@injectable
class ServicioListCubit extends Cubit<ServicioListState> {
  final GetServiciosUseCase _getServiciosUseCase;

  ServicioListCubit(this._getServiciosUseCase) : super(const ServicioListInitial());

  String? _currentEmpresaId;
  ServicioFiltros _currentFiltros = const ServicioFiltros();
  List<Servicio> _allServicios = [];
  bool _isLoadingMore = false;

  Future<void> loadServicios({
    required String empresaId,
    ServicioFiltros? filtros,
  }) async {
    _currentEmpresaId = empresaId;
    _currentFiltros = filtros ?? const ServicioFiltros();
    _allServicios = [];

    emit(const ServicioListLoading());

    final result = await _getServiciosUseCase(
      empresaId: empresaId,
      filtros: _currentFiltros,
    );

    if (isClosed) return;

    if (result is Success<ServiciosPaginados>) {
      final data = result.data;
      _allServicios = data.data;

      emit(ServicioListLoaded(
        servicios: _allServicios,
        total: data.total,
        currentPage: data.page,
        totalPages: data.totalPages,
        hasMore: data.hasNext,
        filtros: _currentFiltros,
      ));
    } else if (result is Error<ServiciosPaginados>) {
      emit(ServicioListError(result.message, errorCode: result.errorCode));
    }
  }

  Future<void> loadMore() async {
    final currentState = state;
    if (currentState is! ServicioListLoaded) return;
    if (!currentState.hasMore) return;
    if (_currentEmpresaId == null) return;
    if (_isLoadingMore) return;
    _isLoadingMore = true;

    emit(ServicioListLoadingMore(_allServicios));

    final nextFiltros = _currentFiltros.copyWith(page: currentState.currentPage + 1);
    final result = await _getServiciosUseCase(
      empresaId: _currentEmpresaId!,
      filtros: nextFiltros,
    );

    if (isClosed) {
      _isLoadingMore = false;
      return;
    }
    _isLoadingMore = false;

    if (result is Success<ServiciosPaginados>) {
      final data = result.data;
      _allServicios = [..._allServicios, ...data.data];
      _currentFiltros = nextFiltros;

      emit(ServicioListLoaded(
        servicios: _allServicios,
        total: data.total,
        currentPage: data.page,
        totalPages: data.totalPages,
        hasMore: data.hasNext,
        filtros: _currentFiltros,
      ));
    } else if (result is Error<ServiciosPaginados>) {
      emit(ServicioListError(result.message, errorCode: result.errorCode));
    }
  }

  Future<void> applyFiltros(ServicioFiltros filtros) async {
    if (_currentEmpresaId == null) return;
    await loadServicios(empresaId: _currentEmpresaId!, filtros: filtros.copyWith(page: 1));
  }

  Future<void> refresh() async {
    if (_currentEmpresaId == null) return;
    await loadServicios(empresaId: _currentEmpresaId!, filtros: _currentFiltros.copyWith(page: 1));
  }
}

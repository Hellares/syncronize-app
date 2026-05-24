import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../../domain/entities/movimiento_caja.dart';
import '../../domain/entities/tesoreria.dart';
import '../../domain/usecases/crear_ajuste_tesoreria_usecase.dart';
import '../../domain/usecases/get_tesoreria_movimientos_usecase.dart';
import '../../domain/usecases/get_tesoreria_resumen_usecase.dart';
import 'tesoreria_state.dart';

@injectable
class TesoreriaCubit extends Cubit<TesoreriaState> {
  final GetTesoreriaResumenUseCase _getResumen;
  final GetTesoreriaMovimientosUseCase _getMovimientos;
  final CrearAjusteTesoreriaUseCase _crearAjuste;

  String? _sedeId;

  TesoreriaCubit(
    this._getResumen,
    this._getMovimientos,
    this._crearAjuste,
  ) : super(const TesoreriaInitial());

  /// Carga inicial: resumen + primera pagina de movimientos.
  Future<void> load(String sedeId) async {
    _sedeId = sedeId;
    emit(const TesoreriaLoading());

    final resumenRes = await _getResumen(sedeId);
    if (isClosed) return;

    if (resumenRes is Error<TesoreriaResumen>) {
      emit(TesoreriaError(resumenRes.message));
      return;
    }

    final resumen = (resumenRes as Success<TesoreriaResumen>).data;
    final filter = const TesoreriaMovimientosFilter();

    final movRes = await _getMovimientos(sedeId: sedeId, filter: filter);
    if (isClosed) return;

    if (movRes is Error<TesoreriaMovimientosPage>) {
      emit(TesoreriaError(movRes.message));
      return;
    }

    emit(TesoreriaLoaded(
      resumen: resumen,
      movimientos: (movRes as Success<TesoreriaMovimientosPage>).data,
      filter: filter,
    ));
  }

  /// Aplica un nuevo filtro y refetchea movimientos. NO recarga el resumen
  /// (ese es un agregado total, no depende de filtros).
  Future<void> applyFilter(TesoreriaMovimientosFilter filter) async {
    if (state is! TesoreriaLoaded || _sedeId == null) return;
    final current = state as TesoreriaLoaded;

    emit(current.copyWith(refreshingMovimientos: true, filter: filter));

    final res = await _getMovimientos(
      sedeId: _sedeId!,
      filter: filter.copyWith(page: 1),
    );
    if (isClosed) return;

    if (res is Error<TesoreriaMovimientosPage>) {
      emit(current.copyWith(refreshingMovimientos: false));
      return;
    }

    emit(current.copyWith(
      movimientos: (res as Success<TesoreriaMovimientosPage>).data,
      filter: filter.copyWith(page: 1),
      refreshingMovimientos: false,
    ));
  }

  /// Refresca resumen + movimientos manteniendo el filtro actual.
  Future<void> refresh() async {
    if (_sedeId == null) return;
    final currentFilter = state is TesoreriaLoaded
        ? (state as TesoreriaLoaded).filter
        : const TesoreriaMovimientosFilter();
    await load(_sedeId!);
    if (state is TesoreriaLoaded && currentFilter.page > 1) {
      await applyFilter(currentFilter);
    }
  }

  /// Crea un ajuste manual y refresca todo.
  Future<Resource<MovimientoCaja>> crearAjuste({
    required TipoMovimientoCaja tipo,
    required MetodoPago metodoPago,
    required double monto,
    required String descripcion,
    String? categoriaGastoId,
  }) async {
    if (_sedeId == null) {
      return Error('Tesoreria no cargada', errorCode: 'NOT_LOADED');
    }
    final res = await _crearAjuste(
      sedeId: _sedeId!,
      tipo: tipo,
      metodoPago: metodoPago,
      monto: monto,
      descripcion: descripcion,
      categoriaGastoId: categoriaGastoId,
    );
    if (res is Success<MovimientoCaja>) {
      await refresh();
    }
    return res;
  }
}

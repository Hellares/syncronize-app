import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../../domain/entities/movimiento_caja.dart';
import '../../domain/entities/resumen_caja.dart';
import '../../domain/usecases/crear_movimiento_usecase.dart';
import '../../domain/usecases/get_movimientos_usecase.dart';
import '../../domain/usecases/get_resumen_usecase.dart';
import 'caja_movimientos_state.dart';

@injectable
class CajaMovimientosCubit extends Cubit<CajaMovimientosState> {
  final GetMovimientosUseCase _getMovimientosUseCase;
  final CrearMovimientoUseCase _crearMovimientoUseCase;
  final GetResumenUseCase _getResumenUseCase;

  String? _currentCajaId;

  CajaMovimientosCubit(
    this._getMovimientosUseCase,
    this._crearMovimientoUseCase,
    this._getResumenUseCase,
  ) : super(const CajaMovimientosInitial());

  Future<void> loadMovimientos(String cajaId) async {
    _currentCajaId = cajaId;
    emit(const CajaMovimientosLoading());

    final results = await Future.wait([
      _getMovimientosUseCase(cajaId: cajaId),
      _getResumenUseCase(cajaId: cajaId),
    ]);
    if (isClosed) return;

    final movimientosResult = results[0] as Resource<List<MovimientoCaja>>;
    final resumenResult = results[1] as Resource<ResumenCaja>;

    if (movimientosResult is Success<List<MovimientoCaja>>) {
      ResumenCaja? resumen;
      if (resumenResult is Success<ResumenCaja>) {
        resumen = resumenResult.data;
      }
      emit(CajaMovimientosLoaded(
        movimientos: movimientosResult.data,
        resumen: resumen,
      ));
    } else if (movimientosResult is Error<List<MovimientoCaja>>) {
      emit(CajaMovimientosError(movimientosResult.message));
    }
  }

  Future<bool> crearMovimiento({
    required String cajaId,
    required TipoMovimientoCaja tipo,
    required CategoriaMovimientoCaja categoria,
    required MetodoPago metodoPago,
    required double monto,
    String? descripcion,
  }) async {
    final result = await _crearMovimientoUseCase(
      cajaId: cajaId,
      tipo: tipo,
      categoria: categoria,
      metodoPago: metodoPago,
      monto: monto,
      descripcion: descripcion,
    );

    if (result is Success<void>) {
      // Reload movements after creating one
      await loadMovimientos(cajaId);
      return true;
    }
    return false;
  }

  Future<void> reload() async {
    if (_currentCajaId != null) {
      await loadMovimientos(_currentCajaId!);
    }
  }
}

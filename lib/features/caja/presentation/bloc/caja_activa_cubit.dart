import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../../domain/entities/caja.dart';
import '../../domain/usecases/abrir_caja_usecase.dart';
import '../../domain/usecases/cerrar_caja_usecase.dart';
import '../../domain/usecases/get_caja_activa_usecase.dart';
import '../../domain/usecases/get_caja_by_id_usecase.dart';
import 'caja_activa_state.dart';

@injectable
class CajaActivaCubit extends Cubit<CajaActivaState> {
  final GetCajaActivaUseCase _getCajaActivaUseCase;
  final GetCajaByIdUseCase _getCajaByIdUseCase;
  final AbrirCajaUseCase _abrirCajaUseCase;
  final CerrarCajaUseCase _cerrarCajaUseCase;

  CajaActivaCubit(
    this._getCajaActivaUseCase,
    this._getCajaByIdUseCase,
    this._abrirCajaUseCase,
    this._cerrarCajaUseCase,
  ) : super(const CajaActivaInitial());

  Future<void> loadCajaActiva() async {
    emit(const CajaActivaLoading());

    final result = await _getCajaActivaUseCase();
    if (isClosed) return;

    if (result is Success<Caja?>) {
      if (result.data != null) {
        emit(CajaActivaAbierta(result.data!));
      } else {
        emit(const CajaActivaSinCaja());
      }
    } else if (result is Error<Caja?>) {
      emit(CajaActivaError(result.message));
    }
  }

  /// Carga una caja por id (vista admin desde el monitor sobre caja
  /// ajena). Reusa CajaActivaAbierta para que toda la CajaPage funcione
  /// igual — el flag `esVistaAdmin` lo maneja la page localmente.
  Future<void> loadCajaPorId(String id) async {
    emit(const CajaActivaLoading());

    final result = await _getCajaByIdUseCase(id);
    if (isClosed) return;

    if (result is Success<Caja>) {
      emit(CajaActivaAbierta(result.data));
    } else if (result is Error<Caja>) {
      emit(CajaActivaError(result.message));
    }
  }

  Future<void> abrirCaja({
    required String sedeId,
    required double montoApertura,
    String? observaciones,
    String? sedeFacturacionId,
  }) async {
    emit(const CajaActivaLoading());

    final result = await _abrirCajaUseCase(
      sedeId: sedeId,
      montoApertura: montoApertura,
      observaciones: observaciones,
      sedeFacturacionId: sedeFacturacionId,
    );
    if (isClosed) return;

    if (result is Success<Caja>) {
      emit(CajaActivaAbierta(result.data));
    } else if (result is Error<Caja>) {
      emit(CajaActivaError(result.message));
    }
  }

  Future<void> cerrarCaja({
    required String cajaId,
    required List<Map<String, dynamic>> conteos,
    String? observaciones,
  }) async {
    emit(const CajaActivaLoading());

    final result = await _cerrarCajaUseCase(
      cajaId: cajaId,
      conteos: conteos,
      observaciones: observaciones,
    );
    if (isClosed) return;

    if (result is Success<Caja>) {
      // Emitimos primero el estado transitorio con la caja+cierre para
      // que el listener de la page pueda imprimir el resumen. Despues
      // pasamos a SinCaja para que el dashboard general reaccione.
      emit(CajaActivaRecienCerrada(result.data));
      emit(const CajaActivaSinCaja());
    } else if (result is Error<Caja>) {
      emit(CajaActivaError(result.message));
    }
  }
}

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../../domain/entities/caja.dart';
import '../../domain/usecases/abrir_caja_usecase.dart';
import '../../domain/usecases/cerrar_caja_usecase.dart';
import '../../domain/usecases/get_caja_activa_usecase.dart';
import 'caja_activa_state.dart';

@injectable
class CajaActivaCubit extends Cubit<CajaActivaState> {
  final GetCajaActivaUseCase _getCajaActivaUseCase;
  final AbrirCajaUseCase _abrirCajaUseCase;
  final CerrarCajaUseCase _cerrarCajaUseCase;

  CajaActivaCubit(
    this._getCajaActivaUseCase,
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

  Future<void> abrirCaja({
    required String sedeId,
    required double montoApertura,
    String? observaciones,
  }) async {
    emit(const CajaActivaLoading());

    final result = await _abrirCajaUseCase(
      sedeId: sedeId,
      montoApertura: montoApertura,
      observaciones: observaciones,
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

    if (result is Success<void>) {
      emit(const CajaActivaSinCaja());
    } else if (result is Error<void>) {
      emit(CajaActivaError(result.message));
    }
  }
}

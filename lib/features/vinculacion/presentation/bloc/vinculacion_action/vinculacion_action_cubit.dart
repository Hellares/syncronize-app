import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../../../../core/utils/resource.dart';
import '../../../domain/entities/vinculacion.dart';
import '../../../domain/usecases/check_ruc_usecase.dart';
import '../../../domain/usecases/crear_vinculacion_usecase.dart';
import '../../../domain/usecases/responder_vinculacion_usecase.dart';
import '../../../domain/usecases/cancelar_vinculacion_usecase.dart';
import '../../../domain/usecases/desvincular_usecase.dart';
import 'vinculacion_action_state.dart';

@injectable
class VinculacionActionCubit extends Cubit<VinculacionActionState> {
  final CheckRucUseCase _checkRucUseCase;
  final CrearVinculacionUseCase _crearUseCase;
  final ResponderVinculacionUseCase _responderUseCase;
  final CancelarVinculacionUseCase _cancelarUseCase;
  final DesvincularUseCase _desvincularUseCase;

  VinculacionActionCubit(
    this._checkRucUseCase,
    this._crearUseCase,
    this._responderUseCase,
    this._cancelarUseCase,
    this._desvincularUseCase,
  ) : super(const VinculacionActionInitial());

  Future<void> checkRuc(String ruc) async {
    emit(const VinculacionActionLoading());

    final result = await _checkRucUseCase(ruc: ruc);

    if (isClosed) return;

    if (result is Success<EmpresaVinculable?>) {
      emit(VinculacionCheckRucResult(empresa: result.data));
    } else if (result is Error<EmpresaVinculable?>) {
      emit(VinculacionActionError(result.message));
    }
  }

  Future<void> crear({
    required String clienteEmpresaId,
    String? mensaje,
  }) async {
    emit(const VinculacionActionLoading());

    final result = await _crearUseCase(
      clienteEmpresaId: clienteEmpresaId,
      mensaje: mensaje,
    );

    if (isClosed) return;

    if (result is Success<VinculacionEmpresa>) {
      emit(VinculacionActionSuccess(
        vinculacion: result.data,
        mensaje: 'Solicitud de vinculación enviada',
      ));
    } else if (result is Error<VinculacionEmpresa>) {
      emit(VinculacionActionError(result.message));
    }
  }

  Future<void> crearConRuc({
    required String ruc,
    String? mensaje,
  }) async {
    emit(const VinculacionActionLoading());

    final result = await _crearUseCase(
      ruc: ruc,
      mensaje: mensaje,
    );

    if (isClosed) return;

    if (result is Success<VinculacionEmpresa>) {
      emit(VinculacionActionSuccess(
        vinculacion: result.data,
        mensaje: 'Solicitud de vinculación enviada',
      ));
    } else if (result is Error<VinculacionEmpresa>) {
      emit(VinculacionActionError(result.message));
    }
  }

  Future<void> aceptar(String id) async {
    emit(const VinculacionActionLoading());

    final result = await _responderUseCase(id: id, aceptar: true);

    if (isClosed) return;

    if (result is Success<VinculacionEmpresa>) {
      emit(VinculacionActionSuccess(
        vinculacion: result.data,
        mensaje: 'Vinculación aceptada',
      ));
    } else if (result is Error<VinculacionEmpresa>) {
      emit(VinculacionActionError(result.message));
    }
  }

  Future<void> rechazar(String id, String motivoRechazo) async {
    emit(const VinculacionActionLoading());

    final result = await _responderUseCase(
      id: id,
      aceptar: false,
      motivoRechazo: motivoRechazo,
    );

    if (isClosed) return;

    if (result is Success<VinculacionEmpresa>) {
      emit(VinculacionActionSuccess(
        vinculacion: result.data,
        mensaje: 'Vinculación rechazada',
      ));
    } else if (result is Error<VinculacionEmpresa>) {
      emit(VinculacionActionError(result.message));
    }
  }

  Future<void> cancelar(String id) async {
    emit(const VinculacionActionLoading());

    final result = await _cancelarUseCase(id: id);

    if (isClosed) return;

    if (result is Success<VinculacionEmpresa>) {
      emit(VinculacionActionSuccess(
        vinculacion: result.data,
        mensaje: 'Solicitud cancelada',
      ));
    } else if (result is Error<VinculacionEmpresa>) {
      emit(VinculacionActionError(result.message));
    }
  }

  Future<void> desvincular(String id) async {
    emit(const VinculacionActionLoading());

    final result = await _desvincularUseCase(id: id);

    if (isClosed) return;

    if (result is Success<VinculacionEmpresa>) {
      emit(VinculacionActionSuccess(
        vinculacion: result.data,
        mensaje: 'Empresas desvinculadas',
      ));
    } else if (result is Error<VinculacionEmpresa>) {
      emit(VinculacionActionError(result.message));
    }
  }

  void reset() {
    emit(const VinculacionActionInitial());
  }
}

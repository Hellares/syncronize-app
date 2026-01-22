import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../../../../core/utils/resource.dart';
import '../../../domain/entities/transferencia_stock.dart';
import '../../../domain/usecases/gestionar_transferencia_usecase.dart';
import 'gestionar_transferencia_state.dart';

@injectable
class GestionarTransferenciaCubit extends Cubit<GestionarTransferenciaState> {
  final AprobarTransferenciaUseCase _aprobarUseCase;
  final EnviarTransferenciaUseCase _enviarUseCase;
  final RecibirTransferenciaUseCase _recibirUseCase;
  final RechazarTransferenciaUseCase _rechazarUseCase;
  final CancelarTransferenciaUseCase _cancelarUseCase;

  GestionarTransferenciaCubit(
    this._aprobarUseCase,
    this._enviarUseCase,
    this._recibirUseCase,
    this._rechazarUseCase,
    this._cancelarUseCase,
  ) : super(const GestionarTransferenciaInitial());

  /// Aprobar transferencia
  Future<void> aprobar({
    required String transferenciaId,
    required String empresaId,
    String? observaciones,
  }) async {
    emit(const GestionarTransferenciaProcessing('aprobar'));

    final result = await _aprobarUseCase(
      transferenciaId: transferenciaId,
      empresaId: empresaId,
      observaciones: observaciones,
    );

    if (isClosed) return;

    if (result is Success<TransferenciaStock>) {
      emit(GestionarTransferenciaSuccess(
        result.data,
        'Transferencia aprobada correctamente',
      ));
    } else if (result is Error<TransferenciaStock>) {
      emit(GestionarTransferenciaError(
        result.message,
        errorCode: result.errorCode,
      ));
    }
  }

  /// Enviar transferencia (marcar en tránsito)
  Future<void> enviar({
    required String transferenciaId,
    required String empresaId,
  }) async {
    emit(const GestionarTransferenciaProcessing('enviar'));

    final result = await _enviarUseCase(
      transferenciaId: transferenciaId,
      empresaId: empresaId,
    );

    if (isClosed) return;

    if (result is Success<TransferenciaStock>) {
      emit(GestionarTransferenciaSuccess(
        result.data,
        'Transferencia enviada correctamente',
      ));
    } else if (result is Error<TransferenciaStock>) {
      emit(GestionarTransferenciaError(
        result.message,
        errorCode: result.errorCode,
      ));
    }
  }

  /// Recibir transferencia
  Future<void> recibir({
    required String transferenciaId,
    required String empresaId,
    required int cantidadRecibida,
    String? ubicacion,
    String? observaciones,
  }) async {
    emit(const GestionarTransferenciaProcessing('recibir'));

    final result = await _recibirUseCase(
      transferenciaId: transferenciaId,
      empresaId: empresaId,
      cantidadRecibida: cantidadRecibida,
      ubicacion: ubicacion,
      observaciones: observaciones,
    );

    if (isClosed) return;

    if (result is Success<TransferenciaStock>) {
      emit(GestionarTransferenciaSuccess(
        result.data,
        'Transferencia recibida correctamente',
      ));
    } else if (result is Error<TransferenciaStock>) {
      emit(GestionarTransferenciaError(
        result.message,
        errorCode: result.errorCode,
      ));
    }
  }

  /// Rechazar transferencia
  Future<void> rechazar({
    required String transferenciaId,
    required String empresaId,
    required String motivo,
  }) async {
    emit(const GestionarTransferenciaProcessing('rechazar'));

    final result = await _rechazarUseCase(
      transferenciaId: transferenciaId,
      empresaId: empresaId,
      motivo: motivo,
    );

    if (isClosed) return;

    if (result is Success<TransferenciaStock>) {
      emit(GestionarTransferenciaSuccess(
        result.data,
        'Transferencia rechazada',
      ));
    } else if (result is Error<TransferenciaStock>) {
      emit(GestionarTransferenciaError(
        result.message,
        errorCode: result.errorCode,
      ));
    }
  }

  /// Cancelar transferencia
  Future<void> cancelar({
    required String transferenciaId,
    required String empresaId,
    required String motivo,
  }) async {
    emit(const GestionarTransferenciaProcessing('cancelar'));

    final result = await _cancelarUseCase(
      transferenciaId: transferenciaId,
      empresaId: empresaId,
      motivo: motivo,
    );

    if (isClosed) return;

    if (result is Success<TransferenciaStock>) {
      emit(GestionarTransferenciaSuccess(
        result.data,
        'Transferencia cancelada',
      ));
    } else if (result is Error<TransferenciaStock>) {
      emit(GestionarTransferenciaError(
        result.message,
        errorCode: result.errorCode,
      ));
    }
  }

  /// Resetea el estado
  void reset() {
    emit(const GestionarTransferenciaInitial());
  }
}

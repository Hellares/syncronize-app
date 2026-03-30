import 'dart:io';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../../../../core/utils/resource.dart';
import '../../../domain/entities/pago_suscripcion.dart';
import '../../../domain/usecases/solicitar_pago_usecase.dart';
import '../../../domain/usecases/subir_comprobante_usecase.dart';

part 'pago_suscripcion_state.dart';

@injectable
class PagoSuscripcionCubit extends Cubit<PagoSuscripcionState> {
  final SolicitarPagoUseCase _solicitarPagoUseCase;
  final SubirComprobantePagoUseCase _subirComprobanteUseCase;

  PagoSuscripcionCubit(
    this._solicitarPagoUseCase,
    this._subirComprobanteUseCase,
  ) : super(const PagoSuscripcionInitial());

  Future<void> solicitarPago({
    required String planSuscripcionId,
    required String periodo,
    required String metodoPago,
  }) async {
    emit(const PagoSuscripcionLoading());

    final result = await _solicitarPagoUseCase(
      planSuscripcionId: planSuscripcionId,
      periodo: periodo,
      metodoPago: metodoPago,
    );
    if (isClosed) return;

    if (result is Success<PagoSuscripcion>) {
      emit(PagoSuscripcionCreated(result.data));
    } else if (result is Error<PagoSuscripcion>) {
      emit(PagoSuscripcionError(result.message));
    }
  }

  Future<void> subirComprobante({
    required String pagoId,
    required File file,
  }) async {
    emit(const PagoSuscripcionUploadingComprobante());

    final result = await _subirComprobanteUseCase(
      pagoId: pagoId,
      file: file,
    );
    if (isClosed) return;

    if (result is Success<String>) {
      emit(PagoSuscripcionComprobanteUploaded(result.data));
    } else if (result is Error<String>) {
      emit(PagoSuscripcionError(result.message));
    }
  }

  void reset() {
    emit(const PagoSuscripcionInitial());
  }
}

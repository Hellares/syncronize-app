import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../../core/utils/resource.dart';
import '../../../domain/entities/incidencia_item_request.dart';
import '../../../domain/usecases/recibir_transferencia_con_incidencias_usecase.dart';
import 'recibir_transferencia_incidencias_state.dart';

@injectable
class RecibirTransferenciaIncidenciasCubit
    extends Cubit<RecibirTransferenciaIncidenciasState> {
  final RecibirTransferenciaConIncidenciasUseCase _useCase;

  RecibirTransferenciaIncidenciasCubit(this._useCase)
      : super(const RecibirTransferenciaIncidenciasInitial());

  /// Recibe una transferencia con manejo de incidencias
  Future<void> recibir({
    required String transferenciaId,
    required String empresaId,
    required RecibirTransferenciaConIncidenciasRequest request,
  }) async {
    emit(const RecibirTransferenciaIncidenciasProcessing());

    final result = await _useCase(
      transferenciaId: transferenciaId,
      empresaId: empresaId,
      request: request,
    );

    if (isClosed) return;

    if (result is Success) {
      emit(RecibirTransferenciaIncidenciasSuccess(
        transferencia: result.data as Map<String, dynamic>,
        message: request.totalIncidencias > 0
            ? 'Transferencia recibida con ${request.totalIncidencias} incidencia(s) reportada(s)'
            : 'Transferencia recibida exitosamente',
      ));
    } else if (result is Error) {
      emit(RecibirTransferenciaIncidenciasError(
        result.message,
        errorCode: result.errorCode,
      ));
    }
  }

  /// Reinicia el estado del cubit
  void reset() {
    if (isClosed) return;
    emit(const RecibirTransferenciaIncidenciasInitial());
  }
}

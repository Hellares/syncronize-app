import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../../core/utils/resource.dart';
import '../../../domain/entities/transferencia_incidencia.dart';
import '../../../domain/entities/incidencia_item_request.dart';
import '../../../domain/usecases/resolver_incidencia_usecase.dart';
import 'resolver_incidencia_state.dart';

@injectable
class ResolverIncidenciaCubit extends Cubit<ResolverIncidenciaState> {
  final ResolverIncidenciaUseCase _useCase;

  ResolverIncidenciaCubit(this._useCase)
      : super(const ResolverIncidenciaInitial());

  /// Resuelve una incidencia con la acción especificada
  Future<void> resolver({
    required String incidenciaId,
    required String empresaId,
    required ResolverIncidenciaRequest request,
  }) async {
    emit(const ResolverIncidenciaProcessing());

    final result = await _useCase(
      incidenciaId: incidenciaId,
      empresaId: empresaId,
      request: request,
    );

    if (isClosed) return;

    if (result is Success<TransferenciaIncidencia>) {
      final mensaje = _generarMensajeExito(request.accion);
      emit(ResolverIncidenciaSuccess(
        incidenciaResuelta: result.data,
        message: mensaje,
      ));
    } else if (result is Error<TransferenciaIncidencia>) {
      emit(ResolverIncidenciaError(
        result.message,
        errorCode: result.errorCode,
      ));
    }
  }

  /// Genera un mensaje descriptivo según la acción ejecutada
  String _generarMensajeExito(AccionResolucionIncidencia accion) {
    switch (accion) {
      case AccionResolucionIncidencia.devolverOrigen:
        return 'Incidencia resuelta: Transferencia de devolución creada';
      case AccionResolucionIncidencia.darDeBaja:
        return 'Incidencia resuelta: Productos dados de baja del inventario';
      case AccionResolucionIncidencia.reparar:
        return 'Incidencia resuelta: Productos marcados para reparación';
      case AccionResolucionIncidencia.aceptarConDescuento:
        return 'Incidencia resuelta: Productos aceptados con descuento aplicado';
      case AccionResolucionIncidencia.reclamarProveedor:
        return 'Incidencia resuelta: Reclamo registrado al proveedor';
    }
  }

  /// Reinicia el estado del cubit
  void reset() {
    if (isClosed) return;
    emit(const ResolverIncidenciaInitial());
  }
}

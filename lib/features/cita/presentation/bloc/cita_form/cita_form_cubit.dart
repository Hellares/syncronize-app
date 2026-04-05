import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../../../../core/utils/resource.dart';
import '../../../domain/entities/cita.dart';
import '../../../domain/repositories/cita_repository.dart';
import 'cita_form_state.dart';

@injectable
class CitaFormCubit extends Cubit<CitaFormState> {
  final CitaRepository _repository;

  CitaFormCubit(this._repository) : super(const CitaFormInitial());

  Future<void> crearCita({
    required String sedeId,
    required String servicioId,
    required String tecnicoId,
    required String fecha,
    required String horaInicio,
    required String horaFin,
    String? clienteId,
    String? clienteEmpresaId,
    String? notas,
  }) async {
    emit(const CitaFormLoading());

    final data = <String, dynamic>{
      'sedeId': sedeId,
      'servicioId': servicioId,
      'tecnicoId': tecnicoId,
      'fecha': fecha,
      'horaInicio': horaInicio,
      'horaFin': horaFin,
    };
    if (clienteId != null) data['clienteId'] = clienteId;
    if (clienteEmpresaId != null) data['clienteEmpresaId'] = clienteEmpresaId;
    if (notas != null && notas.isNotEmpty) data['notas'] = notas;

    final result = await _repository.create(data);
    if (isClosed) return;

    if (result is Success<Cita>) {
      emit(CitaFormSuccess(cita: result.data));
    } else if (result is Error<Cita>) {
      emit(CitaFormError(result.message));
    }
  }

  Future<void> actualizarCita({
    required String id,
    String? servicioId,
    String? tecnicoId,
    String? fecha,
    String? horaInicio,
    String? horaFin,
    String? clienteId,
    String? clienteEmpresaId,
    String? notas,
  }) async {
    emit(const CitaFormLoading());

    final data = <String, dynamic>{};
    if (servicioId != null) data['servicioId'] = servicioId;
    if (tecnicoId != null) data['tecnicoId'] = tecnicoId;
    if (fecha != null) data['fecha'] = fecha;
    if (horaInicio != null) data['horaInicio'] = horaInicio;
    if (horaFin != null) data['horaFin'] = horaFin;
    if (clienteId != null) data['clienteId'] = clienteId;
    if (clienteEmpresaId != null) data['clienteEmpresaId'] = clienteEmpresaId;
    if (notas != null) data['notas'] = notas;

    final result = await _repository.update(id, data);
    if (isClosed) return;

    if (result is Success<Cita>) {
      emit(CitaFormSuccess(cita: result.data, mensaje: 'Cita actualizada'));
    } else if (result is Error<Cita>) {
      emit(CitaFormError(result.message));
    }
  }

  Future<void> cambiarEstado({
    required String id,
    required String nuevoEstado,
    String? notas,
    String? motivoCancelacion,
    bool generarOrden = false,
    Map<String, dynamic>? siguienteCita,
  }) async {
    emit(const CitaFormLoading());

    final data = <String, dynamic>{
      'nuevoEstado': nuevoEstado,
    };
    if (notas != null) data['notas'] = notas;
    if (motivoCancelacion != null) data['motivoCancelacion'] = motivoCancelacion;
    if (generarOrden) data['generarOrden'] = true;
    if (siguienteCita != null) data['siguienteCita'] = siguienteCita;

    final result = await _repository.transitionEstado(id, data);
    if (isClosed) return;

    if (result is Success<Map<String, dynamic>>) {
      emit(CitaTransitionSuccess(
        resultado: result.data,
        mensaje: 'Estado actualizado a $nuevoEstado',
      ));
    } else if (result is Error<Map<String, dynamic>>) {
      emit(CitaFormError(result.message));
    }
  }

  void reset() {
    emit(const CitaFormInitial());
  }
}

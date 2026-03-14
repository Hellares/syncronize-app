import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../../../../core/utils/resource.dart';
import '../../../domain/entities/slot_disponibilidad.dart';
import '../../../domain/repositories/cita_repository.dart';
import 'disponibilidad_state.dart';

@injectable
class DisponibilidadCubit extends Cubit<DisponibilidadState> {
  final CitaRepository _repository;

  DisponibilidadCubit(this._repository) : super(const DisponibilidadInitial());

  Future<void> cargarSlots({
    required String fecha,
    required String sedeId,
    required String servicioId,
    String? tecnicoId,
  }) async {
    emit(const DisponibilidadLoading());

    final result = await _repository.getDisponibilidad(
      fecha: fecha,
      sedeId: sedeId,
      servicioId: servicioId,
      tecnicoId: tecnicoId,
    );
    if (isClosed) return;

    if (result is Success<DisponibilidadResponse>) {
      emit(DisponibilidadLoaded(result.data));
    } else if (result is Error<DisponibilidadResponse>) {
      emit(DisponibilidadError(result.message));
    }
  }

  Future<void> cargarTecnicosDisponibles({
    required String fecha,
    required String horaInicio,
    required String sedeId,
    required String servicioId,
  }) async {
    emit(const DisponibilidadLoading());

    final result = await _repository.getTecnicosDisponibles(
      fecha: fecha,
      horaInicio: horaInicio,
      sedeId: sedeId,
      servicioId: servicioId,
    );
    if (isClosed) return;

    if (result is Success<List<TecnicoDisponible>>) {
      emit(TecnicosDisponiblesLoaded(result.data));
    } else if (result is Error<List<TecnicoDisponible>>) {
      emit(DisponibilidadError(result.message));
    }
  }

  void reset() {
    emit(const DisponibilidadInitial());
  }
}

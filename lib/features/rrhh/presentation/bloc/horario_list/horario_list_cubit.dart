import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../../core/utils/resource.dart';
import '../../../domain/entities/horario_plantilla.dart';
import '../../../domain/repositories/horario_repository.dart';
import 'horario_list_state.dart';

@injectable
class HorarioListCubit extends Cubit<HorarioListState> {
  final HorarioRepository _repository;

  HorarioListCubit(this._repository) : super(const HorarioListInitial());

  Future<void> loadHorarios() async {
    emit(const HorarioListLoading());

    final result = await _repository.getAll();
    if (isClosed) return;

    if (result is Success<List<HorarioPlantilla>>) {
      emit(HorarioListLoaded(result.data));
    } else if (result is Error) {
      emit(HorarioListError((result as Error).message));
    }
  }

  Future<void> crearHorario(Map<String, dynamic> data) async {
    emit(const HorarioListLoading());

    final result = await _repository.create(data);
    if (isClosed) return;

    if (result is Success<HorarioPlantilla>) {
      emit(const HorarioListActionSuccess('Horario creado exitosamente'));
      await loadHorarios();
    } else if (result is Error) {
      emit(HorarioListError((result as Error).message));
    }
  }

  Future<void> actualizarHorario(String id, Map<String, dynamic> data) async {
    emit(const HorarioListLoading());

    final result = await _repository.update(id, data);
    if (isClosed) return;

    if (result is Success<HorarioPlantilla>) {
      emit(const HorarioListActionSuccess('Horario actualizado exitosamente'));
      await loadHorarios();
    } else if (result is Error) {
      emit(HorarioListError((result as Error).message));
    }
  }

  Future<void> eliminarHorario(String id) async {
    emit(const HorarioListLoading());

    final result = await _repository.delete(id);
    if (isClosed) return;

    if (result is Success<void>) {
      emit(const HorarioListActionSuccess('Horario eliminado exitosamente'));
      await loadHorarios();
    } else if (result is Error) {
      emit(HorarioListError((result).message));
    }
  }
}

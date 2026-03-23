import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../../core/utils/resource.dart';
import '../../../domain/entities/turno.dart';
import '../../../domain/repositories/turno_repository.dart';
import 'turno_list_state.dart';

@injectable
class TurnoListCubit extends Cubit<TurnoListState> {
  final TurnoRepository _repository;

  TurnoListCubit(this._repository) : super(const TurnoListInitial());

  Future<void> loadTurnos() async {
    emit(const TurnoListLoading());

    final result = await _repository.getAll();
    if (isClosed) return;

    if (result is Success<List<Turno>>) {
      emit(TurnoListLoaded(result.data));
    } else if (result is Error) {
      emit(TurnoListError((result as Error).message));
    }
  }

  Future<void> crearTurno(Map<String, dynamic> data) async {
    emit(const TurnoListLoading());

    final result = await _repository.create(data);
    if (isClosed) return;

    if (result is Success<Turno>) {
      emit(const TurnoListActionSuccess('Turno creado exitosamente'));
      await loadTurnos();
    } else if (result is Error) {
      emit(TurnoListError((result as Error).message));
    }
  }

  Future<void> actualizarTurno(String id, Map<String, dynamic> data) async {
    emit(const TurnoListLoading());

    final result = await _repository.update(id, data);
    if (isClosed) return;

    if (result is Success<Turno>) {
      emit(const TurnoListActionSuccess('Turno actualizado exitosamente'));
      await loadTurnos();
    } else if (result is Error) {
      emit(TurnoListError((result as Error).message));
    }
  }

  Future<void> eliminarTurno(String id) async {
    emit(const TurnoListLoading());

    final result = await _repository.delete(id);
    if (isClosed) return;

    if (result is Success<void>) {
      emit(const TurnoListActionSuccess('Turno eliminado exitosamente'));
      await loadTurnos();
    } else if (result is Error) {
      emit(TurnoListError((result).message));
    }
  }
}

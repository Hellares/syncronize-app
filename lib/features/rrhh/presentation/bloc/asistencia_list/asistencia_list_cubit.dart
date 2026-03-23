import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../../core/utils/resource.dart';
import '../../../domain/entities/asistencia.dart';
import '../../../domain/repositories/asistencia_repository.dart';
import 'asistencia_list_state.dart';

@injectable
class AsistenciaListCubit extends Cubit<AsistenciaListState> {
  final AsistenciaRepository _repository;

  Map<String, dynamic> _lastFilters = {};

  AsistenciaListCubit(this._repository)
      : super(const AsistenciaListInitial());

  Future<void> loadAsistencias({Map<String, dynamic>? filters}) async {
    if (filters != null) {
      _lastFilters = filters;
    }

    emit(const AsistenciaListLoading());

    final result = await _repository.getAll(queryParams: _lastFilters);
    if (isClosed) return;

    if (result is Success<List<Asistencia>>) {
      emit(AsistenciaListLoaded(result.data));
    } else if (result is Error) {
      emit(AsistenciaListError((result as Error).message));
    }
  }

  Future<void> registrarEntrada(Map<String, dynamic> data) async {
    emit(const AsistenciaListLoading());

    final result = await _repository.registrarEntrada(data);
    if (isClosed) return;

    if (result is Success<Asistencia>) {
      emit(const AsistenciaListActionSuccess('Entrada registrada exitosamente'));
      await loadAsistencias();
    } else if (result is Error) {
      emit(AsistenciaListError((result as Error).message));
    }
  }

  Future<void> registrarSalida(String id, Map<String, dynamic> data) async {
    emit(const AsistenciaListLoading());

    final result = await _repository.registrarSalida(id, data);
    if (isClosed) return;

    if (result is Success<Asistencia>) {
      emit(const AsistenciaListActionSuccess('Salida registrada exitosamente'));
      await loadAsistencias();
    } else if (result is Error) {
      emit(AsistenciaListError((result as Error).message));
    }
  }

  Future<void> registrarBulk(Map<String, dynamic> data) async {
    emit(const AsistenciaListLoading());

    final result = await _repository.registrarBulk(data);
    if (isClosed) return;

    if (result is Success<List<Asistencia>>) {
      emit(const AsistenciaListActionSuccess(
          'Asistencia masiva registrada exitosamente'));
      await loadAsistencias();
    } else if (result is Error) {
      emit(AsistenciaListError((result as Error).message));
    }
  }

  Future<void> refresh() async {
    await loadAsistencias();
  }
}

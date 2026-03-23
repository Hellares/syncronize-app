import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../../core/utils/resource.dart';
import '../../../domain/entities/asistencia.dart';
import '../../../domain/repositories/asistencia_repository.dart';
import 'asistencia_state.dart';

@injectable
class AsistenciaCubit extends Cubit<AsistenciaState> {
  final AsistenciaRepository _repository;

  AsistenciaCubit(this._repository) : super(const AsistenciaInitial());

  Future<void> loadAsistencias({Map<String, dynamic>? queryParams}) async {
    emit(const AsistenciaLoading());

    final result = await _repository.getAll(queryParams: queryParams);
    if (isClosed) return;

    if (result is Success<List<Asistencia>>) {
      emit(AsistenciaListLoaded(result.data));
    } else if (result is Error) {
      emit(AsistenciaError((result as Error).message));
    }
  }

  Future<void> registrarEntrada(Map<String, dynamic> data) async {
    emit(const AsistenciaLoading());

    final result = await _repository.registrarEntrada(data);
    if (isClosed) return;

    if (result is Success<Asistencia>) {
      emit(const AsistenciaActionSuccess('Entrada registrada exitosamente'));
    } else if (result is Error) {
      emit(AsistenciaError((result as Error).message));
    }
  }

  Future<void> registrarSalida(String id, Map<String, dynamic> data) async {
    emit(const AsistenciaLoading());

    final result = await _repository.registrarSalida(id, data);
    if (isClosed) return;

    if (result is Success<Asistencia>) {
      emit(const AsistenciaActionSuccess('Salida registrada exitosamente'));
    } else if (result is Error) {
      emit(AsistenciaError((result as Error).message));
    }
  }

  Future<void> registrarBulk(Map<String, dynamic> data) async {
    emit(const AsistenciaLoading());

    final result = await _repository.registrarBulk(data);
    if (isClosed) return;

    if (result is Success<List<Asistencia>>) {
      emit(const AsistenciaActionSuccess('Asistencia masiva registrada exitosamente'));
    } else if (result is Error) {
      emit(AsistenciaError((result as Error).message));
    }
  }

  Future<void> loadResumenMensual(String empleadoId, int mes, int anio) async {
    emit(const AsistenciaLoading());

    final result = await _repository.getResumenMensual(empleadoId, mes, anio);
    if (isClosed) return;

    if (result is Success<AsistenciaResumen>) {
      emit(AsistenciaResumenLoaded(result.data));
    } else if (result is Error) {
      emit(AsistenciaError((result as Error).message));
    }
  }
}

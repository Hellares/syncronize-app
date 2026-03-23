import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../../core/utils/resource.dart';
import '../../../domain/entities/incidencia.dart';
import '../../../domain/repositories/incidencia_repository.dart';
import 'incidencia_state.dart';

@injectable
class IncidenciaCubit extends Cubit<IncidenciaState> {
  final IncidenciaRepository _repository;

  Map<String, dynamic> _lastParams = {};

  IncidenciaCubit(this._repository) : super(const IncidenciaInitial());

  Future<void> loadIncidencias({Map<String, dynamic>? queryParams}) async {
    if (queryParams != null) _lastParams = queryParams;
    emit(const IncidenciaLoading());

    final result = await _repository.getAll(queryParams: queryParams);
    if (isClosed) return;

    if (result is Success<List<Incidencia>>) {
      emit(IncidenciaListLoaded(result.data));
    } else if (result is Error) {
      emit(IncidenciaError((result as Error).message));
    }
  }

  Future<void> crearIncidencia(Map<String, dynamic> data) async {
    emit(const IncidenciaLoading());

    final result = await _repository.create(data);
    if (isClosed) return;

    if (result is Success<Incidencia>) {
      emit(const IncidenciaActionSuccess('Incidencia creada exitosamente'));
    } else if (result is Error) {
      emit(IncidenciaError((result as Error).message));
    }
  }

  Future<void> aprobar(String id) async {
    emit(const IncidenciaLoading());

    final result = await _repository.aprobar(id);
    if (isClosed) return;

    if (result is Success<Incidencia>) {
      emit(const IncidenciaActionSuccess('Incidencia aprobada'));
      await loadIncidencias(queryParams: _lastParams);
    } else if (result is Error) {
      emit(IncidenciaError((result as Error).message));
    }
  }

  Future<void> rechazar(String id, String motivoRechazo) async {
    emit(const IncidenciaLoading());

    final result = await _repository.rechazar(id, motivoRechazo);
    if (isClosed) return;

    if (result is Success<Incidencia>) {
      emit(const IncidenciaActionSuccess('Incidencia rechazada'));
      await loadIncidencias(queryParams: _lastParams);
    } else if (result is Error) {
      emit(IncidenciaError((result as Error).message));
    }
  }

  Future<void> refresh() async {
    await loadIncidencias(queryParams: _lastParams);
  }
}

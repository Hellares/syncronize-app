import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../../core/utils/resource.dart';
import '../../../domain/entities/incidencia.dart';
import '../../../domain/repositories/incidencia_repository.dart';
import 'incidencia_list_state.dart';

@injectable
class IncidenciaListCubit extends Cubit<IncidenciaListState> {
  final IncidenciaRepository _repository;

  Map<String, dynamic> _lastFilters = {};

  IncidenciaListCubit(this._repository)
      : super(const IncidenciaListInitial());

  Future<void> loadIncidencias({Map<String, dynamic>? filters}) async {
    if (filters != null) {
      _lastFilters = filters;
    }

    emit(const IncidenciaListLoading());

    final result = await _repository.getAll(queryParams: _lastFilters);
    if (isClosed) return;

    if (result is Success<List<Incidencia>>) {
      emit(IncidenciaListLoaded(result.data));
    } else if (result is Error) {
      emit(IncidenciaListError((result as Error).message));
    }
  }

  Future<void> crearIncidencia(Map<String, dynamic> data) async {
    emit(const IncidenciaListLoading());

    final result = await _repository.create(data);
    if (isClosed) return;

    if (result is Success<Incidencia>) {
      emit(const IncidenciaListActionSuccess(
          'Incidencia creada exitosamente'));
      await loadIncidencias();
    } else if (result is Error) {
      emit(IncidenciaListError((result as Error).message));
    }
  }

  Future<void> aprobar(String id) async {
    emit(const IncidenciaListLoading());

    final result = await _repository.aprobar(id);
    if (isClosed) return;

    if (result is Success<Incidencia>) {
      emit(const IncidenciaListActionSuccess(
          'Incidencia aprobada exitosamente'));
      await loadIncidencias();
    } else if (result is Error) {
      emit(IncidenciaListError((result as Error).message));
    }
  }

  Future<void> rechazar(String id, String motivo) async {
    emit(const IncidenciaListLoading());

    final result = await _repository.rechazar(id, motivo);
    if (isClosed) return;

    if (result is Success<Incidencia>) {
      emit(const IncidenciaListActionSuccess(
          'Incidencia rechazada exitosamente'));
      await loadIncidencias();
    } else if (result is Error) {
      emit(IncidenciaListError((result as Error).message));
    }
  }

  Future<void> cancelar(String id) async {
    emit(const IncidenciaListLoading());

    final result = await _repository.cancelar(id);
    if (isClosed) return;

    if (result is Success<Incidencia>) {
      emit(const IncidenciaListActionSuccess(
          'Incidencia cancelada exitosamente'));
      await loadIncidencias();
    } else if (result is Error) {
      emit(IncidenciaListError((result as Error).message));
    }
  }

  Future<void> refresh() async {
    await loadIncidencias();
  }
}

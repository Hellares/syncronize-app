import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../../../../core/utils/resource.dart';
import '../../../domain/entities/direccion_persona.dart';
import '../../../domain/repositories/direccion_repository.dart';
import 'direccion_list_state.dart';

@injectable
class DireccionListCubit extends Cubit<DireccionListState> {
  final DireccionRepository _repository;

  DireccionListCubit(this._repository) : super(const DireccionListInitial());

  Future<void> loadDirecciones() async {
    emit(const DireccionListLoading());

    final result = await _repository.listar();
    if (isClosed) return;

    if (result is Success<List<DireccionPersona>>) {
      emit(DireccionListLoaded(direcciones: result.data));
    } else if (result is Error<List<DireccionPersona>>) {
      emit(DireccionListError(result.message));
    }
  }

  Future<bool> crear(Map<String, dynamic> data) async {
    final result = await _repository.crear(data);
    if (result is Success) {
      await loadDirecciones();
      return true;
    }
    return false;
  }

  Future<bool> actualizar(String id, Map<String, dynamic> data) async {
    final result = await _repository.actualizar(id, data);
    if (result is Success) {
      await loadDirecciones();
      return true;
    }
    return false;
  }

  Future<bool> eliminar(String id) async {
    final result = await _repository.eliminar(id);
    if (result is Success) {
      await loadDirecciones();
      return true;
    }
    return false;
  }

  Future<bool> marcarPredeterminada(String id) async {
    final result = await _repository.marcarPredeterminada(id);
    if (result is Success) {
      await loadDirecciones();
      return true;
    }
    return false;
  }
}

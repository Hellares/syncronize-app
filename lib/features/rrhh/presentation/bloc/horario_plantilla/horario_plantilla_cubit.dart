import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../../core/utils/resource.dart';
import '../../../domain/entities/horario_plantilla.dart';
import '../../../domain/repositories/horario_repository.dart';
import 'horario_plantilla_state.dart';

@injectable
class HorarioPlantillaCubit extends Cubit<HorarioPlantillaState> {
  final HorarioRepository _repository;

  HorarioPlantillaCubit(this._repository)
      : super(const HorarioPlantillaInitial());

  Future<void> loadPlantillas() async {
    emit(const HorarioPlantillaLoading());

    final result = await _repository.getAll();
    if (isClosed) return;

    if (result is Success<List<HorarioPlantilla>>) {
      emit(HorarioPlantillaLoaded(result.data));
    } else if (result is Error) {
      emit(HorarioPlantillaError((result as Error).message));
    }
  }

  Future<void> crearPlantilla(Map<String, dynamic> data) async {
    emit(const HorarioPlantillaLoading());

    final result = await _repository.create(data);
    if (isClosed) return;

    if (result is Success<HorarioPlantilla>) {
      emit(const HorarioPlantillaActionSuccess(
          'Plantilla creada exitosamente'));
      await loadPlantillas();
    } else if (result is Error) {
      emit(HorarioPlantillaError((result as Error).message));
    }
  }

  Future<void> actualizarPlantilla(
    String id,
    Map<String, dynamic> data,
  ) async {
    emit(const HorarioPlantillaLoading());

    final result = await _repository.update(id, data);
    if (isClosed) return;

    if (result is Success<HorarioPlantilla>) {
      emit(const HorarioPlantillaActionSuccess(
          'Plantilla actualizada exitosamente'));
      await loadPlantillas();
    } else if (result is Error) {
      emit(HorarioPlantillaError((result as Error).message));
    }
  }

  Future<void> eliminarPlantilla(String id) async {
    emit(const HorarioPlantillaLoading());

    final result = await _repository.delete(id);
    if (isClosed) return;

    if (result is Success<void>) {
      emit(const HorarioPlantillaActionSuccess(
          'Plantilla eliminada exitosamente'));
      await loadPlantillas();
    } else if (result is Error) {
      emit(HorarioPlantillaError((result).message));
    }
  }
}

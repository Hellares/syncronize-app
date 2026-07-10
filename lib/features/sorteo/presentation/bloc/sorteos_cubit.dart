import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/utils/resource.dart';
import '../../domain/entities/sorteo.dart';
import '../../domain/repositories/sorteo_repository.dart';

part 'sorteos_state.dart';

/// Listado + creación de sorteos (lado empresa).
@injectable
class SorteosCubit extends Cubit<SorteosState> {
  final SorteoRepository _repository;

  SorteosCubit(this._repository) : super(const SorteosInitial());

  EstadoSorteo? _filtro;

  Future<void> loadSorteos({EstadoSorteo? estado}) async {
    _filtro = estado;
    emit(const SorteosLoading());
    final result = await _repository.getSorteos(estado: estado);
    if (isClosed) return;
    if (result is Success<List<Sorteo>>) {
      emit(SorteosLoaded(sorteos: result.data, filtro: estado));
    } else if (result is Error<List<Sorteo>>) {
      emit(SorteosError(result.message));
    }
  }

  Future<void> reload() => loadSorteos(estado: _filtro);

  /// Crea el sorteo y devuelve la entidad (null si falló — el error
  /// queda en [SorteosError] transitorio antes de recargar).
  Future<Sorteo?> crearSorteo({
    required String titulo,
    String? descripcion,
    CanalSorteo? canal,
    String? sedeId,
    double? precioParticipacion,
  }) async {
    final result = await _repository.crearSorteo(
      titulo: titulo,
      descripcion: descripcion,
      canal: canal,
      sedeId: sedeId,
      precioParticipacion: precioParticipacion,
    );
    if (isClosed) return null;
    if (result is Success<Sorteo>) {
      await reload();
      return result.data;
    }
    if (result is Error<Sorteo>) {
      emit(SorteosError(result.message));
      await reload();
    }
    return null;
  }
}

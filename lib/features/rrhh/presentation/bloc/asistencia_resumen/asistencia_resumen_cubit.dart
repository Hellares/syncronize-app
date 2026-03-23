import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../../core/utils/resource.dart';
import '../../../domain/entities/asistencia.dart';
import '../../../domain/repositories/asistencia_repository.dart';
import 'asistencia_resumen_state.dart';

@injectable
class AsistenciaResumenCubit extends Cubit<AsistenciaResumenState> {
  final AsistenciaRepository _repository;

  AsistenciaResumenCubit(this._repository)
      : super(const AsistenciaResumenInitial());

  Future<void> loadResumen(String empleadoId, int mes, int anio) async {
    emit(const AsistenciaResumenLoading());

    final result = await _repository.getResumenMensual(empleadoId, mes, anio);
    if (isClosed) return;

    if (result is Success<AsistenciaResumen>) {
      emit(AsistenciaResumenLoaded(result.data));
    } else if (result is Error) {
      emit(AsistenciaResumenError((result as Error).message));
    }
  }
}

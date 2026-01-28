import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:equatable/equatable.dart';
import '../../../../../core/utils/resource.dart';
import '../../../domain/entities/reporte_incidencia.dart';
import '../../../domain/usecases/crear_reporte_usecase.dart';

part 'crear_reporte_incidencia_state.dart';

@injectable
class CrearReporteIncidenciaCubit extends Cubit<CrearReporteIncidenciaState> {
  final CrearReporteUsecase _crearReporteUsecase;

  CrearReporteIncidenciaCubit(
    this._crearReporteUsecase,
  ) : super(const CrearReporteIncidenciaInitial());

  Future<void> crearReporte({
    required String sedeId,
    required String titulo,
    String? descripcionGeneral,
    required TipoReporteIncidencia tipoReporte,
    required DateTime fechaIncidente,
    String? supervisorId,
    String? observacionesFinales,
  }) async {
    emit(const CrearReporteIncidenciaLoading());

    final result = await _crearReporteUsecase(
      sedeId: sedeId,
      titulo: titulo,
      descripcionGeneral: descripcionGeneral,
      tipoReporte: tipoReporte,
      fechaIncidente: fechaIncidente,
      supervisorId: supervisorId,
      observacionesFinales: observacionesFinales,
    );

    if (isClosed) return;

    if (result is Success<ReporteIncidencia>) {
      emit(CrearReporteIncidenciaSuccess(result.data));
    } else if (result is Error<ReporteIncidencia>) {
      emit(CrearReporteIncidenciaError(result.message));
    }
  }
}

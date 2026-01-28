import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:equatable/equatable.dart';
import '../../../../../core/utils/resource.dart';
import '../../../domain/entities/reporte_incidencia.dart';
import '../../../domain/usecases/obtener_reporte_usecase.dart';

part 'reporte_incidencia_detail_state.dart';

@injectable
class ReporteIncidenciaDetailCubit
    extends Cubit<ReporteIncidenciaDetailState> {
  final ObtenerReporteUsecase _obtenerReporteUsecase;

  ReporteIncidenciaDetailCubit(
    this._obtenerReporteUsecase,
  ) : super( ReporteIncidenciaDetailInitial());

  Future<void> cargarReporte(String reporteId) async {
    emit( ReporteIncidenciaDetailLoading());

    final result = await _obtenerReporteUsecase(reporteId);

    if (isClosed) return;

    if (result is Success<ReporteIncidencia>) {
      emit(ReporteIncidenciaDetailLoaded(result.data));
    } else if (result is Error<ReporteIncidencia>) {
      emit(ReporteIncidenciaDetailError(result.message));
    }
  }

  void actualizarReporte(ReporteIncidencia reporte) {
    emit(ReporteIncidenciaDetailLoaded(reporte));
  }
}

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:equatable/equatable.dart';
import '../../../../../core/utils/resource.dart';
import '../../../domain/entities/reporte_incidencia.dart';
import '../../../domain/usecases/listar_reportes_usecase.dart';

part 'reportes_incidencia_list_state.dart';

@injectable
class ReportesIncidenciaListCubit extends Cubit<ReportesIncidenciaListState> {
  final ListarReportesUsecase _listarReportesUsecase;

  ReportesIncidenciaListCubit(
    this._listarReportesUsecase,
  ) : super( ReportesIncidenciaListInitial());

  Future<void> cargarReportes({
    String? sedeId,
    EstadoReporteIncidencia? estado,
    TipoReporteIncidencia? tipoReporte,
    DateTime? fechaDesde,
    DateTime? fechaHasta,
  }) async {
    emit( ReportesIncidenciaListLoading());

    final result = await _listarReportesUsecase(
      sedeId: sedeId,
      estado: estado,
      tipoReporte: tipoReporte,
      fechaDesde: fechaDesde,
      fechaHasta: fechaHasta,
    );

    if (isClosed) return;

    if (result is Success<List<ReporteIncidencia>>) {
      emit(ReportesIncidenciaListLoaded(result.data));
    } else if (result is Error<List<ReporteIncidencia>>) {
      emit(ReportesIncidenciaListError(result.message));
    }
  }

  void filtrarPorEstado(EstadoReporteIncidencia? estado) {
    cargarReportes(estado: estado);
  }

  void filtrarPorSede(String? sedeId) {
    cargarReportes(sedeId: sedeId);
  }
}

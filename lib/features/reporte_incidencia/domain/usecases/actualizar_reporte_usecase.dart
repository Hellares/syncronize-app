import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/reporte_incidencia.dart';
import '../repositories/reporte_incidencia_repository.dart';

@injectable
class ActualizarReporteUsecase {
  final ReporteIncidenciaRepository _repository;

  ActualizarReporteUsecase(this._repository);

  Future<Resource<ReporteIncidencia>> call({
    required String reporteId,
    String? titulo,
    String? descripcionGeneral,
    TipoReporteIncidencia? tipoReporte,
    DateTime? fechaIncidente,
    String? supervisorId,
    String? observacionesFinales,
  }) async {
    return await _repository.actualizarReporte(
      reporteId: reporteId,
      titulo: titulo,
      descripcionGeneral: descripcionGeneral,
      tipoReporte: tipoReporte,
      fechaIncidente: fechaIncidente,
      supervisorId: supervisorId,
      observacionesFinales: observacionesFinales,
    );
  }
}

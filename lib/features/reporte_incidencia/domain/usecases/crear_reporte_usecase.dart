import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/reporte_incidencia.dart';
import '../repositories/reporte_incidencia_repository.dart';

@injectable
class CrearReporteUsecase {
  final ReporteIncidenciaRepository _repository;

  CrearReporteUsecase(this._repository);

  Future<Resource<ReporteIncidencia>> call({
    required String sedeId,
    required String titulo,
    String? descripcionGeneral,
    required TipoReporteIncidencia tipoReporte,
    required DateTime fechaIncidente,
    String? supervisorId,
    String? observacionesFinales,
  }) async {
    return await _repository.crearReporte(
      sedeId: sedeId,
      titulo: titulo,
      descripcionGeneral: descripcionGeneral,
      tipoReporte: tipoReporte,
      fechaIncidente: fechaIncidente,
      supervisorId: supervisorId,
      observacionesFinales: observacionesFinales,
    );
  }
}

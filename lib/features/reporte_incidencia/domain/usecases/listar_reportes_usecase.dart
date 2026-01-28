import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/reporte_incidencia.dart';
import '../repositories/reporte_incidencia_repository.dart';

@injectable
class ListarReportesUsecase {
  final ReporteIncidenciaRepository _repository;

  ListarReportesUsecase(this._repository);

  Future<Resource<List<ReporteIncidencia>>> call({
    String? sedeId,
    EstadoReporteIncidencia? estado,
    TipoReporteIncidencia? tipoReporte,
    DateTime? fechaDesde,
    DateTime? fechaHasta,
  }) async {
    return await _repository.listarReportes(
      sedeId: sedeId,
      estado: estado,
      tipoReporte: tipoReporte,
      fechaDesde: fechaDesde,
      fechaHasta: fechaHasta,
    );
  }
}

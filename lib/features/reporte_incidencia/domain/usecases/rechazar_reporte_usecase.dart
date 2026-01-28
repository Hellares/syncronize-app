import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/reporte_incidencia.dart';
import '../repositories/reporte_incidencia_repository.dart';

@injectable
class RechazarReporteUsecase {
  final ReporteIncidenciaRepository _repository;

  RechazarReporteUsecase(this._repository);

  Future<Resource<ReporteIncidencia>> call(
    String reporteId,
    String? motivo,
  ) async {
    return await _repository.rechazarReporte(reporteId, motivo);
  }
}

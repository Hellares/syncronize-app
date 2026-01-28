import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/reporte_incidencia.dart';
import '../repositories/reporte_incidencia_repository.dart';

@injectable
class ObtenerReporteUsecase {
  final ReporteIncidenciaRepository _repository;

  ObtenerReporteUsecase(this._repository);

  Future<Resource<ReporteIncidencia>> call(String reporteId) async {
    return await _repository.obtenerReporte(reporteId);
  }
}

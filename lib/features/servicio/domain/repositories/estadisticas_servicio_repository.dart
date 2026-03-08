import '../../../../core/utils/resource.dart';
import '../entities/estadisticas_servicio.dart';

abstract class EstadisticasServicioRepository {
  Future<Resource<EstadisticasServicio>> getEstadisticas({
    required String empresaId,
    String? fechaDesde,
    String? fechaHasta,
  });
}

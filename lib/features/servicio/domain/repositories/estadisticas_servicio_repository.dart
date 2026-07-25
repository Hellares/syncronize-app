import '../../../../core/utils/resource.dart';
import '../entities/estadisticas_servicio.dart';

abstract class EstadisticasServicioRepository {
  Future<Resource<EstadisticasServicio>> getEstadisticas({
    required String empresaId,
    String? fechaDesde,
    String? fechaHasta,
  });

  /// Dashboard consolidado (una respuesta) — shape crudo del backend.
  Future<Resource<Map<String, dynamic>>> getDashboard({
    String? fechaDesde,
    String? fechaHasta,
  });
}

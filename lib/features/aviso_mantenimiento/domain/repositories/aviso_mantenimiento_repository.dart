import '../../../../core/utils/resource.dart';
import '../entities/aviso_mantenimiento.dart';

abstract class AvisoMantenimientoRepository {
  Future<Resource<List<AvisoMantenimiento>>> getAvisos({
    String? estado,
    String? clienteId,
    String? tipoServicio,
    String? cursor,
    int limit = 20,
  });

  Future<Resource<AvisoMantenimiento>> getAviso(String id);

  Future<Resource<AvisoMantenimiento>> updateEstado(
    String id, {
    required String nuevoEstado,
    String? notas,
  });

  Future<Resource<ConfiguracionAvisoMantenimiento>> getConfiguracion();

  Future<Resource<ConfiguracionAvisoMantenimiento>> updateConfiguracion({
    Map<String, int>? intervalos,
    int? diasAnticipacion,
    bool? habilitado,
  });

  Future<Resource<AvisoResumen>> getResumen();
}

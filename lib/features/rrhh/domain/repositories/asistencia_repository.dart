import '../../../../core/utils/resource.dart';
import '../entities/asistencia.dart';

abstract class AsistenciaRepository {
  Future<Resource<Asistencia>> registrarEntrada(Map<String, dynamic> data);

  Future<Resource<Asistencia>> registrarSalida(
      String id, Map<String, dynamic> data);

  Future<Resource<List<Asistencia>>> getAll({
    Map<String, dynamic>? queryParams,
  });

  Future<Resource<AsistenciaResumen>> getResumenMensual(
      String empleadoId, int mes, int anio);

  Future<Resource<List<Asistencia>>> registrarBulk(
      Map<String, dynamic> data);
}

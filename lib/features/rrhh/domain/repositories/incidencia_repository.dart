import '../../../../core/utils/resource.dart';
import '../entities/incidencia.dart';

abstract class IncidenciaRepository {
  Future<Resource<Incidencia>> create(Map<String, dynamic> data);

  Future<Resource<List<Incidencia>>> getAll({
    Map<String, dynamic>? queryParams,
  });

  Future<Resource<Incidencia>> getById(String id);

  Future<Resource<Incidencia>> aprobar(String id);

  Future<Resource<Incidencia>> rechazar(String id, String motivoRechazo);

  Future<Resource<Incidencia>> cancelar(String id);
}

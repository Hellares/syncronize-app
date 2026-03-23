import '../../../../core/utils/resource.dart';
import '../entities/empleado.dart';

abstract class EmpleadoRepository {
  Future<Resource<Empleado>> create(Map<String, dynamic> data);

  Future<Resource<List<Empleado>>> getAll({
    Map<String, dynamic>? queryParams,
  });

  Future<Resource<Empleado>> getById(String id);

  Future<Resource<Empleado>> update(String id, Map<String, dynamic> data);

  Future<Resource<void>> delete(String id);
}

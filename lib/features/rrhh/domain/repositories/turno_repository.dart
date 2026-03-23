import '../../../../core/utils/resource.dart';
import '../entities/turno.dart';

abstract class TurnoRepository {
  Future<Resource<Turno>> create(Map<String, dynamic> data);

  Future<Resource<List<Turno>>> getAll();

  Future<Resource<Turno>> update(String id, Map<String, dynamic> data);

  Future<Resource<void>> delete(String id);
}

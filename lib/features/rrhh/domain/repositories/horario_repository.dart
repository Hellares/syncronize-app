import '../../../../core/utils/resource.dart';
import '../entities/horario_plantilla.dart';

abstract class HorarioRepository {
  Future<Resource<HorarioPlantilla>> create(Map<String, dynamic> data);

  Future<Resource<List<HorarioPlantilla>>> getAll();

  Future<Resource<HorarioPlantilla>> getById(String id);

  Future<Resource<HorarioPlantilla>> update(
      String id, Map<String, dynamic> data);

  Future<Resource<void>> delete(String id);
}

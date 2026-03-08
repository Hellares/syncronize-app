import '../../../../core/utils/resource.dart';
import '../entities/plantilla_servicio.dart';
import '../entities/configuracion_campo.dart';

abstract class PlantillaServicioRepository {
  Future<Resource<List<PlantillaServicio>>> getAll();

  Future<Resource<PlantillaServicio>> getOne(String id);

  Future<Resource<PlantillaServicio>> crear({
    required String nombre,
    String? descripcion,
    List<Map<String, dynamic>>? campos,
  });

  Future<Resource<PlantillaServicio>> actualizar({
    required String id,
    String? nombre,
    String? descripcion,
  });

  Future<Resource<void>> eliminar(String id);

  Future<Resource<ConfiguracionCampo>> addCampo({
    required String plantillaId,
    required Map<String, dynamic> campoData,
  });

  Future<Resource<List<ConfiguracionCampo>>> getCamposByServicioId(String servicioId);
}

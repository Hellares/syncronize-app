import '../../../../core/utils/resource.dart';
import '../entities/configuracion_documentos.dart';
import '../entities/plantilla_documento.dart';
import '../entities/configuracion_documento_completa.dart';

abstract class ConfiguracionDocumentosRepository {
  Future<Resource<ConfiguracionDocumentos>> getConfiguracion();
  Future<Resource<ConfiguracionDocumentos>> updateConfiguracion(
      Map<String, dynamic> data);
  Future<Resource<List<PlantillaDocumento>>> getPlantillas();
  Future<Resource<PlantillaDocumento>> getPlantillaByTipo(
    String tipo, {
    String? formato,
  });
  Future<Resource<PlantillaDocumento>> updatePlantilla(
    String tipo,
    Map<String, dynamic> data,
  );
  Future<Resource<ConfiguracionDocumentoCompleta>> getConfiguracionCompleta(
    String tipo, {
    String? formato,
    String? sedeId,
  });
}

import '../../../../core/utils/resource.dart';
import '../entities/archivo_empresa.dart';

abstract class MultimediaRepository {
  Future<Resource<({List<ArchivoEmpresa> data, int total, int totalPages})>> getArchivos({
    required String empresaId,
    String? tipoArchivo,
    String? entidadTipo,
    int page = 1,
    int limit = 50,
    String orderBy = 'recientes',
  });

  Future<Resource<GaleriaStats>> getStats(String empresaId);

  Future<Resource<void>> deleteArchivo(String archivoId, String empresaId);
}

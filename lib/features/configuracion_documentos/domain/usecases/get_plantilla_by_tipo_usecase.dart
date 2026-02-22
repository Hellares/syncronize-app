import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/plantilla_documento.dart';
import '../repositories/configuracion_documentos_repository.dart';

@injectable
class GetPlantillaByTipoUseCase {
  final ConfiguracionDocumentosRepository _repository;

  GetPlantillaByTipoUseCase(this._repository);

  Future<Resource<PlantillaDocumento>> call({
    required String tipo,
    String? formato,
  }) async {
    return await _repository.getPlantillaByTipo(tipo, formato: formato);
  }
}

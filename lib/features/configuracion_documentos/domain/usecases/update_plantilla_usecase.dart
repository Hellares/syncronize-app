import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/plantilla_documento.dart';
import '../repositories/configuracion_documentos_repository.dart';

@injectable
class UpdatePlantillaUseCase {
  final ConfiguracionDocumentosRepository _repository;

  UpdatePlantillaUseCase(this._repository);

  Future<Resource<PlantillaDocumento>> call({
    required String tipo,
    required Map<String, dynamic> data,
  }) async {
    return await _repository.updatePlantilla(tipo, data);
  }
}

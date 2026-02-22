import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/plantilla_documento.dart';
import '../repositories/configuracion_documentos_repository.dart';

@injectable
class GetPlantillasUseCase {
  final ConfiguracionDocumentosRepository _repository;

  GetPlantillasUseCase(this._repository);

  Future<Resource<List<PlantillaDocumento>>> call() async {
    return await _repository.getPlantillas();
  }
}

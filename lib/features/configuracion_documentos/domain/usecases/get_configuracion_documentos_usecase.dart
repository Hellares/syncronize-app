import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/configuracion_documentos.dart';
import '../repositories/configuracion_documentos_repository.dart';

@injectable
class GetConfiguracionDocumentosUseCase {
  final ConfiguracionDocumentosRepository _repository;

  GetConfiguracionDocumentosUseCase(this._repository);

  Future<Resource<ConfiguracionDocumentos>> call() async {
    return await _repository.getConfiguracion();
  }
}

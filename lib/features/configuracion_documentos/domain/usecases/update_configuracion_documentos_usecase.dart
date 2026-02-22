import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/configuracion_documentos.dart';
import '../repositories/configuracion_documentos_repository.dart';

@injectable
class UpdateConfiguracionDocumentosUseCase {
  final ConfiguracionDocumentosRepository _repository;

  UpdateConfiguracionDocumentosUseCase(this._repository);

  Future<Resource<ConfiguracionDocumentos>> call({
    required Map<String, dynamic> data,
  }) async {
    return await _repository.updateConfiguracion(data);
  }
}

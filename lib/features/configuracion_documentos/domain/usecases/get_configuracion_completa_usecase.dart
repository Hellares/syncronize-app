import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/configuracion_documento_completa.dart';
import '../repositories/configuracion_documentos_repository.dart';

@injectable
class GetConfiguracionCompletaUseCase {
  final ConfiguracionDocumentosRepository _repository;

  GetConfiguracionCompletaUseCase(this._repository);

  Future<Resource<ConfiguracionDocumentoCompleta>> call({
    required String tipo,
    String? formato,
    String? sedeId,
  }) async {
    return await _repository.getConfiguracionCompleta(
      tipo,
      formato: formato,
      sedeId: sedeId,
    );
  }
}

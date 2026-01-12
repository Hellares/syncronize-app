import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/configuracion_codigos.dart';
import '../repositories/configuracion_codigos_repository.dart';

/// UseCase para obtener la configuración de códigos de una empresa
@injectable
class GetConfiguracionUseCase {
  final ConfiguracionCodigosRepository _repository;

  GetConfiguracionUseCase(this._repository);

  Future<Resource<ConfiguracionCodigos>> call(String empresaId) {
    return _repository.getConfiguracion(empresaId);
  }
}

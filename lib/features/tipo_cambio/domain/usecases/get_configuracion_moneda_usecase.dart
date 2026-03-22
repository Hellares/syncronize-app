import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/tipo_cambio.dart';
import '../repositories/tipo_cambio_repository.dart';

@injectable
class GetConfiguracionMonedaUseCase {
  final TipoCambioRepository _repository;
  GetConfiguracionMonedaUseCase(this._repository);

  Future<Resource<ConfiguracionMoneda>> call() {
    return _repository.getConfiguracion();
  }
}

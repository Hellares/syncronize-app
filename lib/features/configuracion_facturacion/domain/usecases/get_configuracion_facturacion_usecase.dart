import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/configuracion_facturacion.dart';
import '../repositories/configuracion_facturacion_repository.dart';

@lazySingleton
class GetConfiguracionFacturacionUseCase {
  final ConfiguracionFacturacionRepository _repository;

  GetConfiguracionFacturacionUseCase(this._repository);

  Future<Resource<ConfiguracionFacturacion>> call() {
    return _repository.getConfiguracion();
  }
}

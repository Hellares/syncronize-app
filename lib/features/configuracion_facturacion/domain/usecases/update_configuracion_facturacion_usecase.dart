import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/configuracion_facturacion.dart';
import '../repositories/configuracion_facturacion_repository.dart';

@lazySingleton
class UpdateConfiguracionFacturacionUseCase {
  final ConfiguracionFacturacionRepository _repository;

  UpdateConfiguracionFacturacionUseCase(this._repository);

  Future<Resource<ConfiguracionFacturacion>> call(
    Map<String, dynamic> data,
  ) {
    return _repository.updateConfiguracion(data);
  }
}

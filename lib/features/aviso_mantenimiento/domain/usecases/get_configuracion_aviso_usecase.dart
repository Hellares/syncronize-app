import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/aviso_mantenimiento.dart';
import '../repositories/aviso_mantenimiento_repository.dart';

@injectable
class GetConfiguracionAvisoUseCase {
  final AvisoMantenimientoRepository _repository;

  GetConfiguracionAvisoUseCase(this._repository);

  Future<Resource<ConfiguracionAvisoMantenimiento>> call() {
    return _repository.getConfiguracion();
  }
}

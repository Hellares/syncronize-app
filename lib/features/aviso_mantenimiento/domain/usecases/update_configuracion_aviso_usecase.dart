import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/aviso_mantenimiento.dart';
import '../repositories/aviso_mantenimiento_repository.dart';

@injectable
class UpdateConfiguracionAvisoUseCase {
  final AvisoMantenimientoRepository _repository;

  UpdateConfiguracionAvisoUseCase(this._repository);

  Future<Resource<ConfiguracionAvisoMantenimiento>> call({
    Map<String, int>? intervalos,
    int? diasAnticipacion,
    bool? habilitado,
  }) {
    return _repository.updateConfiguracion(
      intervalos: intervalos,
      diasAnticipacion: diasAnticipacion,
      habilitado: habilitado,
    );
  }
}

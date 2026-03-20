import '../../../../core/utils/resource.dart';
import '../entities/actividad_unificada.dart';
import '../repositories/portal_unificado_repository.dart';

class GetActividadUnificadaUseCase {
  final PortalUnificadoRepository _repository;

  GetActividadUnificadaUseCase(this._repository);

  Future<Resource<ActividadUnificada>> call() {
    return _repository.getActividadUnificada();
  }
}

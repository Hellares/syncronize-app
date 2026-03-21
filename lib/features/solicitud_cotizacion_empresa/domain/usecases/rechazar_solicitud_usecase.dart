import 'package:injectable/injectable.dart';

import '../../../../core/utils/resource.dart';
import '../repositories/solicitud_empresa_repository.dart';

@injectable
class RechazarSolicitudUseCase {
  final SolicitudEmpresaRepository _repository;

  RechazarSolicitudUseCase(this._repository);

  Future<Resource<void>> call(String id, String motivo) {
    return _repository.rechazar(id, motivo);
  }
}

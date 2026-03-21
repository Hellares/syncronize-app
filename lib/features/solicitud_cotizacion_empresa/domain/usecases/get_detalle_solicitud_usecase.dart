import 'package:injectable/injectable.dart';

import '../../../../core/utils/resource.dart';
import '../entities/solicitud_empresa.dart';
import '../repositories/solicitud_empresa_repository.dart';

@injectable
class GetDetalleSolicitudUseCase {
  final SolicitudEmpresaRepository _repository;

  GetDetalleSolicitudUseCase(this._repository);

  Future<Resource<SolicitudRecibida>> call(String id) {
    return _repository.detalleRecibida(id);
  }
}

import 'package:injectable/injectable.dart';

import '../../../../core/utils/resource.dart';
import '../repositories/solicitud_empresa_repository.dart';

@injectable
class CotizarSolicitudUseCase {
  final SolicitudEmpresaRepository _repository;

  CotizarSolicitudUseCase(this._repository);

  Future<Resource<void>> call(String id, String cotizacionId) {
    return _repository.cotizar(id, cotizacionId);
  }
}

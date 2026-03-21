import 'package:injectable/injectable.dart';

import '../../../../core/utils/resource.dart';
import '../entities/solicitud_empresa.dart';
import '../repositories/solicitud_empresa_repository.dart';

@injectable
class GetSolicitudesRecibidasUseCase {
  final SolicitudEmpresaRepository _repository;

  GetSolicitudesRecibidasUseCase(this._repository);

  Future<Resource<List<SolicitudRecibida>>> call({String? estado}) {
    return _repository.listarRecibidas(estado: estado);
  }
}

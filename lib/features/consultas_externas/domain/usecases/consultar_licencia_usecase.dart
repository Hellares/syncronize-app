import 'package:injectable/injectable.dart';

import '../../../../core/utils/resource.dart';
import '../entities/consulta_licencia.dart';
import '../repositories/consultas_repository.dart';

@lazySingleton
class ConsultarLicenciaUseCase {
  final ConsultasRepository _repository;

  ConsultarLicenciaUseCase(this._repository);

  Future<Resource<ConsultaLicencia>> call(String dni) {
    return _repository.consultarLicencia(dni);
  }
}

import 'package:injectable/injectable.dart';

import '../../../../core/utils/resource.dart';
import '../entities/consulta_dni.dart';
import '../repositories/consultas_repository.dart';

@lazySingleton
class ConsultarDniUseCase {
  final ConsultasRepository _repository;

  ConsultarDniUseCase(this._repository);

  Future<Resource<ConsultaDni>> call(String dni) {
    return _repository.consultarDni(dni);
  }
}

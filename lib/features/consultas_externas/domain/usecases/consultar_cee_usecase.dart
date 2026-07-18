import 'package:injectable/injectable.dart';

import '../../../../core/utils/resource.dart';
import '../entities/consulta_dni.dart';
import '../repositories/consultas_repository.dart';

/// Consulta un Carné de Extranjería (9 dígitos) en Migraciones vía
/// Factiliza. Devuelve la misma entidad que el DNI pero sin dirección.
@lazySingleton
class ConsultarCeeUseCase {
  final ConsultasRepository _repository;

  ConsultarCeeUseCase(this._repository);

  Future<Resource<ConsultaDni>> call(String cee) {
    return _repository.consultarCee(cee);
  }
}

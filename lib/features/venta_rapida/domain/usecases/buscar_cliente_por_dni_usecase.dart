import 'package:injectable/injectable.dart';

import '../../../../core/utils/resource.dart';
import '../repositories/venta_rapida_repository.dart';

/// Resuelve un cliente por DNI (interno o RENIEC) y lo registra en el sistema
/// si no existía. Idempotente: el mismo DNI siempre devuelve el mismo
/// `clienteEmpresaId` para la empresa actual.
@lazySingleton
class BuscarClientePorDniUseCase {
  final VentaRapidaRepository _repository;

  BuscarClientePorDniUseCase(this._repository);

  Future<Resource<ClienteResueltoDni>> call(String dni) {
    return _repository.buscarClientePorDni(dni);
  }
}

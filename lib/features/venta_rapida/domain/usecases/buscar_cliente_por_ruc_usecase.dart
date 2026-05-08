import 'package:injectable/injectable.dart';

import '../../../../core/utils/resource.dart';
import '../repositories/venta_rapida_repository.dart';

/// Resuelve un cliente empresa (B2B) por RUC vía SUNAT y lo registra en el
/// sistema si no existía. Idempotente: el mismo RUC siempre devuelve el
/// mismo `clienteEmpresaId` para la empresa actual.
@lazySingleton
class BuscarClientePorRucUseCase {
  final VentaRapidaRepository _repository;

  BuscarClientePorRucUseCase(this._repository);

  Future<Resource<ClienteResueltoRuc>> call(String ruc) {
    return _repository.buscarClientePorRuc(ruc);
  }
}

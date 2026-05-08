import 'package:injectable/injectable.dart';

import '../../../../core/utils/resource.dart';
import '../repositories/venta_rapida_repository.dart';

/// Resuelve el clienteId del EmpresaPersona "CLIENTES VARIOS" (DNI 00000000)
/// asociado a la empresa actual. Si no existe, el backend lo crea on-the-fly.
@lazySingleton
class ObtenerClienteGenericoUseCase {
  final VentaRapidaRepository _repository;

  ObtenerClienteGenericoUseCase(this._repository);

  Future<Resource<String>> call() {
    return _repository.obtenerClienteGenericoId();
  }
}

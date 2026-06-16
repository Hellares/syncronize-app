import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../repositories/descuento_repository.dart';

/// Use case para asignar clientes (VIP) a una política de precio especial
@injectable
class AsignarClientes {
  final DescuentoRepository _repository;

  AsignarClientes(this._repository);

  Future<Resource<List<Map<String, dynamic>>>> call({
    required String politicaId,
    List<String>? clienteIds,
    List<String>? clienteEmpresaIds,
  }) async {
    return await _repository.asignarClientes(
      politicaId: politicaId,
      clienteIds: clienteIds,
      clienteEmpresaIds: clienteEmpresaIds,
    );
  }
}

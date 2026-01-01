import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/cliente.dart';
import '../repositories/cliente_repository.dart';

/// Use case para obtener un cliente específico
@injectable
class GetClienteUseCase {
  final ClienteRepository _repository;

  GetClienteUseCase(this._repository);

  /// Obtiene un cliente por su ID
  Future<Resource<Cliente>> call({
    required String empresaId,
    required String clienteId,
  }) async {
    return await _repository.getCliente(
      empresaId: empresaId,
      clienteId: clienteId,
    );
  }
}

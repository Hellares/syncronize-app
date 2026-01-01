import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/cliente_filtros.dart';
import '../entities/registro_cliente_response.dart';
import '../repositories/cliente_repository.dart';

/// Use case para obtener la lista de clientes
@injectable
class GetClientesUseCase {
  final ClienteRepository _repository;

  GetClientesUseCase(this._repository);

  /// Obtiene la lista de clientes con filtros y paginación
  Future<Resource<ClientesPaginados>> call({
    required String empresaId,
    required ClienteFiltros filtros,
  }) async {
    return await _repository.getClientes(
      empresaId: empresaId,
      filtros: filtros,
    );
  }
}

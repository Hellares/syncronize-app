import '../../../../core/utils/resource.dart';
import '../entities/cliente.dart';
import '../entities/cliente_filtros.dart';
import '../entities/registro_cliente_response.dart';

/// Repository interface para operaciones de clientes
abstract class ClienteRepository {
  /// Registra un nuevo cliente o asocia uno existente a la empresa
  Future<Resource<RegistroClienteResponse>> registrarCliente({
    required String empresaId,
    required Map<String, dynamic> data,
  });

  /// Obtiene la lista de clientes de una empresa con filtros
  Future<Resource<ClientesPaginados>> getClientes({
    required String empresaId,
    required ClienteFiltros filtros,
  });

  /// Obtiene un cliente específico por ID
  Future<Resource<Cliente>> getCliente({
    required String empresaId,
    required String clienteId,
  });

  /// Actualiza los datos de un cliente
  Future<Resource<Cliente>> updateCliente({
    required String empresaId,
    required String clienteId,
    required Map<String, dynamic> data,
  });

  /// Elimina un cliente (soft delete)
  Future<Resource<void>> deleteCliente({
    required String empresaId,
    required String clienteId,
  });
}

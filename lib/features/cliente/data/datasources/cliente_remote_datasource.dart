import 'package:injectable/injectable.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../../domain/entities/cliente_filtros.dart';
import '../models/cliente_model.dart';
import '../models/registro_cliente_response_model.dart';

/// Data source remoto para operaciones de clientes
@lazySingleton
class ClienteRemoteDataSource {
  final DioClient _dioClient;

  ClienteRemoteDataSource(this._dioClient);

  /// Registra un nuevo cliente o asocia uno existente
  ///
  /// POST /api/clientes
  Future<RegistroClienteResponseModel> registrarCliente(
    Map<String, dynamic> data,
  ) async {
    final response = await _dioClient.post(
      ApiConstants.clientes,
      data: data,
    );

    return RegistroClienteResponseModel.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  /// Obtiene lista paginada de clientes con filtros
  ///
  /// GET /api/clientes?page=1&limit=10&...
  /// Nota: empresaId se valida automáticamente en headers X-Tenant-ID
  Future<Map<String, dynamic>> getClientes({
    required String empresaId,
    required ClienteFiltros filtros,
  }) async {
    final queryParams = filtros.toQueryParams();

    final response = await _dioClient.get(
      ApiConstants.clientes,
      queryParameters: queryParams,
    );

    return response.data as Map<String, dynamic>;
  }

  /// Obtiene un cliente por ID
  ///
  /// GET /api/clientes/:id
  /// Nota: empresaId se valida automáticamente en headers X-Tenant-ID
  Future<ClienteModel> getCliente({
    required String clienteId,
    required String empresaId,
  }) async {
    final response = await _dioClient.get(
      '${ApiConstants.clientes}/$clienteId',
    );

    return ClienteModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// Actualiza un cliente existente
  ///
  /// PUT /api/clientes/:id
  /// Nota: empresaId se valida automáticamente en headers X-Tenant-ID
  Future<ClienteModel> actualizarCliente({
    required String clienteId,
    required String empresaId,
    required Map<String, dynamic> data,
  }) async {
    final response = await _dioClient.put(
      '${ApiConstants.clientes}/$clienteId',
      data: data,
    );

    return ClienteModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// Elimina un cliente (soft delete)
  ///
  /// DELETE /api/clientes/:id
  /// Nota: empresaId se valida automáticamente en headers X-Tenant-ID
  Future<void> eliminarCliente({
    required String clienteId,
    required String empresaId,
  }) async {
    await _dioClient.delete(
      '${ApiConstants.clientes}/$clienteId',
    );
  }
}

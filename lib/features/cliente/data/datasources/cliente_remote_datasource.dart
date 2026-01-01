import 'package:dio/dio.dart';
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
    try {
      final response = await _dioClient.post(
        ApiConstants.clientes,
        data: data,
      );

      return RegistroClienteResponseModel.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('Error inesperado al registrar cliente: $e');
    }
  }

  /// Obtiene lista paginada de clientes con filtros
  ///
  /// GET /api/clientes?page=1&limit=10&...
  /// Nota: empresaId se valida automáticamente en headers X-Tenant-ID
  Future<Map<String, dynamic>> getClientes({
    required String empresaId,
    required ClienteFiltros filtros,
  }) async {
    try {
      final queryParams = filtros.toQueryParams();

      final response = await _dioClient.get(
        ApiConstants.clientes,
        queryParameters: queryParams,
      );

      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('Error inesperado al obtener clientes: $e');
    }
  }

  /// Obtiene un cliente por ID
  ///
  /// GET /api/clientes/:id
  /// Nota: empresaId se valida automáticamente en headers X-Tenant-ID
  Future<ClienteModel> getCliente({
    required String clienteId,
    required String empresaId,
  }) async {
    try {
      final response = await _dioClient.get(
        '${ApiConstants.clientes}/$clienteId',
      );

      return ClienteModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('Error inesperado al obtener cliente: $e');
    }
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
    try {
      final response = await _dioClient.put(
        '${ApiConstants.clientes}/$clienteId',
        data: data,
      );

      return ClienteModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('Error inesperado al actualizar cliente: $e');
    }
  }

  /// Elimina un cliente (soft delete)
  ///
  /// DELETE /api/clientes/:id
  /// Nota: empresaId se valida automáticamente en headers X-Tenant-ID
  Future<void> eliminarCliente({
    required String clienteId,
    required String empresaId,
  }) async {
    try {
      await _dioClient.delete(
        '${ApiConstants.clientes}/$clienteId',
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('Error inesperado al eliminar cliente: $e');
    }
  }

  /// Maneja errores de Dio y los convierte a excepciones con mensajes descriptivos
  Exception _handleDioError(DioException error) {
    if (error.response != null) {
      final statusCode = error.response!.statusCode;
      final data = error.response!.data;

      String message = 'Error del servidor';

      if (data is Map<String, dynamic>) {
        message = data['message'] as String? ??
            data['error'] as String? ??
            message;
      }

      switch (statusCode) {
        case 400:
          return Exception('Solicitud inválida: $message');
        case 401:
          return Exception('No autorizado: $message');
        case 403:
          return Exception('No tienes permisos para esta operación');
        case 404:
          return Exception('Cliente no encontrado');
        case 500:
          return Exception('Error del servidor: $message');
        default:
          return Exception('Error HTTP $statusCode: $message');
      }
    }

    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      return Exception('Tiempo de espera agotado');
    }

    if (error.type == DioExceptionType.connectionError) {
      return Exception('Error de conexión. Verifica tu internet.');
    }

    return Exception('Error de red: ${error.message}');
  }
}

import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/network/dio_client.dart';
import '../models/proveedor_model.dart';
import '../models/proveedor_evaluacion_model.dart';

/// Data source remoto para operaciones de proveedores
@lazySingleton
class ProveedorRemoteDataSource {
  final DioClient _dioClient;

  ProveedorRemoteDataSource(this._dioClient);

  /// Obtiene lista de proveedores
  ///
  /// GET /api/empresas/:empresaId/proveedores
  Future<List<ProveedorModel>> getProveedores({
    required String empresaId,
    bool includeInactive = false,
  }) async {
    try {
      final response = await _dioClient.get(
        '/empresas/$empresaId/proveedores',
        queryParameters: {
          if (includeInactive) 'includeInactive': 'true',
        },
      );

      final data = response.data as List;
      return data
          .map((json) => ProveedorModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('Error inesperado al obtener proveedores: $e');
    }
  }

  /// Obtiene un proveedor por ID
  ///
  /// GET /api/empresas/:empresaId/proveedores/:id
  Future<ProveedorModel> getProveedor({
    required String empresaId,
    required String proveedorId,
  }) async {
    try {
      final response = await _dioClient.get(
        '/empresas/$empresaId/proveedores/$proveedorId',
      );

      return ProveedorModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('Error inesperado al obtener proveedor: $e');
    }
  }

  /// Crea un nuevo proveedor
  ///
  /// POST /api/empresas/:empresaId/proveedores
  Future<ProveedorModel> crearProveedor({
    required String empresaId,
    required Map<String, dynamic> data,
  }) async {
    try {
      final response = await _dioClient.post(
        '/empresas/$empresaId/proveedores',
        data: data,
      );

      return ProveedorModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('Error inesperado al crear proveedor: $e');
    }
  }

  /// Actualiza un proveedor
  ///
  /// PUT /api/empresas/:empresaId/proveedores/:id
  Future<ProveedorModel> actualizarProveedor({
    required String empresaId,
    required String proveedorId,
    required Map<String, dynamic> data,
  }) async {
    try {
      final response = await _dioClient.put(
        '/empresas/$empresaId/proveedores/$proveedorId',
        data: data,
      );

      return ProveedorModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('Error inesperado al actualizar proveedor: $e');
    }
  }

  /// Elimina un proveedor (soft delete)
  ///
  /// DELETE /api/empresas/:empresaId/proveedores/:id
  Future<void> eliminarProveedor({
    required String empresaId,
    required String proveedorId,
    String? motivo,
  }) async {
    try {
      await _dioClient.delete(
        '/empresas/$empresaId/proveedores/$proveedorId',
        data: motivo != null ? {'motivo': motivo} : null,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('Error inesperado al eliminar proveedor: $e');
    }
  }

  /// Evalúa un proveedor
  ///
  /// POST /api/empresas/:empresaId/proveedores/:id/evaluar
  Future<ProveedorEvaluacionModel> evaluarProveedor({
    required String empresaId,
    required String proveedorId,
    required Map<String, dynamic> data,
  }) async {
    try {
      final response = await _dioClient.post(
        '/empresas/$empresaId/proveedores/$proveedorId/evaluar',
        data: data,
      );

      return ProveedorEvaluacionModel.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('Error inesperado al evaluar proveedor: $e');
    }
  }

  /// Obtiene evaluaciones de un proveedor
  ///
  /// GET /api/empresas/:empresaId/proveedores/:id/evaluaciones
  Future<List<ProveedorEvaluacionModel>> getEvaluaciones({
    required String empresaId,
    required String proveedorId,
  }) async {
    try {
      final response = await _dioClient.get(
        '/empresas/$empresaId/proveedores/$proveedorId/evaluaciones',
      );

      final data = response.data as List;
      return data
          .map((json) =>
              ProveedorEvaluacionModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('Error inesperado al obtener evaluaciones: $e');
    }
  }

  /// Maneja errores de Dio y los convierte en excepciones más descriptivas
  Exception _handleDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return Exception('Error de conexión: Tiempo de espera agotado');

      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        final message = e.response?.data?['message'] ?? 'Error desconocido';

        switch (statusCode) {
          case 400:
            return Exception('Datos inválidos: $message');
          case 401:
            return Exception('No autorizado. Por favor, inicie sesión nuevamente');
          case 403:
            return Exception('No tiene permisos para realizar esta acción');
          case 404:
            return Exception('Proveedor no encontrado');
          case 409:
            return Exception('Conflicto: $message');
          case 500:
            return Exception('Error del servidor. Intente nuevamente más tarde');
          default:
            return Exception('Error: $message');
        }

      case DioExceptionType.cancel:
        return Exception('Petición cancelada');

      case DioExceptionType.connectionError:
        return Exception(
            'Error de conexión. Verifique su conexión a internet');

      default:
        return Exception('Error inesperado: ${e.message}');
    }
  }
}

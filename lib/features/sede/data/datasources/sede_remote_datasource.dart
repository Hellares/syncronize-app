import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/network/dio_client.dart';
import '../../../empresa/data/models/sede_model.dart';

/// Data source remoto para operaciones de sede
@lazySingleton
class SedeRemoteDataSource {
  final DioClient _dioClient;

  SedeRemoteDataSource(this._dioClient);

  /// Obtiene todas las sedes de una empresa
  ///
  /// GET /api/empresas/:empresaId/sedes
  Future<List<SedeModel>> getSedes(String empresaId) async {
    try {
      final response = await _dioClient.get(
        '/empresas/$empresaId/sedes',
      );

      if (response.data is! List) {
        throw Exception('Respuesta inválida del servidor');
      }

      return (response.data as List)
          .map((json) => SedeModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('Error inesperado al obtener sedes: $e');
    }
  }

  /// Obtiene los detalles de una sede específica
  ///
  /// GET /api/empresas/:empresaId/sedes/:sedeId
  Future<SedeModel> getSedeById({
    required String empresaId,
    required String sedeId,
  }) async {
    try {
      final response = await _dioClient.get(
        '/empresas/$empresaId/sedes/$sedeId',
      );

      return SedeModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('Error inesperado al obtener sede: $e');
    }
  }

  /// Crea una nueva sede
  ///
  /// POST /api/empresas/:empresaId/sedes
  Future<SedeModel> createSede({
    required String empresaId,
    required Map<String, dynamic> data,
  }) async {
    try {
      final response = await _dioClient.post(
        '/empresas/$empresaId/sedes',
        data: data,
      );

      return SedeModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('Error inesperado al crear sede: $e');
    }
  }

  /// Actualiza una sede existente
  ///
  /// PUT /api/empresas/:empresaId/sedes/:sedeId
  Future<SedeModel> updateSede({
    required String empresaId,
    required String sedeId,
    required Map<String, dynamic> data,
  }) async {
    try {
      final response = await _dioClient.put(
        '/empresas/$empresaId/sedes/$sedeId',
        data: data,
      );

      return SedeModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('Error inesperado al actualizar sede: $e');
    }
  }

  /// Elimina una sede (soft delete)
  ///
  /// DELETE /api/empresas/:empresaId/sedes/:sedeId
  Future<void> deleteSede({
    required String empresaId,
    required String sedeId,
  }) async {
    try {
      await _dioClient.delete(
        '/empresas/$empresaId/sedes/$sedeId',
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('Error inesperado al eliminar sede: $e');
    }
  }

  /// Obtiene los usuarios asignados a una sede
  ///
  /// GET /api/empresas/:empresaId/sedes/:sedeId/usuarios
  Future<List<Map<String, dynamic>>> getSedeUsuarios({
    required String empresaId,
    required String sedeId,
  }) async {
    try {
      final response = await _dioClient.get(
        '/empresas/$empresaId/sedes/$sedeId/usuarios',
      );

      if (response.data is! List) {
        throw Exception('Respuesta inválida del servidor');
      }

      return (response.data as List).cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('Error inesperado al obtener usuarios de sede: $e');
    }
  }

  /// Asigna un usuario a una sede con un rol específico
  ///
  /// POST /api/empresas/:empresaId/sedes/:sedeId/usuarios
  Future<Map<String, dynamic>> assignUsuarioToSede({
    required String empresaId,
    required String sedeId,
    required Map<String, dynamic> data,
  }) async {
    try {
      final response = await _dioClient.post(
        '/empresas/$empresaId/sedes/$sedeId/usuarios',
        data: data,
      );

      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('Error inesperado al asignar usuario a sede: $e');
    }
  }

  /// Remueve un usuario de una sede
  ///
  /// DELETE /api/empresas/:empresaId/sedes/:sedeId/usuarios/:usuarioSedeRolId
  Future<void> removeUsuarioFromSede({
    required String empresaId,
    required String sedeId,
    required String usuarioSedeRolId,
  }) async {
    try {
      await _dioClient.delete(
        '/empresas/$empresaId/sedes/$sedeId/usuarios/$usuarioSedeRolId',
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('Error inesperado al remover usuario de sede: $e');
    }
  }

  /// Manejo de errores de Dio
  Exception _handleDioError(DioException error) {
    if (error.response != null) {
      final statusCode = error.response!.statusCode;
      final data = error.response!.data;

      // Extraer mensaje de error del backend
      String message = 'Error del servidor';
      if (data is Map<String, dynamic>) {
        message = data['message'] as String? ?? message;
      }

      switch (statusCode) {
        case 400:
          return Exception('Datos inválidos: $message');
        case 401:
          return Exception('No autorizado. Inicia sesión nuevamente.');
        case 403:
          return Exception('No tienes permisos para realizar esta acción.');
        case 404:
          return Exception('Sede no encontrada');
        case 409:
          return Exception('Conflicto: $message');
        case 500:
          return Exception('Error del servidor. Intenta nuevamente.');
        default:
          return Exception(message);
      }
    }

    // Errores de conexión
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout) {
      return Exception('Error de conexión. Verifica tu internet.');
    }

    if (error.type == DioExceptionType.unknown) {
      return Exception('Sin conexión a internet');
    }

    return Exception('Error inesperado: ${error.message}');
  }
}

import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../../domain/entities/usuario_filtros.dart';
import '../models/registro_usuario_response_model.dart';

/// DataSource remoto para usuarios
///
/// Maneja todas las llamadas HTTP al backend relacionadas con usuarios
@lazySingleton
class UsuarioRemoteDataSource {
  final DioClient _dioClient;

  UsuarioRemoteDataSource(this._dioClient);

  /// Registra un nuevo usuario/empleado o asigna uno existente
  ///
  /// Throws [DioException] en caso de error
  Future<RegistroUsuarioResponseModel> registrarUsuario(
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _dioClient.post(
        '${ApiConstants.usuarios}/registrar',
        data: data,
      );

      return RegistroUsuarioResponseModel.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('Error inesperado al registrar usuario: $e');
    }
  }

  /// Obtiene la lista de usuarios con paginación y filtros
  ///
  /// Throws [DioException] en caso de error
  Future<Map<String, dynamic>> getUsuarios({
    required String empresaId,
    required UsuarioFiltros filtros,
  }) async {
    try {
      final queryParams = filtros.toQueryParams();

      final response = await _dioClient.get(
        ApiConstants.usuarios,
        queryParameters: queryParams,
      );

      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('Error inesperado al obtener usuarios: $e');
    }
  }

  /// Obtiene un usuario específico por ID
  ///
  /// Throws [DioException] en caso de error
  Future<Map<String, dynamic>> getUsuario({
    required String empresaId,
    required String usuarioId,
  }) async {
    try {
      final response = await _dioClient.get(
        '${ApiConstants.usuarios}/$usuarioId',
      );

      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('Error inesperado al obtener usuario: $e');
    }
  }

  /// Actualiza un usuario
  ///
  /// Throws [DioException] en caso de error
  Future<Map<String, dynamic>> updateUsuario({
    required String empresaId,
    required String usuarioId,
    required Map<String, dynamic> data,
  }) async {
    try {
      final response = await _dioClient.put(
        '${ApiConstants.usuarios}/$usuarioId',
        data: data,
      );

      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('Error inesperado al actualizar usuario: $e');
    }
  }

  /// Elimina (soft delete) un usuario
  ///
  /// Throws [DioException] en caso de error
  Future<void> deleteUsuario({
    required String empresaId,
    required String usuarioId,
  }) async {
    try {
      await _dioClient.delete(
        '${ApiConstants.usuarios}/$usuarioId',
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('Error inesperado al eliminar usuario: $e');
    }
  }

  /// Maneja errores de Dio y los convierte en excepciones más legibles
  Exception _handleDioError(DioException e) {
    final response = e.response;

    if (response != null && response.data != null) {
      final data = response.data;

      // Intenta extraer el mensaje de error del backend
      String message = 'Error en la petición';

      if (data is Map<String, dynamic>) {
        message = data['message'] as String? ??
            data['error'] as String? ??
            message;
      } else if (data is String) {
        message = data;
      }

      return Exception(message);
    }

    // Manejo de errores de conexión
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      return Exception(
        'Tiempo de espera agotado. Verifica tu conexión a internet.',
      );
    }

    if (e.type == DioExceptionType.connectionError) {
      return Exception(
        'No se pudo conectar al servidor. Verifica tu conexión a internet.',
      );
    }

    return Exception('Error inesperado: ${e.message}');
  }
}

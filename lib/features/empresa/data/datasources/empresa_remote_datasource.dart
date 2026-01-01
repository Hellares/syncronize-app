import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../models/empresa_context_model.dart';
import '../models/empresa_list_item_model.dart';
import '../models/personalizacion_empresa_model.dart';

/// Data source remoto para operaciones de empresa
@lazySingleton
class EmpresaRemoteDataSource {
  final DioClient _dioClient;

  EmpresaRemoteDataSource(this._dioClient);

  /// Obtiene la lista de empresas del usuario
  ///
  /// GET /api/empresas
  Future<List<EmpresaListItemModel>> getUserEmpresas() async {
    try {
      final response = await _dioClient.get(ApiConstants.empresas);

      if (response.data is! List) {
        throw Exception('Respuesta inválida del servidor');
      }

      return (response.data as List)
          .map((json) => EmpresaListItemModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('Error inesperado al obtener empresas del usuario: $e');
    }
  }

  /// Obtiene el contexto completo de una empresa desde el backend
  ///
  /// GET /api/empresas/:empresaId/context
  Future<EmpresaContextModel> getEmpresaContext(String empresaId) async {
    try {
      final response = await _dioClient.get(
        '${ApiConstants.empresas}/$empresaId/context',
      );

      return EmpresaContextModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('Error inesperado al obtener contexto de empresa: $e');
    }
  }

  /// Cambia la empresa activa (switch tenant)
  ///
  /// POST /api/auth/switch-tenant
  Future<void> switchEmpresa({
    required String empresaId,
    String? subdominioEmpresa,
  }) async {
    try {
      await _dioClient.post(
        '/auth/switch-tenant',
        data: {
          'empresaId': empresaId,
          if (subdominioEmpresa != null) 'subdominioEmpresa': subdominioEmpresa,
        },
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('Error inesperado al cambiar empresa: $e');
    }
  }

  /// Obtiene la personalización de la empresa
  ///
  /// GET /api/empresas/:empresaId/personalizacion
  Future<PersonalizacionEmpresaModel> getPersonalizacion(String empresaId) async {
    try {
      final response = await _dioClient.get(
        '${ApiConstants.empresas}/$empresaId/personalizacion',
      );

      return PersonalizacionEmpresaModel.fromJson(
          response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('Error inesperado al obtener personalización: $e');
    }
  }

  /// Actualiza la personalización de la empresa
  ///
  /// PUT /api/empresas/:empresaId/personalizacion
  Future<PersonalizacionEmpresaModel> updatePersonalizacion({
    required String empresaId,
    required Map<String, dynamic> data,
  }) async {
    try {
      final response = await _dioClient.put(
        '${ApiConstants.empresas}/$empresaId/personalizacion',
        data: data,
      );

      return PersonalizacionEmpresaModel.fromJson(
          response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('Error inesperado al actualizar personalización: $e');
    }
  }

  /// Maneja errores de Dio y los convierte en excepciones con mensajes claros
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
          return Exception('No tienes acceso a esta empresa');
        case 404:
          return Exception('Empresa no encontrada');
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

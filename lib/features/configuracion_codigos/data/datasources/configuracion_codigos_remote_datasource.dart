import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../models/configuracion_codigos_model.dart';

/// Data source remoto para operaciones de configuración de códigos
@lazySingleton
class ConfiguracionCodigosRemoteDataSource {
  final DioClient _dioClient;

  ConfiguracionCodigosRemoteDataSource(this._dioClient);

  /// Obtener configuración de códigos de una empresa
  ///
  /// GET /api/configuracion-codigos/:empresaId
  Future<ConfiguracionCodigosModel> getConfiguracion(String empresaId) async {
    try {
      final response = await _dioClient.get(
        '${ApiConstants.configuracionCodigos}/$empresaId',
      );

      return ConfiguracionCodigosModel.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('Error inesperado al obtener configuración: $e');
    }
  }

  /// Actualizar configuración de productos
  ///
  /// PUT /api/configuracion-codigos/:empresaId/productos
  Future<ConfiguracionCodigosModel> updateConfigProductos({
    required String empresaId,
    Map<String, dynamic>? data,
  }) async {
    try {
      final response = await _dioClient.put(
        '${ApiConstants.configuracionCodigos}/$empresaId/productos',
        data: data ?? {},
      );

      return ConfiguracionCodigosModel.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception(
        'Error inesperado al actualizar configuración de productos: $e',
      );
    }
  }

  /// Actualizar configuración de variantes
  ///
  /// PUT /api/configuracion-codigos/:empresaId/variantes
  Future<ConfiguracionCodigosModel> updateConfigVariantes({
    required String empresaId,
    Map<String, dynamic>? data,
  }) async {
    try {
      final response = await _dioClient.put(
        '${ApiConstants.configuracionCodigos}/$empresaId/variantes',
        data: data ?? {},
      );

      return ConfiguracionCodigosModel.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception(
        'Error inesperado al actualizar configuración de variantes: $e',
      );
    }
  }

  /// Actualizar configuración de servicios
  ///
  /// PUT /api/configuracion-codigos/:empresaId/servicios
  Future<ConfiguracionCodigosModel> updateConfigServicios({
    required String empresaId,
    Map<String, dynamic>? data,
  }) async {
    try {
      final response = await _dioClient.put(
        '${ApiConstants.configuracionCodigos}/$empresaId/servicios',
        data: data ?? {},
      );

      return ConfiguracionCodigosModel.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception(
        'Error inesperado al actualizar configuración de servicios: $e',
      );
    }
  }

  /// Actualizar configuración de ventas (Notas de Venta)
  ///
  /// PUT /api/configuracion-codigos/:empresaId/ventas
  Future<ConfiguracionCodigosModel> updateConfigVentas({
    required String empresaId,
    Map<String, dynamic>? data,
  }) async {
    try {
      final response = await _dioClient.put(
        '${ApiConstants.configuracionCodigos}/$empresaId/ventas',
        data: data ?? {},
      );

      return ConfiguracionCodigosModel.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception(
        'Error inesperado al actualizar configuración de ventas: $e',
      );
    }
  }

  /// Vista previa de código
  ///
  /// POST /api/configuracion-codigos/:empresaId/preview
  Future<PreviewCodigoModel> previewCodigo({
    required String empresaId,
    required Map<String, dynamic> data,
  }) async {
    try {
      final response = await _dioClient.post(
        '${ApiConstants.configuracionCodigos}/$empresaId/preview',
        data: data,
      );

      return PreviewCodigoModel.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('Error inesperado al obtener vista previa: $e');
    }
  }

  /// Sincronizar contador con estado real de BD
  ///
  /// POST /api/configuracion-codigos/:empresaId/sincronizar/:tipo
  Future<Map<String, dynamic>> sincronizarContador({
    required String empresaId,
    required String tipo,
  }) async {
    try {
      final response = await _dioClient.post(
        '${ApiConstants.configuracionCodigos}/$empresaId/sincronizar/$tipo',
      );

      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('Error inesperado al sincronizar contador: $e');
    }
  }

  /// Maneja errores de Dio y devuelve un mensaje apropiado
  Exception _handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return Exception(
          'Tiempo de espera agotado. Verifica tu conexión a internet.',
        );
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        final message = error.response?.data?['message'] as String?;

        if (statusCode == 400) {
          return Exception(message ?? 'Solicitud inválida');
        } else if (statusCode == 401) {
          return Exception('No autorizado. Inicia sesión nuevamente.');
        } else if (statusCode == 403) {
          return Exception(message ?? 'No tienes permisos para esta acción');
        } else if (statusCode == 404) {
          return Exception(message ?? 'Configuración no encontrada');
        } else if (statusCode == 500) {
          return Exception('Error del servidor. Intenta nuevamente más tarde.');
        }
        return Exception(message ?? 'Error al procesar la solicitud');
      case DioExceptionType.cancel:
        return Exception('Solicitud cancelada');
      case DioExceptionType.unknown:
        return Exception(
          'Error de conexión. Verifica tu conexión a internet.',
        );
      default:
        return Exception('Error inesperado: ${error.message}');
    }
  }
}

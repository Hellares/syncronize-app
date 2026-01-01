import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../models/configuracion_precio_model.dart';

/// Data source remoto para operaciones de configuraciones de precios
@lazySingleton
class ConfiguracionPrecioRemoteDataSource {
  final DioClient _dioClient;

  ConfiguracionPrecioRemoteDataSource(this._dioClient);

  /// Crea una nueva configuración de precios
  ///
  /// POST /api/configuraciones-precio
  Future<ConfiguracionPrecioModel> crear(
    ConfiguracionPrecioDto dto,
  ) async {
    try {
      final response = await _dioClient.post(
        ApiConstants.configuracionesPrecios,
        data: dto.toJson(),
      );

      return ConfiguracionPrecioModel.fromJson(
          response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('Error inesperado al crear configuración: $e');
    }
  }

  /// Obtiene todas las configuraciones de precios de la empresa
  ///
  /// GET /api/configuraciones-precio
  Future<List<ConfiguracionPrecioModel>> obtenerTodas() async {
    try {
      final response = await _dioClient.get(
        ApiConstants.configuracionesPrecios,
      );

      final list = response.data as List;
      return list
          .map((json) =>
              ConfiguracionPrecioModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('Error inesperado al obtener configuraciones: $e');
    }
  }

  /// Obtiene una configuración por ID
  ///
  /// GET /api/configuraciones-precio/:id
  Future<ConfiguracionPrecioModel> obtenerPorId(
    String configuracionId,
  ) async {
    try {
      final response = await _dioClient.get(
        '${ApiConstants.configuracionesPrecios}/$configuracionId',
      );

      return ConfiguracionPrecioModel.fromJson(
          response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('Error inesperado al obtener configuración: $e');
    }
  }

  /// Actualiza una configuración de precios
  ///
  /// PATCH /api/configuraciones-precio/:id
  Future<ConfiguracionPrecioModel> actualizar(
    String configuracionId,
    ConfiguracionPrecioDto dto,
  ) async {
    try {
      final response = await _dioClient.patch(
        '${ApiConstants.configuracionesPrecios}/$configuracionId',
        data: dto.toJson(),
      );

      return ConfiguracionPrecioModel.fromJson(
          response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('Error inesperado al actualizar configuración: $e');
    }
  }

  /// Elimina una configuración de precios
  ///
  /// DELETE /api/configuraciones-precio/:id
  Future<void> eliminar(String configuracionId) async {
    try {
      await _dioClient.delete(
        '${ApiConstants.configuracionesPrecios}/$configuracionId',
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('Error inesperado al eliminar configuración: $e');
    }
  }

  /// Maneja errores de Dio y los convierte en excepciones más específicas
  Exception _handleDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return Exception('Tiempo de espera agotado. Verifica tu conexión.');
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        final message = e.response?.data?['message'] ?? 'Error del servidor';
        return Exception('Error $statusCode: $message');
      case DioExceptionType.cancel:
        return Exception('Solicitud cancelada');
      case DioExceptionType.connectionError:
        return Exception(
            'Error de conexión. Verifica tu conexión a internet.');
      default:
        return Exception('Error inesperado: ${e.message}');
    }
  }
}

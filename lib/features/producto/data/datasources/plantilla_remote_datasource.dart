import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../models/atributo_plantilla_model.dart';

/// Data source remoto para operaciones de plantillas de atributos
@lazySingleton
class PlantillaRemoteDataSource {
  final DioClient _dioClient;

  PlantillaRemoteDataSource(this._dioClient);

  /// Crea una nueva plantilla de atributos
  ///
  /// POST /producto-atributo-plantillas
  Future<AtributoPlantillaModel> crearPlantilla(
    CreatePlantillaDto dto,
  ) async {
    try {
      final response = await _dioClient.post(
        ApiConstants.plantillasAtributos,
        data: dto.toJson(),
      );

      return AtributoPlantillaModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('Error inesperado al crear plantilla: $e');
    }
  }

  /// Obtiene todas las plantillas de atributos
  ///
  /// GET /producto-atributo-plantillas?categoriaId=xxx
  Future<List<AtributoPlantillaModel>> getPlantillas({
    String? categoriaId,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (categoriaId != null) {
        queryParams['categoriaId'] = categoriaId;
      }

      final response = await _dioClient.get(
        ApiConstants.plantillasAtributos,
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      final List<dynamic> data = response.data as List<dynamic>;
      return data
          .map((json) => AtributoPlantillaModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('Error inesperado al obtener plantillas: $e');
    }
  }

  /// Obtiene una plantilla por ID
  ///
  /// GET /producto-atributo-plantillas/:id
  Future<AtributoPlantillaModel> getPlantilla(String id) async {
    try {
      final response = await _dioClient.get(
        '${ApiConstants.plantillasAtributos}/$id',
      );

      return AtributoPlantillaModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('Error inesperado al obtener plantilla: $e');
    }
  }

  /// Actualiza una plantilla existente
  ///
  /// PATCH /producto-atributo-plantillas/:id
  Future<AtributoPlantillaModel> actualizarPlantilla(
    String id,
    UpdatePlantillaDto dto,
  ) async {
    try {
      final response = await _dioClient.patch(
        '${ApiConstants.plantillasAtributos}/$id',
        data: dto.toJson(),
      );

      return AtributoPlantillaModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('Error inesperado al actualizar plantilla: $e');
    }
  }

  /// Elimina una plantilla (soft delete)
  ///
  /// DELETE /producto-atributo-plantillas/:id
  Future<void> eliminarPlantilla(String id) async {
    try {
      await _dioClient.delete(
        '${ApiConstants.plantillasAtributos}/$id',
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('Error inesperado al eliminar plantilla: $e');
    }
  }

  /// Aplica una plantilla a un producto o variante
  ///
  /// POST /producto-atributo-plantillas/aplicar
  Future<Map<String, dynamic>> aplicarPlantilla(
    AplicarPlantillaDto dto,
  ) async {
    try {
      final response = await _dioClient.post(
        '${ApiConstants.plantillasAtributos}/aplicar',
        data: dto.toJson(),
      );

      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('Error inesperado al aplicar plantilla: $e');
    }
  }

  /// Obtiene información de límites del plan
  ///
  /// GET /producto-atributo-plantillas/limits-info
  Future<Map<String, dynamic>> getLimitsInfo() async {
    try {
      final response = await _dioClient.get(
        '${ApiConstants.plantillasAtributos}/limits-info',
      );

      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('Error inesperado al obtener información de límites: $e');
    }
  }

  /// Maneja errores de Dio y los convierte en excepciones más específicas
  Exception _handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return Exception('Tiempo de espera agotado. Verifica tu conexión.');

      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        final message = error.response?.data?['message'] as String? ??
            error.response?.data?['error'] as String? ??
            'Error del servidor';

        if (statusCode == 400) {
          return Exception('Solicitud inválida: $message');
        } else if (statusCode == 401) {
          return Exception('No autorizado: $message');
        } else if (statusCode == 403) {
          return Exception('Acceso denegado: $message');
        } else if (statusCode == 404) {
          return Exception('Recurso no encontrado: $message');
        } else if (statusCode == 409) {
          return Exception('Conflicto: $message');
        } else if (statusCode != null && statusCode >= 500) {
          return Exception('Error del servidor: $message');
        }
        return Exception(message);

      case DioExceptionType.cancel:
        return Exception('Solicitud cancelada');

      case DioExceptionType.unknown:
        if (error.error.toString().contains('SocketException')) {
          return Exception('Sin conexión a internet');
        }
        return Exception('Error de conexión: ${error.message}');

      default:
        return Exception('Error inesperado: ${error.message}');
    }
  }
}

import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../models/precio_nivel_model.dart';

/// Data source remoto para operaciones de precios por nivel
@lazySingleton
class PrecioNivelRemoteDataSource {
  final DioClient _dioClient;

  PrecioNivelRemoteDataSource(this._dioClient);

  /// Crea un nivel de precio para un producto
  ///
  /// POST /api/productos/:productoId/precios-nivel
  Future<PrecioNivelModel> crearPrecioNivelProducto({
    required String productoId,
    required PrecioNivelDto dto,
  }) async {
    try {
      final response = await _dioClient.post(
        '${ApiConstants.productos}/$productoId/precios-nivel',
        data: dto.toJson(),
      );

      return PrecioNivelModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('Error inesperado al crear nivel de precio: $e');
    }
  }

  /// Crea un nivel de precio para una variante
  ///
  /// POST /api/productos/variantes/:varianteId/precios-nivel
  Future<PrecioNivelModel> crearPrecioNivelVariante({
    required String varianteId,
    required PrecioNivelDto dto,
  }) async {
    try {
      final response = await _dioClient.post(
        '${ApiConstants.productos}/variantes/$varianteId/precios-nivel',
        data: dto.toJson(),
      );

      return PrecioNivelModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('Error inesperado al crear nivel de precio: $e');
    }
  }

  /// Obtiene todos los niveles de precio de un producto
  ///
  /// GET /api/productos/:productoId/precios-nivel
  Future<List<PrecioNivelModel>> getPreciosNivelProducto({
    required String productoId,
  }) async {
    try {
      final response = await _dioClient.get(
        '${ApiConstants.productos}/$productoId/precios-nivel',
      );

      final list = response.data as List;
      return list
          .map((json) => PrecioNivelModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception(
          'Error inesperado al obtener niveles de precio del producto: $e');
    }
  }

  /// Obtiene todos los niveles de precio de una variante
  ///
  /// GET /api/productos/variantes/:varianteId/precios-nivel
  Future<List<PrecioNivelModel>> getPreciosNivelVariante({
    required String varianteId,
  }) async {
    try {
      final response = await _dioClient.get(
        '${ApiConstants.productos}/variantes/$varianteId/precios-nivel',
      );

      final list = response.data as List;
      return list
          .map((json) => PrecioNivelModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception(
          'Error inesperado al obtener niveles de precio de la variante: $e');
    }
  }

  /// Obtiene un nivel de precio por ID
  ///
  /// GET /api/productos/precios-nivel/:nivelId
  Future<PrecioNivelModel> getPrecioNivel({
    required String nivelId,
  }) async {
    try {
      final response = await _dioClient.get(
        '${ApiConstants.productos}/precios-nivel/$nivelId',
      );

      return PrecioNivelModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('Error inesperado al obtener nivel de precio: $e');
    }
  }

  /// Actualiza un nivel de precio
  ///
  /// PATCH /api/productos/precios-nivel/:nivelId
  Future<PrecioNivelModel> actualizarPrecioNivel({
    required String nivelId,
    required Map<String, dynamic> data,
  }) async {
    try {
      final response = await _dioClient.patch(
        '${ApiConstants.productos}/precios-nivel/$nivelId',
        data: data,
      );

      return PrecioNivelModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('Error inesperado al actualizar nivel de precio: $e');
    }
  }

  /// Elimina un nivel de precio
  ///
  /// DELETE /api/productos/precios-nivel/:nivelId
  Future<void> eliminarPrecioNivel({
    required String nivelId,
  }) async {
    try {
      await _dioClient.delete(
        '${ApiConstants.productos}/precios-nivel/$nivelId',
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('Error inesperado al eliminar nivel de precio: $e');
    }
  }

  /// Calcula el precio según la cantidad para un producto
  ///
  /// GET /api/productos/:productoId/calcular-precio?cantidad=X
  Future<CalculoPrecioResultModel> calcularPrecioProducto({
    required String productoId,
    required int cantidad,
  }) async {
    try {
      final response = await _dioClient.get(
        '${ApiConstants.productos}/$productoId/calcular-precio',
        queryParameters: {'cantidad': cantidad},
      );

      return CalculoPrecioResultModel.fromJson(
          response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('Error inesperado al calcular precio: $e');
    }
  }

  /// Calcula el precio según la cantidad para una variante
  ///
  /// GET /api/productos/variantes/:varianteId/calcular-precio?cantidad=X
  Future<CalculoPrecioResultModel> calcularPrecioVariante({
    required String varianteId,
    required int cantidad,
  }) async {
    try {
      final response = await _dioClient.get(
        '${ApiConstants.productos}/variantes/$varianteId/calcular-precio',
        queryParameters: {'cantidad': cantidad},
      );

      return CalculoPrecioResultModel.fromJson(
          response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('Error inesperado al calcular precio: $e');
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

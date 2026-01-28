import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/network/dio_client.dart';
import '../models/transferencia_stock_model.dart';
import '../../domain/entities/transferencia_stock.dart';

/// Data source remoto para operaciones de TransferenciaStock
@lazySingleton
class TransferenciaStockRemoteDataSource {
  final DioClient _dioClient;

  TransferenciaStockRemoteDataSource(this._dioClient);

  /// Crear transferencia de stock
  ///
  /// POST /api/transferencias-stock
  Future<TransferenciaStockModel> crearTransferencia({
    required String empresaId,
    required String sedeOrigenId,
    required String sedeDestinoId,
    String? productoId,
    String? varianteId,
    required int cantidad,
    String? motivo,
    String? observaciones,
  }) async {
    try {
      final response = await _dioClient.post(
        '/transferencias-stock',
        data: {
          'sedeOrigenId': sedeOrigenId,
          'sedeDestinoId': sedeDestinoId,
          if (productoId != null) 'productoId': productoId,
          if (varianteId != null) 'varianteId': varianteId,
          'cantidad': cantidad,
          if (motivo != null) 'motivo': motivo,
          if (observaciones != null) 'observaciones': observaciones,
        },
      );

      return TransferenciaStockModel.fromJson(
          response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('Error inesperado al crear transferencia: $e');
    }
  }

  /// Crear múltiples transferencias de stock
  ///
  /// POST /api/transferencias-stock/multiples
  Future<Map<String, dynamic>> crearTransferenciasMultiples({
    required String empresaId,
    required String sedeOrigenId,
    required String sedeDestinoId,
    required List<Map<String, dynamic>> productos,
    String? motivoGeneral,
    String? observaciones,
  }) async {
    try {
      final response = await _dioClient.post(
        '/transferencias-stock/multiples',
        data: {
          'sedeOrigenId': sedeOrigenId,
          'sedeDestinoId': sedeDestinoId,
          'productos': productos,
          if (motivoGeneral != null) 'motivoGeneral': motivoGeneral,
          if (observaciones != null) 'observaciones': observaciones,
        },
      );

      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('Error inesperado al crear transferencias múltiples: $e');
    }
  }

  /// Lista transferencias con filtros opcionales
  ///
  /// GET /api/transferencias-stock
  Future<Map<String, dynamic>> listarTransferencias({
    required String empresaId,
    String? sedeId,
    EstadoTransferencia? estado,
    int page = 1,
    int limit = 50,
  }) async {
    try {
      final response = await _dioClient.get(
        '/transferencias-stock',
        queryParameters: {
          if (sedeId != null) 'sedeId': sedeId,
          if (estado != null) 'estado': estado.value,
          'page': page,
          'limit': limit,
        },
      );

      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('Error inesperado al obtener transferencias: $e');
    }
  }

  /// Obtiene el detalle de una transferencia
  ///
  /// GET /api/transferencias-stock/:id
  Future<TransferenciaStockModel> obtenerTransferencia({
    required String transferenciaId,
    required String empresaId,
  }) async {
    try {
      final response = await _dioClient.get(
        '/transferencias-stock/$transferenciaId',
      );

      return TransferenciaStockModel.fromJson(
          response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('Error inesperado al obtener transferencia: $e');
    }
  }

  /// Aprobar transferencia
  ///
  /// PUT /api/transferencias-stock/:id/aprobar
  Future<TransferenciaStockModel> aprobarTransferencia({
    required String transferenciaId,
    required String empresaId,
    String? observaciones,
  }) async {
    try {
      final response = await _dioClient.put(
        '/transferencias-stock/$transferenciaId/aprobar',
        data: {
          if (observaciones != null) 'observaciones': observaciones,
        },
      );

      return TransferenciaStockModel.fromJson(
          response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('Error inesperado al aprobar transferencia: $e');
    }
  }

  /// Enviar transferencia (marcar en tránsito)
  ///
  /// PUT /api/transferencias-stock/:id/enviar
  Future<TransferenciaStockModel> enviarTransferencia({
    required String transferenciaId,
    required String empresaId,
  }) async {
    try {
      final response = await _dioClient.put(
        '/transferencias-stock/$transferenciaId/enviar',
      );

      return TransferenciaStockModel.fromJson(
          response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('Error inesperado al enviar transferencia: $e');
    }
  }

  /// Recibir transferencia
  ///
  /// PUT /api/transferencias-stock/:id/recibir
  Future<TransferenciaStockModel> recibirTransferencia({
    required String transferenciaId,
    required String empresaId,
    required int cantidadRecibida,
    String? ubicacion,
    String? observaciones,
  }) async {
    try {
      final response = await _dioClient.put(
        '/transferencias-stock/$transferenciaId/recibir',
        data: {
          'cantidadRecibida': cantidadRecibida,
          if (ubicacion != null) 'ubicacion': ubicacion,
          if (observaciones != null) 'observaciones': observaciones,
        },
      );

      return TransferenciaStockModel.fromJson(
          response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('Error inesperado al recibir transferencia: $e');
    }
  }

  /// Rechazar transferencia
  ///
  /// PUT /api/transferencias-stock/:id/rechazar
  Future<TransferenciaStockModel> rechazarTransferencia({
    required String transferenciaId,
    required String empresaId,
    required String motivo,
  }) async {
    try {
      final response = await _dioClient.put(
        '/transferencias-stock/$transferenciaId/rechazar',
        data: {'motivo': motivo},
      );

      return TransferenciaStockModel.fromJson(
          response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('Error inesperado al rechazar transferencia: $e');
    }
  }

  /// Cancelar transferencia
  ///
  /// PUT /api/transferencias-stock/:id/cancelar
  Future<TransferenciaStockModel> cancelarTransferencia({
    required String transferenciaId,
    required String empresaId,
    required String motivo,
  }) async {
    try {
      final response = await _dioClient.put(
        '/transferencias-stock/$transferenciaId/cancelar',
        data: {'motivo': motivo},
      );

      return TransferenciaStockModel.fromJson(
          response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('Error inesperado al cancelar transferencia: $e');
    }
  }

  /// Procesar completamente transferencia (aprobar + enviar + recibir)
  ///
  /// PUT /api/transferencias-stock/:id/procesar-completo
  Future<TransferenciaStockModel> procesarCompletoTransferencia({
    required String transferenciaId,
    required String empresaId,
    String? ubicacion,
    String? observaciones,
  }) async {
    try {
      final response = await _dioClient.put(
        '/transferencias-stock/$transferenciaId/procesar-completo',
        data: {
          if (ubicacion != null) 'ubicacion': ubicacion,
          if (observaciones != null) 'observaciones': observaciones,
        },
      );

      return TransferenciaStockModel.fromJson(
          response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception(
          'Error inesperado al procesar completamente la transferencia: $e');
    }
  }

  /// Crear incidencia posterior a la recepción
  ///
  /// POST /api/transferencias-stock/:id/crear-incidencia
  Future<Map<String, dynamic>> crearIncidenciaPosterior({
    required String transferenciaId,
    required String empresaId,
    required String itemId,
    required String tipo,
    required int cantidadAfectada,
    String? descripcion,
    List<String>? evidenciasUrls,
    String? observaciones,
  }) async {
    try {
      final response = await _dioClient.post(
        '/transferencias-stock/$transferenciaId/crear-incidencia',
        data: {
          'itemId': itemId,
          'tipo': tipo,
          'cantidadAfectada': cantidadAfectada,
          if (descripcion != null) 'descripcion': descripcion,
          if (evidenciasUrls != null && evidenciasUrls.isNotEmpty)
            'evidenciasUrls': evidenciasUrls,
          if (observaciones != null) 'observaciones': observaciones,
        },
      );

      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('Error inesperado al crear incidencia posterior: $e');
    }
  }

  /// Manejo de errores de Dio
  Exception _handleDioError(DioException error) {
    String message = 'Error en la operación de transferencia';

    if (error.response != null) {
      final data = error.response!.data;
      if (data is Map<String, dynamic> && data.containsKey('message')) {
        message = data['message'] as String;
      } else if (data is String) {
        message = data;
      }

      switch (error.response!.statusCode) {
        case 400:
          return Exception('Solicitud inválida: $message');
        case 401:
          return Exception('No autorizado: $message');
        case 403:
          return Exception('Acceso denegado: $message');
        case 404:
          return Exception('Transferencia no encontrada: $message');
        case 409:
          return Exception('Conflicto: $message');
        case 500:
          return Exception('Error del servidor: $message');
        default:
          return Exception('Error: $message');
      }
    }

    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      return Exception('Tiempo de espera agotado');
    }

    if (error.type == DioExceptionType.connectionError) {
      return Exception('Error de conexión. Verifica tu conexión a internet');
    }

    return Exception(message);
  }
}

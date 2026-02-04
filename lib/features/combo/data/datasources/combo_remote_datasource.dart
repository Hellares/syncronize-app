import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../models/combo_model.dart';
import '../models/componente_combo_model.dart';
import '../models/create_combo_dto.dart';

/// Data source remoto para operaciones de combos
@lazySingleton
class ComboRemoteDataSource {
  final DioClient _dioClient;

  ComboRemoteDataSource(this._dioClient);

  /// Crea un nuevo combo directamente
  ///
  /// POST /api/combos
  Future<ComboModel> createCombo({
    required CreateComboDto dto,
  }) async {
    try {
      final response = await _dioClient.post(
        ApiConstants.combos,
        data: dto.toJson(),
      );

      return ComboModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('Error inesperado al crear combo: $e');
    }
  }

  /// Obtiene todos los combos de una empresa con información completa
  ///
  /// GET /api/combos (incluye componentes, stock y precio calculado)
  Future<List<ComboModel>> getCombos({required String sedeId}) async {
    try {
      final response = await _dioClient.get(
        ApiConstants.combos,
        queryParameters: {'sedeId': sedeId},
      );

      // El backend devuelve un array de combos completos
      final List<dynamic> combos = response.data as List<dynamic>;

      return combos
          .map((json) => ComboModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('Error inesperado al obtener combos: $e');
    }
  }

  /// Obtiene información completa de un combo
  ///
  /// GET /api/combos/:id/combo-completo
  Future<ComboModel> getComboCompleto({
    required String comboId,
    required String sedeId,
  }) async {
    try {
      final response = await _dioClient.get(
        '${ApiConstants.combos}/$comboId/combo-completo',
        queryParameters: {'sedeId': sedeId},
      );

      return ComboModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('Error inesperado al obtener combo: $e');
    }
  }

  /// Agrega un componente a un combo
  ///
  /// POST /api/combos/:id/componentes
  Future<ComponenteComboModel> agregarComponente({
    required String comboId,
    required String sedeId,
    required Map<String, dynamic> data,
  }) async {
    try {
      final response = await _dioClient.post(
        '${ApiConstants.combos}/$comboId/componentes',
        data: data,
        queryParameters: {'sedeId': sedeId},
      );

      return ComponenteComboModel.fromJson(
          response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('Error inesperado al agregar componente: $e');
    }
  }

  /// Agrega múltiples componentes a un combo en batch
  ///
  /// POST /api/combos/:id/componentes/batch
  Future<List<ComponenteComboModel>> agregarComponentesBatch({
    required String comboId,
    required String sedeId,
    required List<Map<String, dynamic>> componentes,
  }) async {
    try {
      final response = await _dioClient.post(
        '${ApiConstants.combos}/$comboId/componentes/batch',
        data: {'componentes': componentes},
        queryParameters: {'sedeId': sedeId},
      );

      final List<dynamic> data = response.data as List<dynamic>;
      return data
          .map((e) =>
              ComponenteComboModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('Error inesperado al agregar componentes en batch: $e');
    }
  }

  /// Obtiene todos los componentes de un combo
  ///
  /// GET /api/combos/:id/componentes
  Future<List<ComponenteComboModel>> getComponentes({
    required String comboId,
    required String sedeId,
  }) async {
    try {
      final response = await _dioClient.get(
        '${ApiConstants.combos}/$comboId/componentes',
        queryParameters: {'sedeId': sedeId},
      );

      final List<dynamic> data = response.data as List<dynamic>;
      return data
          .map((e) =>
              ComponenteComboModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('Error inesperado al obtener componentes: $e');
    }
  }

  /// Actualiza un componente del combo
  ///
  /// PUT /api/combos/componentes/:id
  Future<ComponenteComboModel> actualizarComponente({
    required String componenteId,
    required String sedeId,
    required Map<String, dynamic> data,
  }) async {
    try {
      final response = await _dioClient.put(
        '${ApiConstants.combos}/componentes/$componenteId',
        data: data,
        queryParameters: {'sedeId': sedeId},
      );

      return ComponenteComboModel.fromJson(
          response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('Error inesperado al actualizar componente: $e');
    }
  }

  /// Elimina un componente del combo
  ///
  /// DELETE /api/combos/componentes/:id
  Future<void> eliminarComponente({
    required String componenteId,
  }) async {
    try {
      await _dioClient.delete(
        '${ApiConstants.combos}/componentes/$componenteId',
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('Error inesperado al eliminar componente: $e');
    }
  }

  /// Obtiene el stock disponible de un combo
  ///
  /// GET /api/combos/:id/stock-disponible-combo
  Future<int> getStockDisponible({
    required String comboId,
    required String sedeId,
  }) async {
    try {
      final response = await _dioClient.get(
        '${ApiConstants.combos}/$comboId/stock-disponible-combo',
        queryParameters: {'sedeId': sedeId},
      );

      final data = response.data as Map<String, dynamic>;
      return data['stockDisponible'] as int? ?? 0;
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('Error inesperado al obtener stock: $e');
    }
  }

  /// Calcula el precio del combo
  ///
  /// GET /api/combos/:id/precio-calculado-combo
  Future<double> getPrecioCalculado({
    required String comboId,
    required String sedeId,
  }) async {
    try {
      final response = await _dioClient.get(
        '${ApiConstants.combos}/$comboId/precio-calculado-combo',
        queryParameters: {'sedeId': sedeId},
      );

      final data = response.data as Map<String, dynamic>;
      return (data['precioCalculado'] as num?)?.toDouble() ?? 0;
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('Error inesperado al calcular precio: $e');
    }
  }

  /// Valida si el combo tiene stock suficiente
  ///
  /// GET /api/combos/:id/validar-stock-combo/:cantidad
  Future<bool> validarStock({
    required String comboId,
    required int cantidad,
    required String sedeId,
  }) async {
    try {
      final response = await _dioClient.get(
        '${ApiConstants.combos}/$comboId/validar-stock-combo/$cantidad',
        queryParameters: {'sedeId': sedeId},
      );

      final data = response.data as Map<String, dynamic>;
      return data['tieneStock'] as bool? ?? false;
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('Error inesperado al validar stock: $e');
    }
  }

  /// Obtiene la reservación actual de un combo en una sede
  ///
  /// GET /api/combos/:id/reservacion
  Future<int> getReservacion({
    required String comboId,
    required String sedeId,
  }) async {
    try {
      final response = await _dioClient.get(
        '${ApiConstants.combos}/$comboId/reservacion',
        queryParameters: {'sedeId': sedeId},
      );

      final data = response.data as Map<String, dynamic>;
      return data['cantidad'] as int? ?? 0;
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('Error inesperado al obtener reservación: $e');
    }
  }

  /// Reserva stock para un combo (crear/actualizar reservación)
  ///
  /// POST /api/combos/:id/reservar-stock
  Future<int> reservarStock({
    required String comboId,
    required String sedeId,
    required int cantidad,
  }) async {
    try {
      final response = await _dioClient.post(
        '${ApiConstants.combos}/$comboId/reservar-stock',
        data: {'cantidad': cantidad},
        queryParameters: {'sedeId': sedeId},
      );

      final data = response.data as Map<String, dynamic>;
      return data['cantidad'] as int? ?? 0;
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('Error inesperado al reservar stock: $e');
    }
  }

  /// Libera toda la reservación de un combo en una sede
  ///
  /// DELETE /api/combos/:id/reservar-stock
  Future<void> liberarReserva({
    required String comboId,
    required String sedeId,
  }) async {
    try {
      await _dioClient.delete(
        '${ApiConstants.combos}/$comboId/reservar-stock',
        queryParameters: {'sedeId': sedeId},
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('Error inesperado al liberar reservación: $e');
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
          return Exception('No tienes permisos para esta operación');
        case 404:
          return Exception('Combo o componente no encontrado');
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

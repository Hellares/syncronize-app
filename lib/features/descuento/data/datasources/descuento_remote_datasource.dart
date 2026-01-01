import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../models/politica_descuento_model.dart';
import '../models/usuario_descuento_model.dart';
import '../models/descuento_calculado_model.dart';

/// Data source remoto para operaciones de políticas de descuento
@lazySingleton
class DescuentoRemoteDataSource {
  final DioClient _dioClient;

  DescuentoRemoteDataSource(this._dioClient);

  /// Obtiene lista de políticas de descuento con filtros y paginación
  ///
  /// GET /api/politicas-descuento?page=1&limit=20&...
  Future<Map<String, dynamic>> getPoliticasDescuento({
    String? tipoDescuento,
    bool? isActive,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final queryParams = {
        'page': page.toString(),
        'limit': limit.toString(),
        if (tipoDescuento != null) 'tipoDescuento': tipoDescuento,
        if (isActive != null) 'isActive': isActive.toString(),
      };

      final response = await _dioClient.get(
        ApiConstants.politicasDescuento,
        queryParameters: queryParams,
      );

      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('Error inesperado al obtener políticas: $e');
    }
  }

  /// Obtiene una política por ID
  ///
  /// GET /api/politicas-descuento/:id
  Future<PoliticaDescuentoModel> getPoliticaById(String id) async {
    try {
      final response = await _dioClient.get(
        '${ApiConstants.politicasDescuento}/$id',
      );

      return PoliticaDescuentoModel.fromJson(
          response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('Error inesperado al obtener política: $e');
    }
  }

  /// Crea una nueva política de descuento
  ///
  /// POST /api/politicas-descuento
  Future<PoliticaDescuentoModel> createPolitica(
      Map<String, dynamic> politica) async {
    try {
      final response = await _dioClient.post(
        ApiConstants.politicasDescuento,
        data: politica,
      );

      return PoliticaDescuentoModel.fromJson(
          response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('Error inesperado al crear política: $e');
    }
  }

  /// Actualiza una política de descuento existente
  ///
  /// PUT /api/politicas-descuento/:id
  Future<PoliticaDescuentoModel> updatePolitica(
    String id,
    Map<String, dynamic> politica,
  ) async {
    try {
      final response = await _dioClient.put(
        '${ApiConstants.politicasDescuento}/$id',
        data: politica,
      );

      return PoliticaDescuentoModel.fromJson(
          response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('Error inesperado al actualizar política: $e');
    }
  }

  /// Elimina una política de descuento
  ///
  /// DELETE /api/politicas-descuento/:id
  Future<void> deletePolitica(String id) async {
    try {
      await _dioClient.delete(
        '${ApiConstants.politicasDescuento}/$id',
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('Error inesperado al eliminar política: $e');
    }
  }

  /// Asigna usuarios a una política de descuento
  ///
  /// POST /api/politicas-descuento/:politicaId/usuarios
  Future<List<UsuarioDescuentoModel>> asignarUsuarios(
    String politicaId,
    List<String> usuariosIds, {
    int? limiteMensualUsos,
  }) async {
    try {
      final response = await _dioClient.post(
        '${ApiConstants.politicasDescuento}/$politicaId/usuarios',
        data: {
          'usuariosIds': usuariosIds,
          if (limiteMensualUsos != null) 'limiteMensualUsos': limiteMensualUsos,
        },
      );

      final List<dynamic> data = response.data as List<dynamic>;
      return data
          .map((json) =>
              UsuarioDescuentoModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('Error inesperado al asignar usuarios: $e');
    }
  }

  /// Obtiene los IDs de usuarios asignados a una política
  ///
  /// GET /api/politicas-descuento/:id/usuarios-asignados
  Future<List<String>> obtenerUsuariosAsignados(String politicaId) async {
    try {
      final response = await _dioClient.get(
        '${ApiConstants.politicasDescuento}/$politicaId/usuarios-asignados',
      );

      final List<dynamic> data = response.data as List<dynamic>;
      return data
          .map((item) => (item as Map<String, dynamic>)['usuarioId'] as String)
          .toList();
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('Error inesperado al obtener usuarios asignados: $e');
    }
  }

  /// Remueve un usuario de una política
  ///
  /// DELETE /api/politicas-descuento/:politicaId/usuarios/:usuarioId
  Future<void> removerUsuario(String politicaId, String usuarioId) async {
    try {
      await _dioClient.delete(
        '${ApiConstants.politicasDescuento}/$politicaId/usuarios/$usuarioId',
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('Error inesperado al remover usuario: $e');
    }
  }

  /// Agrega un familiar a un trabajador
  ///
  /// POST /api/politicas-descuento/trabajadores/:trabajadorId/familiares
  Future<UsuarioDescuentoModel> agregarFamiliar(
    String trabajadorId,
    Map<String, dynamic> familiar,
  ) async {
    try {
      final response = await _dioClient.post(
        '${ApiConstants.politicasDescuento}/trabajadores/$trabajadorId/familiares',
        data: familiar,
      );

      return UsuarioDescuentoModel.fromJson(
          response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('Error inesperado al agregar familiar: $e');
    }
  }

  /// Obtiene la lista de familiares de un trabajador
  ///
  /// GET /api/politicas-descuento/trabajadores/:trabajadorId/familiares
  Future<List<UsuarioDescuentoModel>> obtenerFamiliares(
      String trabajadorId) async {
    try {
      final response = await _dioClient.get(
        '${ApiConstants.politicasDescuento}/trabajadores/$trabajadorId/familiares',
      );

      final List<dynamic> data = response.data as List<dynamic>;
      return data
          .map((json) =>
              UsuarioDescuentoModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('Error inesperado al obtener familiares: $e');
    }
  }

  /// Remueve un familiar de un trabajador
  ///
  /// DELETE /api/politicas-descuento/trabajadores/:trabajadorId/familiares/:familiarId
  Future<void> removerFamiliar(String trabajadorId, String familiarId) async {
    try {
      await _dioClient.delete(
        '${ApiConstants.politicasDescuento}/trabajadores/$trabajadorId/familiares/$familiarId',
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('Error inesperado al remover familiar: $e');
    }
  }

  /// Asigna productos a una política de descuento
  ///
  /// POST /api/politicas-descuento/:politicaId/productos
  Future<List<Map<String, dynamic>>> asignarProductos(
    String politicaId,
    List<Map<String, dynamic>> productos,
  ) async {
    try {
      final response = await _dioClient.post(
        '${ApiConstants.politicasDescuento}/$politicaId/productos',
        data: {'productos': productos},
      );

      final List<dynamic> data = response.data as List<dynamic>;
      return data.map((e) => e as Map<String, dynamic>).toList();
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('Error inesperado al asignar productos: $e');
    }
  }

  /// Asigna categorías a una política de descuento
  ///
  /// POST /api/politicas-descuento/:politicaId/categorias
  Future<List<Map<String, dynamic>>> asignarCategorias(
    String politicaId,
    List<Map<String, dynamic>> categorias,
  ) async {
    try {
      final response = await _dioClient.post(
        '${ApiConstants.politicasDescuento}/$politicaId/categorias',
        data: {'categorias': categorias},
      );

      final List<dynamic> data = response.data as List<dynamic>;
      return data.map((e) => e as Map<String, dynamic>).toList();
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('Error inesperado al asignar categorías: $e');
    }
  }

  /// Calcula el descuento aplicable para un usuario y producto
  ///
  /// POST /api/politicas-descuento/calcular-descuento
  Future<DescuentoCalculadoModel> calcularDescuento({
    required String usuarioId,
    required String productoId,
    String? varianteId,
    required int cantidad,
    required double precioBase,
  }) async {
    try {
      final response = await _dioClient.post(
        '${ApiConstants.politicasDescuento}/calcular-descuento',
        data: {
          'usuarioId': usuarioId,
          'productoId': productoId,
          if (varianteId != null) 'varianteId': varianteId,
          'cantidad': cantidad,
          'precioBase': precioBase,
        },
      );

      return DescuentoCalculadoModel.fromJson(
          response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('Error inesperado al calcular descuento: $e');
    }
  }

  /// Obtiene el historial de uso de una política
  ///
  /// GET /api/politicas-descuento/:politicaId/historial-uso
  Future<List<Map<String, dynamic>>> obtenerHistorialUso(
      String politicaId) async {
    try {
      final response = await _dioClient.get(
        '${ApiConstants.politicasDescuento}/$politicaId/historial-uso',
      );

      final List<dynamic> data = response.data as List<dynamic>;
      return data.map((e) => e as Map<String, dynamic>).toList();
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('Error inesperado al obtener historial: $e');
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
          return Exception(message); // Usar el mensaje del servidor que indica el permiso faltante
        case 404:
          return Exception('Política de descuento no encontrada');
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

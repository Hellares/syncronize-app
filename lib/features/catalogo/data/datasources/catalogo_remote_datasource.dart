import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../models/categoria_maestra_model.dart';
import '../models/marca_maestra_model.dart';
import '../models/empresa_categoria_model.dart';
import '../models/empresa_marca_model.dart';

/// Data source remoto para operaciones de catálogos
@lazySingleton
class CatalogoRemoteDataSource {
  final DioClient _dioClient;

  CatalogoRemoteDataSource(this._dioClient);

  // ============================================
  // CATEGORÍAS MAESTRAS
  // ============================================

  /// Obtiene el catálogo global de categorías maestras
  ///
  /// GET /api/catalogos/categorias-maestras
  Future<List<CategoriaMaestraModel>> getCategoriasMaestras({
    bool incluirHijos = false,
    bool soloPopulares = false,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (incluirHijos) queryParams['incluirHijos'] = 'true';
      if (soloPopulares) queryParams['soloPopulares'] = 'true';

      final response = await _dioClient.get(
        '${ApiConstants.catalogos}/categorias-maestras',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      if (response.data is! List) {
        throw Exception('Respuesta inválida del servidor');
      }

      return (response.data as List)
          .map((json) =>
              CategoriaMaestraModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('Error inesperado al obtener categorías maestras: $e');
    }
  }

  // ============================================
  // MARCAS MAESTRAS
  // ============================================

  /// Obtiene el catálogo global de marcas maestras
  ///
  /// GET /api/catalogos/marcas-maestras
  Future<List<MarcaMaestraModel>> getMarcasMaestras({
    bool soloPopulares = false,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (soloPopulares) queryParams['soloPopulares'] = 'true';

      final response = await _dioClient.get(
        '${ApiConstants.catalogos}/marcas-maestras',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      if (response.data is! List) {
        throw Exception('Respuesta inválida del servidor');
      }

      return (response.data as List)
          .map((json) =>
              MarcaMaestraModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('Error inesperado al obtener marcas maestras: $e');
    }
  }

  // ============================================
  // CATEGORÍAS POR EMPRESA
  // ============================================

  /// Obtiene las categorías activas de una empresa
  ///
  /// GET /api/catalogos/categorias/empresa/:empresaId
  Future<List<EmpresaCategoriaModel>> getCategoriasEmpresa(
      String empresaId) async {
    try {
      final response = await _dioClient.get(
        '${ApiConstants.catalogos}/categorias/empresa/$empresaId',
      );

      if (response.data is! List) {
        throw Exception('Respuesta inválida del servidor');
      }

      return (response.data as List)
          .map((json) =>
              EmpresaCategoriaModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('Error inesperado al obtener categorías de empresa: $e');
    }
  }

  /// Activa una categoría para una empresa
  ///
  /// POST /api/catalogos/categorias/activar
  Future<EmpresaCategoriaModel> activarCategoria(
      Map<String, dynamic> data) async {
    try {
      final response = await _dioClient.post(
        '${ApiConstants.catalogos}/categorias/activar',
        data: data,
      );

      return EmpresaCategoriaModel.fromJson(
          response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('Error inesperado al activar categoría: $e');
    }
  }

  /// Desactiva una categoría de una empresa
  ///
  /// DELETE /api/catalogos/categorias/empresa/:empresaId/:empresaCategoriaId
  Future<void> desactivarCategoria({
    required String empresaId,
    required String empresaCategoriaId,
  }) async {
    try {
      await _dioClient.delete(
        '${ApiConstants.catalogos}/categorias/empresa/$empresaId/$empresaCategoriaId',
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('Error inesperado al desactivar categoría: $e');
    }
  }

  /// Activa categorías populares para una empresa
  ///
  /// POST /api/catalogos/categorias/activar-populares
  Future<List<EmpresaCategoriaModel>> activarCategoriasPopulares(
      String empresaId) async {
    try {
      final response = await _dioClient.post(
        '${ApiConstants.catalogos}/categorias/activar-populares',
        data: {'empresaId': empresaId},
      );

      if (response.data is! List) {
        throw Exception('Respuesta inválida del servidor');
      }

      return (response.data as List)
          .map((json) =>
              EmpresaCategoriaModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('Error inesperado al activar categorías populares: $e');
    }
  }

  // ============================================
  // MARCAS POR EMPRESA
  // ============================================

  /// Obtiene las marcas activas de una empresa
  ///
  /// GET /api/catalogos/marcas/empresa/:empresaId
  Future<List<EmpresaMarcaModel>> getMarcasEmpresa(String empresaId) async {
    try {
      final response = await _dioClient.get(
        '${ApiConstants.catalogos}/marcas/empresa/$empresaId',
      );

      if (response.data is! List) {
        throw Exception('Respuesta inválida del servidor');
      }

      return (response.data as List)
          .map((json) =>
              EmpresaMarcaModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('Error inesperado al obtener marcas de empresa: $e');
    }
  }

  /// Activa una marca para una empresa
  ///
  /// POST /api/catalogos/marcas/activar
  Future<EmpresaMarcaModel> activarMarca(Map<String, dynamic> data) async {
    try {
      final response = await _dioClient.post(
        '${ApiConstants.catalogos}/marcas/activar',
        data: data,
      );

      return EmpresaMarcaModel.fromJson(
          response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('Error inesperado al activar marca: $e');
    }
  }

  /// Desactiva una marca de una empresa
  ///
  /// DELETE /api/catalogos/marcas/empresa/:empresaId/:empresaMarcaId
  Future<void> desactivarMarca({
    required String empresaId,
    required String empresaMarcaId,
  }) async {
    try {
      await _dioClient.delete(
        '${ApiConstants.catalogos}/marcas/empresa/$empresaId/$empresaMarcaId',
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('Error inesperado al desactivar marca: $e');
    }
  }

  /// Activa marcas populares para una empresa
  ///
  /// POST /api/catalogos/marcas/activar-populares
  Future<List<EmpresaMarcaModel>> activarMarcasPopulares(
      String empresaId) async {
    try {
      final response = await _dioClient.post(
        '${ApiConstants.catalogos}/marcas/activar-populares',
        data: {'empresaId': empresaId},
      );

      if (response.data is! List) {
        throw Exception('Respuesta inválida del servidor');
      }

      return (response.data as List)
          .map((json) =>
              EmpresaMarcaModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('Error inesperado al activar marcas populares: $e');
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
          return Exception('Recurso no encontrado');
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

import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/network/dio_client.dart';
import '../models/unidad_medida_model.dart';

/// Data source remoto para operaciones de unidades de medida
@lazySingleton
class UnidadMedidaRemoteDataSource {
  final DioClient _dioClient;

  UnidadMedidaRemoteDataSource(this._dioClient);

  /// Obtiene todas las unidades de medida maestras (catálogo SUNAT)
  ///
  /// GET /api/catalogos/unidades-maestras
  Future<List<UnidadMedidaMaestraModel>> getUnidadesMaestras({
    String? categoria,
    bool soloPopulares = false,
  }) async {
    try {
      final queryParameters = <String, dynamic>{};
      if (categoria != null) queryParameters['categoria'] = categoria;
      if (soloPopulares) queryParameters['soloPopulares'] = 'true';

      final response = await _dioClient.get(
        '/catalogos/unidades-maestras',
        queryParameters: queryParameters,
      );

      if (response.data is! List) {
        throw Exception('Respuesta inválida del servidor');
      }

      return (response.data as List)
          .map((json) => UnidadMedidaMaestraModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('Error inesperado al obtener unidades maestras: $e');
    }
  }

  /// Obtiene las unidades de medida activadas para una empresa
  ///
  /// GET /api/catalogos/unidades/empresa/:empresaId
  Future<List<EmpresaUnidadMedidaModel>> getUnidadesEmpresa(String empresaId) async {
    try {
      final response = await _dioClient.get(
        '/catalogos/unidades/empresa/$empresaId',
      );

      if (response.data is! List) {
        throw Exception('Respuesta inválida del servidor');
      }

      return (response.data as List)
          .map((json) => EmpresaUnidadMedidaModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('Error inesperado al obtener unidades de empresa: $e');
    }
  }

  /// Activa una unidad de medida para una empresa
  ///
  /// POST /api/catalogos/unidades/activar
  Future<EmpresaUnidadMedidaModel> activarUnidad({
    required String empresaId,
    String? unidadMaestraId,
    String? nombrePersonalizado,
    String? simboloPersonalizado,
    String? codigoPersonalizado,
    String? descripcion,
    String? nombreLocal,
    String? simboloLocal,
    int? orden,
  }) async {
    try {
      final data = <String, dynamic>{
        'empresaId': empresaId,
      };

      if (unidadMaestraId != null) data['unidadMaestraId'] = unidadMaestraId;
      if (nombrePersonalizado != null) data['nombrePersonalizado'] = nombrePersonalizado;
      if (simboloPersonalizado != null) data['simboloPersonalizado'] = simboloPersonalizado;
      if (codigoPersonalizado != null) data['codigoPersonalizado'] = codigoPersonalizado;
      if (descripcion != null) data['descripcion'] = descripcion;
      if (nombreLocal != null) data['nombreLocal'] = nombreLocal;
      if (simboloLocal != null) data['simboloLocal'] = simboloLocal;
      if (orden != null) data['orden'] = orden;

      final response = await _dioClient.post(
        '/catalogos/unidades/activar',
        data: data,
      );

      return EmpresaUnidadMedidaModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('Error inesperado al activar unidad: $e');
    }
  }

  /// Desactiva una unidad de medida de una empresa
  ///
  /// DELETE /api/catalogos/unidades/empresa/:empresaId/:unidadId
  Future<void> desactivarUnidad({
    required String empresaId,
    required String unidadId,
  }) async {
    try {
      await _dioClient.delete(
        '/catalogos/unidades/empresa/$empresaId/$unidadId',
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('Error inesperado al desactivar unidad: $e');
    }
  }

  /// Activa las unidades de medida populares para una empresa
  ///
  /// POST /api/catalogos/unidades/activar-populares
  Future<List<EmpresaUnidadMedidaModel>> activarUnidadesPopulares(String empresaId) async {
    try {
      final response = await _dioClient.post(
        '/catalogos/unidades/activar-populares',
        data: {'empresaId': empresaId},
      );

      // El backend devuelve un objeto con estructura { unidades: [...], total: N }
      final data = response.data as Map<String, dynamic>;
      final unidades = data['unidades'] as List;

      return unidades
          .map((json) => EmpresaUnidadMedidaModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('Error inesperado al activar unidades populares: $e');
    }
  }

  /// Maneja los errores de Dio y los convierte en excepciones más específicas
  Exception _handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return Exception('Tiempo de espera agotado. Verifica tu conexión a internet.');

      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        final message = error.response?.data?['message'] ??
                        error.response?.data?['error'] ??
                        'Error del servidor';

        if (statusCode == 400) {
          return Exception('Solicitud inválida: $message');
        } else if (statusCode == 401) {
          return Exception('No autorizado. Por favor inicia sesión nuevamente.');
        } else if (statusCode == 403) {
          return Exception('No tienes permisos para realizar esta acción.');
        } else if (statusCode == 404) {
          return Exception('Recurso no encontrado.');
        } else if (statusCode == 409) {
          return Exception('Conflicto: $message');
        } else if (statusCode != null && statusCode >= 500) {
          return Exception('Error del servidor. Intenta nuevamente más tarde.');
        }
        return Exception(message);

      case DioExceptionType.cancel:
        return Exception('Solicitud cancelada.');

      case DioExceptionType.connectionError:
        return Exception('Error de conexión. Verifica tu conexión a internet.');

      case DioExceptionType.badCertificate:
        return Exception('Error de certificado SSL.');

      case DioExceptionType.unknown:
      if (error.error != null) {
          return Exception('Error de red: ${error.error}');
        }
        return Exception('Error desconocido. Intenta nuevamente.');
    }
  }
}

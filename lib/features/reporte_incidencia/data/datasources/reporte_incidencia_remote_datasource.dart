import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/network/dio_client.dart';
import '../models/reporte_incidencia_model.dart';
import '../../domain/entities/reporte_incidencia.dart';

@lazySingleton
class ReporteIncidenciaRemoteDataSource {
  final DioClient _dioClient;

  ReporteIncidenciaRemoteDataSource(this._dioClient);

  Future<ReporteIncidenciaModel> crearReporte({
    required String sedeId,
    required String titulo,
    String? descripcionGeneral,
    required TipoReporteIncidencia tipoReporte,
    required DateTime fechaIncidente,
    String? supervisorId,
    String? observacionesFinales,
  }) async {
    try {
      final response = await _dioClient.post(
        '/reportes-incidencia',
        data: {
          'sedeId': sedeId,
          'titulo': titulo,
          'descripcionGeneral': descripcionGeneral,
          'tipoReporte': tipoReporte.value,
          'fechaIncidente': fechaIncidente.toIso8601String(),
          'supervisorId': supervisorId,
          'observacionesFinales': observacionesFinales,
        },
      );

      return ReporteIncidenciaModel.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<List<ReporteIncidenciaModel>> listarReportes({
    String? sedeId,
    EstadoReporteIncidencia? estado,
    TipoReporteIncidencia? tipoReporte,
    DateTime? fechaDesde,
    DateTime? fechaHasta,
  }) async {
    try {
      final queryParameters = <String, dynamic>{};

      if (sedeId != null) queryParameters['sedeId'] = sedeId;
      if (estado != null) queryParameters['estado'] = estado.value;
      if (tipoReporte != null) {
        queryParameters['tipoReporte'] = tipoReporte.value;
      }
      if (fechaDesde != null) {
        queryParameters['fechaDesde'] = fechaDesde.toIso8601String();
      }
      if (fechaHasta != null) {
        queryParameters['fechaHasta'] = fechaHasta.toIso8601String();
      }

      final response = await _dioClient.get(
        '/reportes-incidencia',
        queryParameters: queryParameters,
      );

      return (response.data as List)
          .map((json) => ReporteIncidenciaModel.fromJson(json))
          .toList();
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<ReporteIncidenciaModel> obtenerReporte(String reporteId) async {
    try {
      final response = await _dioClient.get('/reportes-incidencia/$reporteId');
      return ReporteIncidenciaModel.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<ReporteIncidenciaModel> actualizarReporte({
    required String reporteId,
    String? titulo,
    String? descripcionGeneral,
    TipoReporteIncidencia? tipoReporte,
    DateTime? fechaIncidente,
    String? supervisorId,
    String? observacionesFinales,
  }) async {
    try {
      final data = <String, dynamic>{};

      if (titulo != null) data['titulo'] = titulo;
      if (descripcionGeneral != null) {
        data['descripcionGeneral'] = descripcionGeneral;
      }
      if (tipoReporte != null) data['tipoReporte'] = tipoReporte.value;
      if (fechaIncidente != null) {
        data['fechaIncidente'] = fechaIncidente.toIso8601String();
      }
      if (supervisorId != null) data['supervisorId'] = supervisorId;
      if (observacionesFinales != null) {
        data['observacionesFinales'] = observacionesFinales;
      }

      final response = await _dioClient.put(
        '/reportes-incidencia/$reporteId',
        data: data,
      );

      return ReporteIncidenciaModel.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<ReporteIncidenciaItemModel> agregarItem({
    required String reporteId,
    required String productoStockId,
    required TipoIncidenciaProducto tipo,
    required int cantidadAfectada,
    required String descripcion,
    String? observaciones,
  }) async {
    try {
      final response = await _dioClient.post(
        '/reportes-incidencia/$reporteId/items',
        data: {
          'productoStockId': productoStockId,
          'tipo': tipo.value,
          'cantidadAfectada': cantidadAfectada,
          'descripcion': descripcion,
          'observaciones': observaciones,
        },
      );

      return ReporteIncidenciaItemModel.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<void> eliminarItem({
    required String reporteId,
    required String itemId,
  }) async {
    try {
      await _dioClient.delete('/reportes-incidencia/$reporteId/items/$itemId');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<ReporteIncidenciaModel> enviarParaRevision(String reporteId) async {
    try {
      final response =
          await _dioClient.post('/reportes-incidencia/$reporteId/enviar');
      return ReporteIncidenciaModel.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<ReporteIncidenciaModel> aprobarReporte(String reporteId) async {
    try {
      final response =
          await _dioClient.post('/reportes-incidencia/$reporteId/aprobar');
      return ReporteIncidenciaModel.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<ReporteIncidenciaModel> rechazarReporte(
    String reporteId,
    String? motivo,
  ) async {
    try {
      final response = await _dioClient.post(
        '/reportes-incidencia/$reporteId/rechazar',
        data: {
          'motivo': motivo,
        },
      );
      return ReporteIncidenciaModel.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<ReporteIncidenciaItemModel> resolverItem({
    required String reporteId,
    required String itemId,
    required AccionIncidenciaProducto accionTomada,
    String? observaciones,
    String? sedeDestinoId,
  }) async {
    try {
      final response = await _dioClient.post(
        '/reportes-incidencia/$reporteId/items/$itemId/resolver',
        data: {
          'accionTomada': accionTomada.value,
          'observaciones': observaciones,
          'sedeDestinoId': sedeDestinoId,
        },
      );

      return ReporteIncidenciaItemModel.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Exception _handleDioError(DioException e) {
    if (e.response != null) {
      final message = e.response?.data['message'] ??
          e.response?.data['error'] ??
          'Error del servidor';
      return Exception(message);
    } else if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return Exception('Tiempo de espera agotado');
    } else if (e.type == DioExceptionType.unknown) {
      return Exception('Sin conexión a internet');
    }
    return Exception('Error inesperado: ${e.message}');
  }
}

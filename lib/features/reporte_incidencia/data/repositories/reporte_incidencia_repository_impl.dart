import 'package:injectable/injectable.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/utils/resource.dart';
import '../../domain/entities/reporte_incidencia.dart';
import '../../domain/repositories/reporte_incidencia_repository.dart';
import '../datasources/reporte_incidencia_remote_datasource.dart';

@LazySingleton(as: ReporteIncidenciaRepository)
class ReporteIncidenciaRepositoryImpl implements ReporteIncidenciaRepository {
  final ReporteIncidenciaRemoteDataSource _remoteDataSource;
  final NetworkInfo _networkInfo;

  ReporteIncidenciaRepositoryImpl(
    this._remoteDataSource,
    this._networkInfo,
  );

  @override
  Future<Resource<ReporteIncidencia>> crearReporte({
    required String sedeId,
    required String titulo,
    String? descripcionGeneral,
    required TipoReporteIncidencia tipoReporte,
    required DateTime fechaIncidente,
    String? supervisorId,
    String? observacionesFinales,
  }) async {
    if (!await _networkInfo.isConnected) {
      return Error(
        'No hay conexión a internet',
        errorCode: 'NETWORK_ERROR',
      );
    }

    try {
      final reporte = await _remoteDataSource.crearReporte(
        sedeId: sedeId,
        titulo: titulo,
        descripcionGeneral: descripcionGeneral,
        tipoReporte: tipoReporte,
        fechaIncidente: fechaIncidente,
        supervisorId: supervisorId,
        observacionesFinales: observacionesFinales,
      );
      return Success(reporte);
    } catch (e) {
      return Error(
        _extractErrorMessage(e),
        errorCode: 'CREATE_REPORTE_ERROR',
      );
    }
  }

  @override
  Future<Resource<List<ReporteIncidencia>>> listarReportes({
    String? sedeId,
    EstadoReporteIncidencia? estado,
    TipoReporteIncidencia? tipoReporte,
    DateTime? fechaDesde,
    DateTime? fechaHasta,
  }) async {
    if (!await _networkInfo.isConnected) {
      return Error(
        'No hay conexión a internet',
        errorCode: 'NETWORK_ERROR',
      );
    }

    try {
      final reportes = await _remoteDataSource.listarReportes(
        sedeId: sedeId,
        estado: estado,
        tipoReporte: tipoReporte,
        fechaDesde: fechaDesde,
        fechaHasta: fechaHasta,
      );
      return Success(reportes);
    } catch (e) {
      return Error(
        _extractErrorMessage(e),
        errorCode: 'GET_REPORTES_ERROR',
      );
    }
  }

  @override
  Future<Resource<ReporteIncidencia>> obtenerReporte(String reporteId) async {
    if (!await _networkInfo.isConnected) {
      return Error(
        'No hay conexión a internet',
        errorCode: 'NETWORK_ERROR',
      );
    }

    try {
      final reporte = await _remoteDataSource.obtenerReporte(reporteId);
      return Success(reporte);
    } catch (e) {
      return Error(
        _extractErrorMessage(e),
        errorCode: 'GET_REPORTE_ERROR',
      );
    }
  }

  @override
  Future<Resource<ReporteIncidencia>> actualizarReporte({
    required String reporteId,
    String? titulo,
    String? descripcionGeneral,
    TipoReporteIncidencia? tipoReporte,
    DateTime? fechaIncidente,
    String? supervisorId,
    String? observacionesFinales,
  }) async {
    if (!await _networkInfo.isConnected) {
      return Error(
        'No hay conexión a internet',
        errorCode: 'NETWORK_ERROR',
      );
    }

    try {
      final reporte = await _remoteDataSource.actualizarReporte(
        reporteId: reporteId,
        titulo: titulo,
        descripcionGeneral: descripcionGeneral,
        tipoReporte: tipoReporte,
        fechaIncidente: fechaIncidente,
        supervisorId: supervisorId,
        observacionesFinales: observacionesFinales,
      );
      return Success(reporte);
    } catch (e) {
      return Error(
        _extractErrorMessage(e),
        errorCode: 'UPDATE_REPORTE_ERROR',
      );
    }
  }

  @override
  Future<Resource<ReporteIncidenciaItem>> agregarItem({
    required String reporteId,
    required String productoStockId,
    required TipoIncidenciaProducto tipo,
    required int cantidadAfectada,
    required String descripcion,
    String? observaciones,
  }) async {
    if (!await _networkInfo.isConnected) {
      return Error(
        'No hay conexión a internet',
        errorCode: 'NETWORK_ERROR',
      );
    }

    try {
      final item = await _remoteDataSource.agregarItem(
        reporteId: reporteId,
        productoStockId: productoStockId,
        tipo: tipo,
        cantidadAfectada: cantidadAfectada,
        descripcion: descripcion,
        observaciones: observaciones,
      );
      return Success(item);
    } catch (e) {
      return Error(
        _extractErrorMessage(e),
        errorCode: 'ADD_ITEM_ERROR',
      );
    }
  }

  @override
  Future<Resource<void>> eliminarItem({
    required String reporteId,
    required String itemId,
  }) async {
    if (!await _networkInfo.isConnected) {
      return Error(
        'No hay conexión a internet',
        errorCode: 'NETWORK_ERROR',
      );
    }

    try {
      await _remoteDataSource.eliminarItem(
        reporteId: reporteId,
        itemId: itemId,
      );
      return Success(null);
    } catch (e) {
      return Error(
        _extractErrorMessage(e),
        errorCode: 'DELETE_ITEM_ERROR',
      );
    }
  }

  @override
  Future<Resource<ReporteIncidencia>> enviarParaRevision(
      String reporteId) async {
    if (!await _networkInfo.isConnected) {
      return Error(
        'No hay conexión a internet',
        errorCode: 'NETWORK_ERROR',
      );
    }

    try {
      final reporte = await _remoteDataSource.enviarParaRevision(reporteId);
      return Success(reporte);
    } catch (e) {
      return Error(
        _extractErrorMessage(e),
        errorCode: 'ENVIAR_REPORTE_ERROR',
      );
    }
  }

  @override
  Future<Resource<ReporteIncidencia>> aprobarReporte(String reporteId) async {
    if (!await _networkInfo.isConnected) {
      return Error(
        'No hay conexión a internet',
        errorCode: 'NETWORK_ERROR',
      );
    }

    try {
      final reporte = await _remoteDataSource.aprobarReporte(reporteId);
      return Success(reporte);
    } catch (e) {
      return Error(
        _extractErrorMessage(e),
        errorCode: 'APROBAR_REPORTE_ERROR',
      );
    }
  }

  @override
  Future<Resource<ReporteIncidencia>> rechazarReporte(
    String reporteId,
    String? motivo,
  ) async {
    if (!await _networkInfo.isConnected) {
      return Error(
        'No hay conexión a internet',
        errorCode: 'NETWORK_ERROR',
      );
    }

    try {
      final reporte = await _remoteDataSource.rechazarReporte(
        reporteId,
        motivo,
      );
      return Success(reporte);
    } catch (e) {
      return Error(
        _extractErrorMessage(e),
        errorCode: 'RECHAZAR_REPORTE_ERROR',
      );
    }
  }

  @override
  Future<Resource<ReporteIncidenciaItem>> resolverItem({
    required String reporteId,
    required String itemId,
    required AccionIncidenciaProducto accionTomada,
    String? observaciones,
    String? sedeDestinoId,
  }) async {
    if (!await _networkInfo.isConnected) {
      return Error(
        'No hay conexión a internet',
        errorCode: 'NETWORK_ERROR',
      );
    }

    try {
      final item = await _remoteDataSource.resolverItem(
        reporteId: reporteId,
        itemId: itemId,
        accionTomada: accionTomada,
        observaciones: observaciones,
        sedeDestinoId: sedeDestinoId,
      );
      return Success(item);
    } catch (e) {
      return Error(
        _extractErrorMessage(e),
        errorCode: 'RESOLVER_ITEM_ERROR',
      );
    }
  }

  String _extractErrorMessage(Object error) {
    if (error is Exception) {
      final message = error.toString();
      if (message.startsWith('Exception: ')) {
        return message.substring(11);
      }
      return message;
    }
    return error.toString();
  }
}

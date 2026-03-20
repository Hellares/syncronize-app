import 'package:injectable/injectable.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/services/error_handler_service.dart';
import '../../../../core/utils/resource.dart';
import '../../domain/entities/solicitud_cotizacion.dart';
import '../../domain/repositories/solicitud_cotizacion_repository.dart';
import '../datasources/solicitud_cotizacion_remote_datasource.dart';

@LazySingleton(as: SolicitudCotizacionRepository)
class SolicitudCotizacionRepositoryImpl
    implements SolicitudCotizacionRepository {
  final SolicitudCotizacionRemoteDataSource _remoteDataSource;
  final NetworkInfo _networkInfo;
  final ErrorHandlerService _errorHandler;

  SolicitudCotizacionRepositoryImpl(
    this._remoteDataSource,
    this._networkInfo,
    this._errorHandler,
  );

  @override
  Future<Resource<SolicitudCotizacion>> crearSolicitud({
    required String empresaId,
    String? observaciones,
    required List<Map<String, dynamic>> items,
  }) async {
    if (!await _networkInfo.isConnected) {
      return Error(
        'No hay conexion a internet',
        errorCode: 'NETWORK_ERROR',
      );
    }

    try {
      final data = <String, dynamic>{
        'empresaId': empresaId,
        if (observaciones != null && observaciones.isNotEmpty)
          'observaciones': observaciones,
        'items': items,
      };
      final solicitud = await _remoteDataSource.crearSolicitud(data);
      return Success(solicitud.toEntity());
    } catch (e) {
      return _errorHandler.handleException(e,
          context: 'SolicitudCotizacion');
    }
  }

  @override
  Future<Resource<List<SolicitudCotizacion>>> getMisSolicitudes() async {
    if (!await _networkInfo.isConnected) {
      return Error(
        'No hay conexion a internet',
        errorCode: 'NETWORK_ERROR',
      );
    }

    try {
      final solicitudes = await _remoteDataSource.getMisSolicitudes();
      return Success(
        solicitudes.map((model) => model.toEntity()).toList(),
      );
    } catch (e) {
      return _errorHandler.handleException(e,
          context: 'SolicitudCotizacion');
    }
  }

  @override
  Future<Resource<SolicitudCotizacion>> getSolicitudDetalle({
    required String solicitudId,
  }) async {
    if (!await _networkInfo.isConnected) {
      return Error(
        'No hay conexion a internet',
        errorCode: 'NETWORK_ERROR',
      );
    }

    try {
      final solicitud =
          await _remoteDataSource.getSolicitudDetalle(solicitudId);
      return Success(solicitud.toEntity());
    } catch (e) {
      return _errorHandler.handleException(e,
          context: 'SolicitudCotizacion');
    }
  }

  @override
  Future<Resource<void>> cancelarSolicitud({
    required String solicitudId,
  }) async {
    if (!await _networkInfo.isConnected) {
      return Error(
        'No hay conexion a internet',
        errorCode: 'NETWORK_ERROR',
      );
    }

    try {
      await _remoteDataSource.cancelarSolicitud(solicitudId);
      return Success(null);
    } catch (e) {
      return _errorHandler.handleException(e,
          context: 'SolicitudCotizacion');
    }
  }
}

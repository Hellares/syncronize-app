import 'package:injectable/injectable.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/services/error_handler_service.dart';
import '../../../../core/utils/resource.dart';
import '../../domain/entities/cotizacion.dart';
import '../../domain/repositories/cotizacion_repository.dart';
import '../datasources/cotizacion_remote_datasource.dart';

@LazySingleton(as: CotizacionRepository)
class CotizacionRepositoryImpl implements CotizacionRepository {
  final CotizacionRemoteDataSource _remoteDataSource;
  final NetworkInfo _networkInfo;
  final ErrorHandlerService _errorHandler;

  CotizacionRepositoryImpl(
    this._remoteDataSource,
    this._networkInfo,
    this._errorHandler,
  );

  @override
  Future<Resource<Cotizacion>> crearCotizacion({
    required Map<String, dynamic> data,
  }) async {
    if (!await _networkInfo.isConnected) {
      return Error(
        'No hay conexion a internet',
        errorCode: 'NETWORK_ERROR',
      );
    }

    try {
      final cotizacion = await _remoteDataSource.crearCotizacion(data);
      return Success(cotizacion.toEntity());
    } catch (e) {
      return _errorHandler.handleException(e, context: 'Cotizacion');
    }
  }

  @override
  Future<Resource<List<Cotizacion>>> getCotizaciones({
    String? sedeId,
    String? estado,
    String? fechaDesde,
    String? fechaHasta,
    String? clienteId,
    String? search,
  }) async {
    if (!await _networkInfo.isConnected) {
      return Error(
        'No hay conexion a internet',
        errorCode: 'NETWORK_ERROR',
      );
    }

    try {
      final cotizaciones = await _remoteDataSource.getCotizaciones(
        sedeId: sedeId,
        estado: estado,
        fechaDesde: fechaDesde,
        fechaHasta: fechaHasta,
        clienteId: clienteId,
        search: search,
      );
      return Success(
        cotizaciones.map((model) => model.toEntity()).toList(),
      );
    } catch (e) {
      return _errorHandler.handleException(e, context: 'Cotizacion');
    }
  }

  @override
  Future<Resource<Cotizacion>> getCotizacion({
    required String cotizacionId,
  }) async {
    if (!await _networkInfo.isConnected) {
      return Error(
        'No hay conexion a internet',
        errorCode: 'NETWORK_ERROR',
      );
    }

    try {
      final cotizacion = await _remoteDataSource.getCotizacion(cotizacionId);
      return Success(cotizacion.toEntity());
    } catch (e) {
      return _errorHandler.handleException(e, context: 'Cotizacion');
    }
  }

  @override
  Future<Resource<Cotizacion>> actualizarCotizacion({
    required String cotizacionId,
    required Map<String, dynamic> data,
  }) async {
    if (!await _networkInfo.isConnected) {
      return Error(
        'No hay conexion a internet',
        errorCode: 'NETWORK_ERROR',
      );
    }

    try {
      final cotizacion =
          await _remoteDataSource.actualizarCotizacion(cotizacionId, data);
      return Success(cotizacion.toEntity());
    } catch (e) {
      return _errorHandler.handleException(e, context: 'Cotizacion');
    }
  }

  @override
  Future<Resource<Cotizacion>> cambiarEstado({
    required String cotizacionId,
    required Map<String, dynamic> data,
  }) async {
    if (!await _networkInfo.isConnected) {
      return Error(
        'No hay conexion a internet',
        errorCode: 'NETWORK_ERROR',
      );
    }

    try {
      final cotizacion =
          await _remoteDataSource.cambiarEstado(cotizacionId, data);
      return Success(cotizacion.toEntity());
    } catch (e) {
      return _errorHandler.handleException(e, context: 'Cotizacion');
    }
  }

  @override
  Future<Resource<Cotizacion>> duplicarCotizacion({
    required String cotizacionId,
  }) async {
    if (!await _networkInfo.isConnected) {
      return Error(
        'No hay conexion a internet',
        errorCode: 'NETWORK_ERROR',
      );
    }

    try {
      final cotizacion =
          await _remoteDataSource.duplicarCotizacion(cotizacionId);
      return Success(cotizacion.toEntity());
    } catch (e) {
      return _errorHandler.handleException(e, context: 'Cotizacion');
    }
  }

  @override
  Future<Resource<void>> eliminarCotizacion({
    required String cotizacionId,
  }) async {
    if (!await _networkInfo.isConnected) {
      return Error(
        'No hay conexion a internet',
        errorCode: 'NETWORK_ERROR',
      );
    }

    try {
      await _remoteDataSource.eliminarCotizacion(cotizacionId);
      return Success(null);
    } catch (e) {
      return _errorHandler.handleException(e, context: 'Cotizacion');
    }
  }

  @override
  Future<Resource<Map<String, dynamic>>> validarCompatibilidad({
    required List<Map<String, dynamic>> detalles,
  }) async {
    if (!await _networkInfo.isConnected) {
      return Error(
        'No hay conexion a internet',
        errorCode: 'NETWORK_ERROR',
      );
    }

    try {
      final result = await _remoteDataSource.validarCompatibilidad(detalles);
      return Success(result);
    } catch (e) {
      return _errorHandler.handleException(e, context: 'Cotizacion');
    }
  }
}

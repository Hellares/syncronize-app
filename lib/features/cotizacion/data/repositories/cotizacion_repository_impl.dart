import 'package:injectable/injectable.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/services/error_handler_service.dart';
import '../../../../core/utils/resource.dart';
import '../../../cotizacion_rapida/data/datasources/cotizacion_rapida_remote_datasource.dart';
import '../../domain/entities/cotizacion.dart';
import '../../domain/entities/cotizaciones_page.dart';
import '../../domain/repositories/cotizacion_repository.dart';

@LazySingleton(as: CotizacionRepository)
class CotizacionRepositoryImpl implements CotizacionRepository {
  final CotizacionRapidaRemoteDataSource _remoteDataSource;
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
      final cotizacion = await _remoteDataSource.crear(data);
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
      final cotizaciones = await _remoteDataSource.listar(
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
  Future<Resource<CotizacionesPage>> getCotizacionesPaginadas({
    String? sedeId,
    String? estado,
    String? search,
    required int limit,
    String? cursor,
  }) async {
    if (!await _networkInfo.isConnected) {
      return Error(
        'No hay conexion a internet',
        errorCode: 'NETWORK_ERROR',
      );
    }

    try {
      final page = await _remoteDataSource.listarPaginado(
        sedeId: sedeId,
        estado: estado,
        search: search,
        limit: limit,
        cursor: cursor,
      );
      return Success(CotizacionesPage(
        cotizaciones: page.items.map((m) => m.toEntity()).toList(),
        hasMore: page.hasMore,
        nextCursor: page.nextCursor,
      ));
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
      final cotizacion = await _remoteDataSource.obtener(cotizacionId);
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
          await _remoteDataSource.actualizar(cotizacionId, data);
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
      final cotizacion = await _remoteDataSource.duplicar(cotizacionId);
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
      await _remoteDataSource.eliminar(cotizacionId);
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

import 'package:injectable/injectable.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/services/error_handler_service.dart';
import '../../../../core/utils/resource.dart';
import '../../../cotizacion/domain/entities/cotizacion.dart';
import '../../domain/repositories/cotizacion_rapida_repository.dart';
import '../datasources/cotizacion_rapida_remote_datasource.dart';

@LazySingleton(as: CotizacionRapidaRepository)
class CotizacionRapidaRepositoryImpl implements CotizacionRapidaRepository {
  final CotizacionRapidaRemoteDataSource _remoteDataSource;
  final NetworkInfo _networkInfo;
  final ErrorHandlerService _errorHandler;

  CotizacionRapidaRepositoryImpl(
    this._remoteDataSource,
    this._networkInfo,
    this._errorHandler,
  );

  @override
  Future<Resource<Cotizacion>> crear({
    required Map<String, dynamic> data,
  }) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexion a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final model = await _remoteDataSource.crear(data);
      return Success(model.toEntity());
    } catch (e) {
      return _errorHandler.handleException(e, context: 'CotizacionRapida');
    }
  }

  @override
  Future<Resource<Cotizacion>> actualizar({
    required String cotizacionId,
    required Map<String, dynamic> data,
  }) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexion a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final model = await _remoteDataSource.actualizar(cotizacionId, data);
      return Success(model.toEntity());
    } catch (e) {
      return _errorHandler.handleException(e, context: 'CotizacionRapida');
    }
  }

  @override
  Future<Resource<Cotizacion>> obtener({
    required String cotizacionId,
  }) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexion a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final model = await _remoteDataSource.obtener(cotizacionId);
      return Success(model.toEntity());
    } catch (e) {
      return _errorHandler.handleException(e, context: 'CotizacionRapida');
    }
  }
}

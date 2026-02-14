import 'package:injectable/injectable.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/services/error_handler_service.dart';
import '../../../../core/utils/resource.dart';
import '../../domain/entities/configuracion_precio.dart';
import '../../domain/repositories/configuracion_precio_repository.dart';
import '../datasources/configuracion_precio_remote_datasource.dart';
import '../models/configuracion_precio_model.dart';

@LazySingleton(as: ConfiguracionPrecioRepository)
class ConfiguracionPrecioRepositoryImpl
    implements ConfiguracionPrecioRepository {
  final ConfiguracionPrecioRemoteDataSource _remoteDataSource;
  final NetworkInfo _networkInfo;
  final ErrorHandlerService _errorHandler;

  ConfiguracionPrecioRepositoryImpl(
    this._remoteDataSource,
    this._networkInfo,
    this._errorHandler,
  );

  @override
  Future<Resource<ConfiguracionPrecio>> crear(
    ConfiguracionPrecioDto dto,
  ) async {
    if (!await _networkInfo.isConnected) {
      return Error(
        'No hay conexión a internet',
        errorCode: 'NETWORK_ERROR',
      );
    }

    try {
      final configuracion = await _remoteDataSource.crear(dto);
      return Success<ConfiguracionPrecio>(configuracion);
    } catch (e) {
      return _errorHandler.handleException(e, context: 'ConfiguracionPrecio');
    }
  }

  @override
  Future<Resource<List<ConfiguracionPrecio>>> obtenerTodas() async {
    if (!await _networkInfo.isConnected) {
      return Error(
        'No hay conexión a internet',
        errorCode: 'NETWORK_ERROR',
      );
    }

    try {
      final configuraciones = await _remoteDataSource.obtenerTodas();
      return Success<List<ConfiguracionPrecio>>(configuraciones);
    } catch (e) {
      return _errorHandler.handleException(e, context: 'ConfiguracionPrecio');
    }
  }

  @override
  Future<Resource<ConfiguracionPrecio>> obtenerPorId(
    String configuracionId,
  ) async {
    if (!await _networkInfo.isConnected) {
      return Error(
        'No hay conexión a internet',
        errorCode: 'NETWORK_ERROR',
      );
    }

    try {
      final configuracion = await _remoteDataSource.obtenerPorId(
        configuracionId,
      );
      return Success<ConfiguracionPrecio>(configuracion);
    } catch (e) {
      return _errorHandler.handleException(e, context: 'ConfiguracionPrecio');
    }
  }

  @override
  Future<Resource<ConfiguracionPrecio>> actualizar(
    String configuracionId,
    ConfiguracionPrecioDto dto,
  ) async {
    if (!await _networkInfo.isConnected) {
      return Error(
        'No hay conexión a internet',
        errorCode: 'NETWORK_ERROR',
      );
    }

    try {
      final configuracion = await _remoteDataSource.actualizar(
        configuracionId,
        dto,
      );
      return Success<ConfiguracionPrecio>(configuracion);
    } catch (e) {
      return _errorHandler.handleException(e, context: 'ConfiguracionPrecio');
    }
  }

  @override
  Future<Resource<void>> eliminar(
    String configuracionId,
  ) async {
    if (!await _networkInfo.isConnected) {
      return Error(
        'No hay conexión a internet',
        errorCode: 'NETWORK_ERROR',
      );
    }

    try {
      await _remoteDataSource.eliminar(configuracionId);
      return Success(null);
    } catch (e) {
      return _errorHandler.handleException(e, context: 'ConfiguracionPrecio');
    }
  }
}

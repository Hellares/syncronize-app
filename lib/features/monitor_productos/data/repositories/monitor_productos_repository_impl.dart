import 'package:injectable/injectable.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/services/error_handler_service.dart';
import '../../../../core/utils/resource.dart';
import '../../domain/entities/monitor_productos.dart';
import '../../domain/repositories/monitor_productos_repository.dart';
import '../datasources/monitor_productos_remote_datasource.dart';

@LazySingleton(as: MonitorProductosRepository)
class MonitorProductosRepositoryImpl implements MonitorProductosRepository {
  final MonitorProductosRemoteDataSource _remoteDataSource;
  final NetworkInfo _networkInfo;
  final ErrorHandlerService _errorHandler;

  MonitorProductosRepositoryImpl(
    this._remoteDataSource,
    this._networkInfo,
    this._errorHandler,
  );

  @override
  Future<Resource<MonitorProductos>> getMonitor({String? sedeId}) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexión a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final result = await _remoteDataSource.getMonitor(sedeId: sedeId);
      return Success(result.toEntity());
    } catch (e) {
      return _errorHandler.handleException(e, context: 'MonitorProductos');
    }
  }

  @override
  Future<Resource<void>> bulkMarketplace(List<String> ids, bool visible) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexión a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      await _remoteDataSource.bulkMarketplace(ids, visible);
      return Success(null);
    } catch (e) {
      return _errorHandler.handleException(e, context: 'MonitorProductos');
    }
  }

  @override
  Future<Resource<void>> bulkUbicacion(List<String> ids, String ubicacion) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexión a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      await _remoteDataSource.bulkUbicacion(ids, ubicacion);
      return Success(null);
    } catch (e) {
      return _errorHandler.handleException(e, context: 'MonitorProductos');
    }
  }

  @override
  Future<Resource<void>> bulkPrecioIgv(List<String> ids, bool incluyeIgv) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexión a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      await _remoteDataSource.bulkPrecioIgv(ids, incluyeIgv);
      return Success(null);
    } catch (e) {
      return _errorHandler.handleException(e, context: 'MonitorProductos');
    }
  }
}

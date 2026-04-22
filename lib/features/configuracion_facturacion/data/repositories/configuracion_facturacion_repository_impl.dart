import 'package:injectable/injectable.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/services/error_handler_service.dart';
import '../../../../core/utils/resource.dart';
import '../../domain/entities/configuracion_facturacion.dart';
import '../../domain/repositories/configuracion_facturacion_repository.dart';
import '../datasources/configuracion_facturacion_remote_datasource.dart';

@LazySingleton(as: ConfiguracionFacturacionRepository)
class ConfiguracionFacturacionRepositoryImpl
    implements ConfiguracionFacturacionRepository {
  final ConfiguracionFacturacionRemoteDataSource _remoteDataSource;
  final NetworkInfo _networkInfo;
  final ErrorHandlerService _errorHandler;

  ConfiguracionFacturacionRepositoryImpl(
    this._remoteDataSource,
    this._networkInfo,
    this._errorHandler,
  );

  @override
  Future<Resource<ConfiguracionFacturacion>> getConfiguracion() async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexión a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final result = await _remoteDataSource.getConfiguracion();
      return Success(result.toEntity());
    } catch (e) {
      return _errorHandler.handleException(e,
          context: 'ConfiguracionFacturacion');
    }
  }

  @override
  Future<Resource<ConfiguracionFacturacion>> updateConfiguracion(
    Map<String, dynamic> data,
  ) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexión a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final result = await _remoteDataSource.updateConfiguracion(data);
      return Success(result.toEntity());
    } catch (e) {
      return _errorHandler.handleException(e,
          context: 'ConfiguracionFacturacion');
    }
  }

  @override
  Future<Resource<ResultadoProbarConexion>> probarConexion({
    required ProveedorFacturacion proveedorActivo,
    required String proveedorRuta,
    required String proveedorToken,
    Map<String, dynamic>? proveedorConfig,
  }) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexión a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final result = await _remoteDataSource.probarConexion(
        proveedorActivo: proveedorActivo,
        proveedorRuta: proveedorRuta,
        proveedorToken: proveedorToken,
        proveedorConfig: proveedorConfig,
      );
      return Success(result);
    } catch (e) {
      return _errorHandler.handleException(e,
          context: 'ConfiguracionFacturacion.probar');
    }
  }
}

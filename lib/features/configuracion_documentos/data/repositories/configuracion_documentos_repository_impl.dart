import 'package:injectable/injectable.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/services/error_handler_service.dart';
import '../../../../core/utils/resource.dart';
import '../../domain/entities/configuracion_documentos.dart';
import '../../domain/entities/plantilla_documento.dart';
import '../../domain/entities/configuracion_documento_completa.dart';
import '../../domain/repositories/configuracion_documentos_repository.dart';
import '../datasources/configuracion_documentos_remote_datasource.dart';

@LazySingleton(as: ConfiguracionDocumentosRepository)
class ConfiguracionDocumentosRepositoryImpl
    implements ConfiguracionDocumentosRepository {
  final ConfiguracionDocumentosRemoteDataSource _remoteDataSource;
  final NetworkInfo _networkInfo;
  final ErrorHandlerService _errorHandler;

  ConfiguracionDocumentosRepositoryImpl(
    this._remoteDataSource,
    this._networkInfo,
    this._errorHandler,
  );

  @override
  Future<Resource<ConfiguracionDocumentos>> getConfiguracion() async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexion a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final result = await _remoteDataSource.getConfiguracion();
      return Success(result.toEntity());
    } catch (e) {
      return _errorHandler.handleException(e,
          context: 'ConfiguracionDocumentos');
    }
  }

  @override
  Future<Resource<ConfiguracionDocumentos>> updateConfiguracion(
    Map<String, dynamic> data,
  ) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexion a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final result = await _remoteDataSource.updateConfiguracion(data);
      return Success(result.toEntity());
    } catch (e) {
      return _errorHandler.handleException(e,
          context: 'ConfiguracionDocumentos');
    }
  }

  @override
  Future<Resource<List<PlantillaDocumento>>> getPlantillas() async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexion a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final result = await _remoteDataSource.getPlantillas();
      return Success(result.map((e) => e.toEntity()).toList());
    } catch (e) {
      return _errorHandler.handleException(e,
          context: 'ConfiguracionDocumentos');
    }
  }

  @override
  Future<Resource<PlantillaDocumento>> getPlantillaByTipo(
    String tipo, {
    String? formato,
  }) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexion a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final result =
          await _remoteDataSource.getPlantillaByTipo(tipo, formato: formato);
      return Success(result.toEntity());
    } catch (e) {
      return _errorHandler.handleException(e,
          context: 'ConfiguracionDocumentos');
    }
  }

  @override
  Future<Resource<PlantillaDocumento>> updatePlantilla(
    String tipo,
    Map<String, dynamic> data,
  ) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexion a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final result = await _remoteDataSource.updatePlantilla(tipo, data);
      return Success(result.toEntity());
    } catch (e) {
      return _errorHandler.handleException(e,
          context: 'ConfiguracionDocumentos');
    }
  }

  @override
  Future<Resource<ConfiguracionDocumentoCompleta>> getConfiguracionCompleta(
    String tipo, {
    String? formato,
    String? sedeId,
  }) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexion a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final result = await _remoteDataSource.getConfiguracionCompleta(
        tipo,
        formato: formato,
        sedeId: sedeId,
      );
      return Success(result.toEntity());
    } catch (e) {
      return _errorHandler.handleException(e,
          context: 'ConfiguracionDocumentos');
    }
  }
}

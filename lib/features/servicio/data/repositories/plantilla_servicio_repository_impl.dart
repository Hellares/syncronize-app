import 'package:injectable/injectable.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/services/error_handler_service.dart';
import '../../../../core/utils/resource.dart';
import '../../domain/entities/plantilla_servicio.dart';
import '../../domain/entities/configuracion_campo.dart';
import '../../domain/repositories/plantilla_servicio_repository.dart';
import '../datasources/plantilla_servicio_remote_datasource.dart';

@LazySingleton(as: PlantillaServicioRepository)
class PlantillaServicioRepositoryImpl implements PlantillaServicioRepository {
  final PlantillaServicioRemoteDataSource _remoteDataSource;
  final NetworkInfo _networkInfo;
  final ErrorHandlerService _errorHandler;

  PlantillaServicioRepositoryImpl(
    this._remoteDataSource,
    this._networkInfo,
    this._errorHandler,
  );

  @override
  Future<Resource<List<PlantillaServicio>>> getAll() async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexión a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final result = await _remoteDataSource.getAll();
      return Success(result);
    } catch (e) {
      return _errorHandler.handleException(e, context: 'PlantillaServicio');
    }
  }

  @override
  Future<Resource<PlantillaServicio>> getOne(String id) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexión a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final result = await _remoteDataSource.getOne(id);
      return Success(result);
    } catch (e) {
      return _errorHandler.handleException(e, context: 'PlantillaServicio');
    }
  }

  @override
  Future<Resource<PlantillaServicio>> crear({
    required String nombre,
    String? descripcion,
    List<Map<String, dynamic>>? campos,
  }) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexión a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final data = <String, dynamic>{
        'nombre': nombre,
        if (descripcion != null) 'descripcion': descripcion,
        if (campos != null) 'campos': campos,
      };
      final result = await _remoteDataSource.crear(data);
      return Success(result);
    } catch (e) {
      return _errorHandler.handleException(e, context: 'PlantillaServicio');
    }
  }

  @override
  Future<Resource<PlantillaServicio>> actualizar({
    required String id,
    String? nombre,
    String? descripcion,
  }) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexión a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final data = <String, dynamic>{
        if (nombre != null) 'nombre': nombre,
        if (descripcion != null) 'descripcion': descripcion,
      };
      final result = await _remoteDataSource.actualizar(id, data);
      return Success(result);
    } catch (e) {
      return _errorHandler.handleException(e, context: 'PlantillaServicio');
    }
  }

  @override
  Future<Resource<void>> eliminar(String id) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexión a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      await _remoteDataSource.eliminar(id);
      return Success(null);
    } catch (e) {
      return _errorHandler.handleException(e, context: 'PlantillaServicio');
    }
  }

  @override
  Future<Resource<ConfiguracionCampo>> addCampo({
    required String plantillaId,
    required Map<String, dynamic> campoData,
  }) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexión a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final result = await _remoteDataSource.addCampo(plantillaId, campoData);
      return Success(result);
    } catch (e) {
      return _errorHandler.handleException(e, context: 'PlantillaServicio');
    }
  }

  @override
  Future<Resource<List<ConfiguracionCampo>>> getCamposByServicioId(String servicioId) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexión a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final result = await _remoteDataSource.getCamposByServicioId(servicioId);
      return Success(result);
    } catch (e) {
      return _errorHandler.handleException(e, context: 'PlantillaServicio');
    }
  }
}

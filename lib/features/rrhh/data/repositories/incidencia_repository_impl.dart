import 'package:injectable/injectable.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/services/error_handler_service.dart';
import '../../../../core/utils/resource.dart';
import '../../domain/entities/incidencia.dart';
import '../../domain/repositories/incidencia_repository.dart';
import '../datasources/incidencia_remote_datasource.dart';

@LazySingleton(as: IncidenciaRepository)
class IncidenciaRepositoryImpl implements IncidenciaRepository {
  final IncidenciaRemoteDataSource _remoteDataSource;
  final NetworkInfo _networkInfo;
  final ErrorHandlerService _errorHandler;

  IncidenciaRepositoryImpl(
    this._remoteDataSource,
    this._networkInfo,
    this._errorHandler,
  );

  @override
  Future<Resource<Incidencia>> create(Map<String, dynamic> data) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexion a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final result = await _remoteDataSource.create(data);
      return Success(result.toEntity());
    } catch (e) {
      return _errorHandler.handleException(e, context: 'Incidencia');
    }
  }

  @override
  Future<Resource<List<Incidencia>>> getAll({
    Map<String, dynamic>? queryParams,
  }) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexion a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final result =
          await _remoteDataSource.getAll(queryParams: queryParams);
      return Success(result.map((model) => model.toEntity()).toList());
    } catch (e) {
      return _errorHandler.handleException(e, context: 'Incidencia');
    }
  }

  @override
  Future<Resource<Incidencia>> getById(String id) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexion a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final result = await _remoteDataSource.getById(id);
      return Success(result.toEntity());
    } catch (e) {
      return _errorHandler.handleException(e, context: 'Incidencia');
    }
  }

  @override
  Future<Resource<Incidencia>> aprobar(String id) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexion a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final result = await _remoteDataSource.aprobar(id);
      return Success(result.toEntity());
    } catch (e) {
      return _errorHandler.handleException(e, context: 'Incidencia');
    }
  }

  @override
  Future<Resource<Incidencia>> rechazar(
      String id, String motivoRechazo) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexion a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final result =
          await _remoteDataSource.rechazar(id, motivoRechazo);
      return Success(result.toEntity());
    } catch (e) {
      return _errorHandler.handleException(e, context: 'Incidencia');
    }
  }

  @override
  Future<Resource<Incidencia>> cancelar(String id) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexion a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final result = await _remoteDataSource.cancelar(id);
      return Success(result.toEntity());
    } catch (e) {
      return _errorHandler.handleException(e, context: 'Incidencia');
    }
  }
}

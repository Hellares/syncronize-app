import 'package:injectable/injectable.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/services/error_handler_service.dart';
import '../../../../core/utils/resource.dart';
import '../../domain/entities/empleado.dart';
import '../../domain/repositories/empleado_repository.dart';
import '../datasources/empleado_remote_datasource.dart';

@LazySingleton(as: EmpleadoRepository)
class EmpleadoRepositoryImpl implements EmpleadoRepository {
  final EmpleadoRemoteDataSource _remoteDataSource;
  final NetworkInfo _networkInfo;
  final ErrorHandlerService _errorHandler;

  EmpleadoRepositoryImpl(
    this._remoteDataSource,
    this._networkInfo,
    this._errorHandler,
  );

  @override
  Future<Resource<Empleado>> create(Map<String, dynamic> data) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexion a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final result = await _remoteDataSource.create(data);
      return Success(result.toEntity());
    } catch (e) {
      return _errorHandler.handleException(e, context: 'Empleado');
    }
  }

  @override
  Future<Resource<List<Empleado>>> getAll({
    Map<String, dynamic>? queryParams,
  }) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexion a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final result = await _remoteDataSource.getAll(queryParams: queryParams);
      return Success(result.map((model) => model.toEntity()).toList());
    } catch (e) {
      return _errorHandler.handleException(e, context: 'Empleado');
    }
  }

  @override
  Future<Resource<Empleado>> getById(String id) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexion a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final result = await _remoteDataSource.getById(id);
      return Success(result.toEntity());
    } catch (e) {
      return _errorHandler.handleException(e, context: 'Empleado');
    }
  }

  @override
  Future<Resource<Empleado>> update(
      String id, Map<String, dynamic> data) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexion a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final result = await _remoteDataSource.update(id, data);
      return Success(result.toEntity());
    } catch (e) {
      return _errorHandler.handleException(e, context: 'Empleado');
    }
  }

  @override
  Future<Resource<void>> delete(String id) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexion a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      await _remoteDataSource.delete(id);
      return Success(null);
    } catch (e) {
      return _errorHandler.handleException(e, context: 'Empleado');
    }
  }
}

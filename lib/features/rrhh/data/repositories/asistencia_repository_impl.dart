import 'package:injectable/injectable.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/services/error_handler_service.dart';
import '../../../../core/utils/resource.dart';
import '../../domain/entities/asistencia.dart';
import '../../domain/repositories/asistencia_repository.dart';
import '../datasources/asistencia_remote_datasource.dart';

@LazySingleton(as: AsistenciaRepository)
class AsistenciaRepositoryImpl implements AsistenciaRepository {
  final AsistenciaRemoteDataSource _remoteDataSource;
  final NetworkInfo _networkInfo;
  final ErrorHandlerService _errorHandler;

  AsistenciaRepositoryImpl(
    this._remoteDataSource,
    this._networkInfo,
    this._errorHandler,
  );

  @override
  Future<Resource<Asistencia>> registrarEntrada(
      Map<String, dynamic> data) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexion a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final result = await _remoteDataSource.registrarEntrada(data);
      return Success(result.toEntity());
    } catch (e) {
      return _errorHandler.handleException(e, context: 'Asistencia');
    }
  }

  @override
  Future<Resource<Asistencia>> registrarSalida(
      String id, Map<String, dynamic> data) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexion a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final result = await _remoteDataSource.registrarSalida(id, data);
      return Success(result.toEntity());
    } catch (e) {
      return _errorHandler.handleException(e, context: 'Asistencia');
    }
  }

  @override
  Future<Resource<List<Asistencia>>> getAll({
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
      return _errorHandler.handleException(e, context: 'Asistencia');
    }
  }

  @override
  Future<Resource<AsistenciaResumen>> getResumenMensual(
      String empleadoId, int mes, int anio) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexion a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final result =
          await _remoteDataSource.getResumenMensual(empleadoId, mes, anio);
      return Success(result.toEntity());
    } catch (e) {
      return _errorHandler.handleException(e, context: 'Asistencia');
    }
  }

  @override
  Future<Resource<List<Asistencia>>> registrarBulk(
      Map<String, dynamic> data) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexion a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final result = await _remoteDataSource.registrarBulk(data);
      return Success(result.map((model) => model.toEntity()).toList());
    } catch (e) {
      return _errorHandler.handleException(e, context: 'Asistencia');
    }
  }
}

import 'package:injectable/injectable.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/services/error_handler_service.dart';
import '../../../../core/utils/resource.dart';
import '../../domain/entities/turno.dart';
import '../../domain/repositories/turno_repository.dart';
import '../datasources/turno_remote_datasource.dart';

@LazySingleton(as: TurnoRepository)
class TurnoRepositoryImpl implements TurnoRepository {
  final TurnoRemoteDataSource _remoteDataSource;
  final NetworkInfo _networkInfo;
  final ErrorHandlerService _errorHandler;

  TurnoRepositoryImpl(
    this._remoteDataSource,
    this._networkInfo,
    this._errorHandler,
  );

  @override
  Future<Resource<Turno>> create(Map<String, dynamic> data) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexion a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final result = await _remoteDataSource.create(data);
      return Success(result.toEntity());
    } catch (e) {
      return _errorHandler.handleException(e, context: 'Turno');
    }
  }

  @override
  Future<Resource<List<Turno>>> getAll() async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexion a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final result = await _remoteDataSource.getAll();
      return Success(result.map((model) => model.toEntity()).toList());
    } catch (e) {
      return _errorHandler.handleException(e, context: 'Turno');
    }
  }

  @override
  Future<Resource<Turno>> update(String id, Map<String, dynamic> data) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexion a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final result = await _remoteDataSource.update(id, data);
      return Success(result.toEntity());
    } catch (e) {
      return _errorHandler.handleException(e, context: 'Turno');
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
      return _errorHandler.handleException(e, context: 'Turno');
    }
  }
}

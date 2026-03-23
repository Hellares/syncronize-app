import 'package:injectable/injectable.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/services/error_handler_service.dart';
import '../../../../core/utils/resource.dart';
import '../../domain/entities/adelanto.dart';
import '../../domain/repositories/adelanto_repository.dart';
import '../datasources/adelanto_remote_datasource.dart';

@LazySingleton(as: AdelantoRepository)
class AdelantoRepositoryImpl implements AdelantoRepository {
  final AdelantoRemoteDataSource _remoteDataSource;
  final NetworkInfo _networkInfo;
  final ErrorHandlerService _errorHandler;

  AdelantoRepositoryImpl(
    this._remoteDataSource,
    this._networkInfo,
    this._errorHandler,
  );

  @override
  Future<Resource<Adelanto>> create(Map<String, dynamic> data) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexion a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final result = await _remoteDataSource.create(data);
      return Success(result.toEntity());
    } catch (e) {
      return _errorHandler.handleException(e, context: 'Adelanto');
    }
  }

  @override
  Future<Resource<List<Adelanto>>> getAll({
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
      return _errorHandler.handleException(e, context: 'Adelanto');
    }
  }

  @override
  Future<Resource<Adelanto>> aprobar(String id) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexion a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final result = await _remoteDataSource.aprobar(id);
      return Success(result.toEntity());
    } catch (e) {
      return _errorHandler.handleException(e, context: 'Adelanto');
    }
  }

  @override
  Future<Resource<Adelanto>> rechazar(
      String id, String motivoRechazo) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexion a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final result =
          await _remoteDataSource.rechazar(id, motivoRechazo);
      return Success(result.toEntity());
    } catch (e) {
      return _errorHandler.handleException(e, context: 'Adelanto');
    }
  }

  @override
  Future<Resource<Adelanto>> pagar(
      String id, Map<String, dynamic> data) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexion a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final result = await _remoteDataSource.pagar(id, data);
      return Success(result.toEntity());
    } catch (e) {
      return _errorHandler.handleException(e, context: 'Adelanto');
    }
  }
}

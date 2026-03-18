import 'package:injectable/injectable.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/utils/resource.dart';
import '../../domain/entities/direccion_persona.dart';
import '../../domain/repositories/direccion_repository.dart';
import '../datasources/direccion_remote_datasource.dart';

@LazySingleton(as: DireccionRepository)
class DireccionRepositoryImpl implements DireccionRepository {
  final DireccionRemoteDataSource _remoteDataSource;
  final NetworkInfo _networkInfo;

  DireccionRepositoryImpl(this._remoteDataSource, this._networkInfo);

  @override
  Future<Resource<List<DireccionPersona>>> listar() async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexión a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final result = await _remoteDataSource.listar();
      return Success(result.map((e) => e.toEntity()).toList());
    } catch (e) {
      return Error(e.toString().replaceFirst('Exception: ', ''),
          errorCode: 'SERVER_ERROR');
    }
  }

  @override
  Future<Resource<DireccionPersona>> crear(Map<String, dynamic> data) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexión a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final result = await _remoteDataSource.crear(data);
      return Success(result.toEntity());
    } catch (e) {
      return Error(e.toString().replaceFirst('Exception: ', ''),
          errorCode: 'SERVER_ERROR');
    }
  }

  @override
  Future<Resource<DireccionPersona>> actualizar(String id, Map<String, dynamic> data) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexión a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final result = await _remoteDataSource.actualizar(id, data);
      return Success(result.toEntity());
    } catch (e) {
      return Error(e.toString().replaceFirst('Exception: ', ''),
          errorCode: 'SERVER_ERROR');
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
      return Error(e.toString().replaceFirst('Exception: ', ''),
          errorCode: 'SERVER_ERROR');
    }
  }

  @override
  Future<Resource<DireccionPersona>> marcarPredeterminada(String id) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexión a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      final result = await _remoteDataSource.marcarPredeterminada(id);
      return Success(result.toEntity());
    } catch (e) {
      return Error(e.toString().replaceFirst('Exception: ', ''),
          errorCode: 'SERVER_ERROR');
    }
  }
}

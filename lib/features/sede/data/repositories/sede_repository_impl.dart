import 'package:injectable/injectable.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/utils/resource.dart';
import '../../../empresa/domain/entities/sede.dart';
import '../../domain/repositories/sede_repository.dart';
import '../datasources/sede_remote_datasource.dart';

@LazySingleton(as: SedeRepository)
class SedeRepositoryImpl implements SedeRepository {
  final SedeRemoteDataSource _remoteDataSource;
  final NetworkInfo _networkInfo;

  SedeRepositoryImpl(
    this._remoteDataSource,
    this._networkInfo,
  );

  @override
  Future<Resource<List<Sede>>> getSedes(String empresaId) async {
    if (!await _networkInfo.isConnected) {
      return Error(
        'No hay conexión a internet',
        errorCode: 'NETWORK_ERROR',
      );
    }

    try {
      final sedes = await _remoteDataSource.getSedes(empresaId);
      return Success(sedes.map((e) => e.toEntity()).toList());
    } catch (e) {
      return Error(
        _extractErrorMessage(e),
        errorCode: 'GET_SEDES_ERROR',
      );
    }
  }

  @override
  Future<Resource<Sede>> getSedeById({
    required String empresaId,
    required String sedeId,
  }) async {
    if (!await _networkInfo.isConnected) {
      return Error(
        'No hay conexión a internet',
        errorCode: 'NETWORK_ERROR',
      );
    }

    try {
      final sede = await _remoteDataSource.getSedeById(
        empresaId: empresaId,
        sedeId: sedeId,
      );
      return Success(sede.toEntity());
    } catch (e) {
      return Error(
        _extractErrorMessage(e),
        errorCode: 'GET_SEDE_ERROR',
      );
    }
  }

  @override
  Future<Resource<Sede>> createSede({
    required String empresaId,
    required Map<String, dynamic> data,
  }) async {
    if (!await _networkInfo.isConnected) {
      return Error(
        'No hay conexión a internet',
        errorCode: 'NETWORK_ERROR',
      );
    }

    try {
      final sede = await _remoteDataSource.createSede(
        empresaId: empresaId,
        data: data,
      );
      return Success(sede.toEntity());
    } catch (e) {
      return Error(
        _extractErrorMessage(e),
        errorCode: 'CREATE_SEDE_ERROR',
      );
    }
  }

  @override
  Future<Resource<Sede>> updateSede({
    required String empresaId,
    required String sedeId,
    required Map<String, dynamic> data,
  }) async {
    if (!await _networkInfo.isConnected) {
      return Error(
        'No hay conexión a internet',
        errorCode: 'NETWORK_ERROR',
      );
    }

    try {
      final sede = await _remoteDataSource.updateSede(
        empresaId: empresaId,
        sedeId: sedeId,
        data: data,
      );
      return Success(sede.toEntity());
    } catch (e) {
      return Error(
        _extractErrorMessage(e),
        errorCode: 'UPDATE_SEDE_ERROR',
      );
    }
  }

  @override
  Future<Resource<void>> deleteSede({
    required String empresaId,
    required String sedeId,
  }) async {
    if (!await _networkInfo.isConnected) {
      return Error(
        'No hay conexión a internet',
        errorCode: 'NETWORK_ERROR',
      );
    }

    try {
      await _remoteDataSource.deleteSede(
        empresaId: empresaId,
        sedeId: sedeId,
      );
      return Success(null);
    } catch (e) {
      return Error(
        _extractErrorMessage(e),
        errorCode: 'DELETE_SEDE_ERROR',
      );
    }
  }

  @override
  Future<Resource<List<Map<String, dynamic>>>> getSedeUsuarios({
    required String empresaId,
    required String sedeId,
  }) async {
    if (!await _networkInfo.isConnected) {
      return Error(
        'No hay conexión a internet',
        errorCode: 'NETWORK_ERROR',
      );
    }

    try {
      final usuarios = await _remoteDataSource.getSedeUsuarios(
        empresaId: empresaId,
        sedeId: sedeId,
      );
      return Success(usuarios);
    } catch (e) {
      return Error(
        _extractErrorMessage(e),
        errorCode: 'GET_SEDE_USUARIOS_ERROR',
      );
    }
  }

  @override
  Future<Resource<Map<String, dynamic>>> assignUsuarioToSede({
    required String empresaId,
    required String sedeId,
    required Map<String, dynamic> data,
  }) async {
    if (!await _networkInfo.isConnected) {
      return Error(
        'No hay conexión a internet',
        errorCode: 'NETWORK_ERROR',
      );
    }

    try {
      final result = await _remoteDataSource.assignUsuarioToSede(
        empresaId: empresaId,
        sedeId: sedeId,
        data: data,
      );
      return Success(result);
    } catch (e) {
      return Error(
        _extractErrorMessage(e),
        errorCode: 'ASSIGN_USUARIO_ERROR',
      );
    }
  }

  @override
  Future<Resource<void>> removeUsuarioFromSede({
    required String empresaId,
    required String sedeId,
    required String usuarioSedeRolId,
  }) async {
    if (!await _networkInfo.isConnected) {
      return Error(
        'No hay conexión a internet',
        errorCode: 'NETWORK_ERROR',
      );
    }

    try {
      await _remoteDataSource.removeUsuarioFromSede(
        empresaId: empresaId,
        sedeId: sedeId,
        usuarioSedeRolId: usuarioSedeRolId,
      );
      return Success(null);
    } catch (e) {
      return Error(
        _extractErrorMessage(e),
        errorCode: 'REMOVE_USUARIO_ERROR',
      );
    }
  }

  /// Extrae el mensaje de error de una excepción
  String _extractErrorMessage(Object e) {
    if (e is Exception) {
      final message = e.toString().replaceFirst('Exception: ', '');
      return message;
    }
    return 'Error inesperado: ${e.toString()}';
  }
}

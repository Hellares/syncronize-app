import 'package:injectable/injectable.dart';

import '../../../../core/network/network_info.dart';
import '../../../../core/utils/resource.dart';
import '../../domain/entities/registro_usuario_response.dart';
import '../../domain/entities/usuario.dart';
import '../../domain/entities/usuario_filtros.dart';
import '../../domain/repositories/usuario_repository.dart';
import '../datasources/usuario_remote_datasource.dart';
import '../models/usuario_model.dart';

/// Implementación del repositorio de usuarios
@LazySingleton(as: UsuarioRepository)
class UsuarioRepositoryImpl implements UsuarioRepository {
  final UsuarioRemoteDataSource _remoteDataSource;
  final NetworkInfo _networkInfo;

  UsuarioRepositoryImpl(
    this._remoteDataSource,
    this._networkInfo,
  );

  @override
  Future<Resource<RegistroUsuarioResponse>> registrarUsuario({
    required String empresaId,
    required Map<String, dynamic> data,
  }) async {
    // Verificar conexión a internet
    if (!await _networkInfo.isConnected) {
      return Error(
        'No hay conexión a internet',
        errorCode: 'NETWORK_ERROR',
      );
    }

    try {
      final response = await _remoteDataSource.registrarUsuario(data);
      return Success(response.toEntity());
    } catch (e) {
      final message = e.toString().replaceFirst('Exception: ', '');
      return Error(message);
    }
  }

  @override
  Future<Resource<UsuariosPaginados>> getUsuarios({
    required String empresaId,
    required UsuarioFiltros filtros,
  }) async {
    // Verificar conexión a internet
    if (!await _networkInfo.isConnected) {
      return Error(
        'No hay conexión a internet',
        errorCode: 'NETWORK_ERROR',
      );
    }

    try {
      final responseData = await _remoteDataSource.getUsuarios(
        empresaId: empresaId,
        filtros: filtros,
      );

      // Parsear lista de usuarios
      final List<dynamic> usuariosJson = responseData['data'] as List? ?? [];
      final usuarios = usuariosJson
          .map((e) => UsuarioModel.fromJson(e as Map<String, dynamic>))
          .toList();

      // Parsear metadata de paginación
      final meta = responseData['meta'] as Map<String, dynamic>? ??
          {
            'total': usuarios.length,
            'page': 1,
            'totalPages': 1,
            'hasNext': false,
            'hasPrevious': false,
          };

      final paginado = UsuariosPaginados(
        data: usuarios,
        total: meta['total'] as int? ?? 0,
        page: meta['page'] as int? ?? 1,
        totalPages: meta['totalPages'] as int? ?? 1,
        hasNext: meta['hasNext'] as bool? ?? false,
        hasPrev: meta['hasPrevious'] as bool? ?? false,
      );

      return Success(paginado);
    } catch (e) {
      final message = e.toString().replaceFirst('Exception: ', '');
      return Error(message);
    }
  }

  @override
  Future<Resource<Usuario>> getUsuario({
    required String empresaId,
    required String usuarioId,
  }) async {
    // Verificar conexión a internet
    if (!await _networkInfo.isConnected) {
      return Error(
        'No hay conexión a internet',
        errorCode: 'NETWORK_ERROR',
      );
    }

    try {
      final responseData = await _remoteDataSource.getUsuario(
        empresaId: empresaId,
        usuarioId: usuarioId,
      );

      final usuario = UsuarioModel.fromJson(responseData);
      return Success(usuario.toEntity());
    } catch (e) {
      final message = e.toString().replaceFirst('Exception: ', '');
      return Error(message);
    }
  }

  @override
  Future<Resource<Usuario>> updateUsuario({
    required String empresaId,
    required String usuarioId,
    required Map<String, dynamic> data,
  }) async {
    // Verificar conexión a internet
    if (!await _networkInfo.isConnected) {
      return Error(
        'No hay conexión a internet',
        errorCode: 'NETWORK_ERROR',
      );
    }

    try {
      final responseData = await _remoteDataSource.updateUsuario(
        empresaId: empresaId,
        usuarioId: usuarioId,
        data: data,
      );

      final usuario = UsuarioModel.fromJson(responseData);
      return Success(usuario.toEntity());
    } catch (e) {
      final message = e.toString().replaceFirst('Exception: ', '');
      return Error(message);
    }
  }

  @override
  Future<Resource<void>> deleteUsuario({
    required String empresaId,
    required String usuarioId,
  }) async {
    // Verificar conexión a internet
    if (!await _networkInfo.isConnected) {
      return Error(
        'No hay conexión a internet',
        errorCode: 'NETWORK_ERROR',
      );
    }

    try {
      await _remoteDataSource.deleteUsuario(
        empresaId: empresaId,
        usuarioId: usuarioId,
      );
      return Success(null);
    } catch (e) {
      final message = e.toString().replaceFirst('Exception: ', '');
      return Error(message);
    }
  }
}

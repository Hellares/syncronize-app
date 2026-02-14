import 'package:injectable/injectable.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../../domain/entities/usuario_filtros.dart';
import '../models/registro_usuario_response_model.dart';

/// DataSource remoto para usuarios
///
/// Maneja todas las llamadas HTTP al backend relacionadas con usuarios
@lazySingleton
class UsuarioRemoteDataSource {
  final DioClient _dioClient;

  UsuarioRemoteDataSource(this._dioClient);

  /// Registra un nuevo usuario/empleado o asigna uno existente
  Future<RegistroUsuarioResponseModel> registrarUsuario(
    Map<String, dynamic> data,
  ) async {
    final response = await _dioClient.post(
      '${ApiConstants.usuarios}/registrar',
      data: data,
    );

    return RegistroUsuarioResponseModel.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  /// Obtiene la lista de usuarios con paginación y filtros
  Future<Map<String, dynamic>> getUsuarios({
    required String empresaId,
    required UsuarioFiltros filtros,
  }) async {
    final queryParams = filtros.toQueryParams();

    final response = await _dioClient.get(
      ApiConstants.usuarios,
      queryParameters: queryParams,
    );

    return response.data as Map<String, dynamic>;
  }

  /// Obtiene un usuario específico por ID
  Future<Map<String, dynamic>> getUsuario({
    required String empresaId,
    required String usuarioId,
  }) async {
    final response = await _dioClient.get(
      '${ApiConstants.usuarios}/$usuarioId',
    );

    return response.data as Map<String, dynamic>;
  }

  /// Actualiza un usuario
  Future<Map<String, dynamic>> updateUsuario({
    required String empresaId,
    required String usuarioId,
    required Map<String, dynamic> data,
  }) async {
    final response = await _dioClient.patch(
      '${ApiConstants.usuarios}/$usuarioId',
      data: data,
    );

    return response.data as Map<String, dynamic>;
  }

  /// Elimina (soft delete) un usuario
  Future<void> deleteUsuario({
    required String empresaId,
    required String usuarioId,
  }) async {
    await _dioClient.delete(
      '${ApiConstants.usuarios}/$usuarioId',
    );
  }
}

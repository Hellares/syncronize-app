import 'package:injectable/injectable.dart';
import '../../../../core/network/dio_client.dart';
import '../../../empresa/data/models/sede_model.dart';

/// Data source remoto para operaciones de sede
@lazySingleton
class SedeRemoteDataSource {
  final DioClient _dioClient;

  SedeRemoteDataSource(this._dioClient);

  /// Obtiene todas las sedes de una empresa
  ///
  /// GET /api/empresas/:empresaId/sedes
  Future<List<SedeModel>> getSedes(String empresaId) async {
    final response = await _dioClient.get(
      '/empresas/$empresaId/sedes',
    );

    if (response.data is! List) {
      throw Exception('Respuesta inválida del servidor');
    }

    return (response.data as List)
        .map((json) => SedeModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Obtiene los detalles de una sede específica
  ///
  /// GET /api/empresas/:empresaId/sedes/:sedeId
  Future<SedeModel> getSedeById({
    required String empresaId,
    required String sedeId,
  }) async {
    final response = await _dioClient.get(
      '/empresas/$empresaId/sedes/$sedeId',
    );

    return SedeModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// Crea una nueva sede
  ///
  /// POST /api/empresas/:empresaId/sedes
  Future<SedeModel> createSede({
    required String empresaId,
    required Map<String, dynamic> data,
  }) async {
    final response = await _dioClient.post(
      '/empresas/$empresaId/sedes',
      data: data,
    );

    return SedeModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// Actualiza una sede existente
  ///
  /// PUT /api/empresas/:empresaId/sedes/:sedeId
  Future<SedeModel> updateSede({
    required String empresaId,
    required String sedeId,
    required Map<String, dynamic> data,
  }) async {
    final response = await _dioClient.put(
      '/empresas/$empresaId/sedes/$sedeId',
      data: data,
    );

    return SedeModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// Elimina una sede (soft delete)
  ///
  /// DELETE /api/empresas/:empresaId/sedes/:sedeId
  Future<void> deleteSede({
    required String empresaId,
    required String sedeId,
  }) async {
    await _dioClient.delete(
      '/empresas/$empresaId/sedes/$sedeId',
    );
  }

  /// Obtiene los usuarios asignados a una sede
  ///
  /// GET /api/empresas/:empresaId/sedes/:sedeId/usuarios
  Future<List<Map<String, dynamic>>> getSedeUsuarios({
    required String empresaId,
    required String sedeId,
  }) async {
    final response = await _dioClient.get(
      '/empresas/$empresaId/sedes/$sedeId/usuarios',
    );

    if (response.data is! List) {
      throw Exception('Respuesta inválida del servidor');
    }

    return (response.data as List).cast<Map<String, dynamic>>();
  }

  /// Asigna un usuario a una sede con un rol específico
  ///
  /// POST /api/empresas/:empresaId/sedes/:sedeId/usuarios
  Future<Map<String, dynamic>> assignUsuarioToSede({
    required String empresaId,
    required String sedeId,
    required Map<String, dynamic> data,
  }) async {
    final response = await _dioClient.post(
      '/empresas/$empresaId/sedes/$sedeId/usuarios',
      data: data,
    );

    return response.data as Map<String, dynamic>;
  }

  /// Remueve un usuario de una sede
  ///
  /// DELETE /api/empresas/:empresaId/sedes/:sedeId/usuarios/:usuarioSedeRolId
  Future<void> removeUsuarioFromSede({
    required String empresaId,
    required String sedeId,
    required String usuarioSedeRolId,
  }) async {
    await _dioClient.delete(
      '/empresas/$empresaId/sedes/$sedeId/usuarios/$usuarioSedeRolId',
    );
  }
}

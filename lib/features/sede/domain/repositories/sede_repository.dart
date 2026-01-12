import '../../../../core/utils/resource.dart';
import '../../../empresa/domain/entities/sede.dart';

/// Repository interface para operaciones relacionadas con sedes
abstract class SedeRepository {
  /// Obtiene todas las sedes de una empresa
  Future<Resource<List<Sede>>> getSedes(String empresaId);

  /// Obtiene los detalles de una sede específica
  Future<Resource<Sede>> getSedeById({
    required String empresaId,
    required String sedeId,
  });

  /// Crea una nueva sede
  Future<Resource<Sede>> createSede({
    required String empresaId,
    required Map<String, dynamic> data,
  });

  /// Actualiza una sede existente
  Future<Resource<Sede>> updateSede({
    required String empresaId,
    required String sedeId,
    required Map<String, dynamic> data,
  });

  /// Elimina una sede (soft delete)
  Future<Resource<void>> deleteSede({
    required String empresaId,
    required String sedeId,
  });

  /// Obtiene los usuarios asignados a una sede
  Future<Resource<List<Map<String, dynamic>>>> getSedeUsuarios({
    required String empresaId,
    required String sedeId,
  });

  /// Asigna un usuario a una sede con un rol específico
  Future<Resource<Map<String, dynamic>>> assignUsuarioToSede({
    required String empresaId,
    required String sedeId,
    required Map<String, dynamic> data,
  });

  /// Remueve un usuario de una sede
  Future<Resource<void>> removeUsuarioFromSede({
    required String empresaId,
    required String sedeId,
    required String usuarioSedeRolId,
  });
}

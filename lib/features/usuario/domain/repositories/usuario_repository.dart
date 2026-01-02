import '../../../../core/utils/resource.dart';
import '../entities/registro_usuario_response.dart';
import '../entities/usuario.dart';
import '../entities/usuario_filtros.dart';

/// Interface del repositorio de usuarios
///
/// Define los métodos que deben implementarse para gestionar usuarios
abstract class UsuarioRepository {
  /// Registra un nuevo usuario/empleado o asigna uno existente
  ///
  /// [empresaId] ID de la empresa
  /// [data] Datos del usuario a registrar
  ///
  /// Returns [Resource<RegistroUsuarioResponse>] con el resultado de la operación
  Future<Resource<RegistroUsuarioResponse>> registrarUsuario({
    required String empresaId,
    required Map<String, dynamic> data,
  });

  /// Obtiene la lista de usuarios de una empresa con paginación y filtros
  ///
  /// [empresaId] ID de la empresa
  /// [filtros] Filtros a aplicar en la búsqueda
  ///
  /// Returns [Resource<UsuariosPaginados>] con la lista paginada de usuarios
  Future<Resource<UsuariosPaginados>> getUsuarios({
    required String empresaId,
    required UsuarioFiltros filtros,
  });

  /// Obtiene un usuario específico por su ID
  ///
  /// [empresaId] ID de la empresa
  /// [usuarioId] ID del usuario
  ///
  /// Returns [Resource<Usuario>] con los datos del usuario
  Future<Resource<Usuario>> getUsuario({
    required String empresaId,
    required String usuarioId,
  });

  /// Actualiza los datos de un usuario
  ///
  /// [empresaId] ID de la empresa
  /// [usuarioId] ID del usuario
  /// [data] Datos a actualizar
  ///
  /// Returns [Resource<Usuario>] con el usuario actualizado
  Future<Resource<Usuario>> updateUsuario({
    required String empresaId,
    required String usuarioId,
    required Map<String, dynamic> data,
  });

  /// Elimina (soft delete) un usuario de la empresa
  ///
  /// [empresaId] ID de la empresa
  /// [usuarioId] ID del usuario
  ///
  /// Returns [Resource<void>] indicando éxito o error
  Future<Resource<void>> deleteUsuario({
    required String empresaId,
    required String usuarioId,
  });
}

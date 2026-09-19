import '../../../empresa/data/models/empresa_permissions_model.dart';
import '../../../empresa/domain/entities/empresa_permissions.dart';
import '../../domain/entities/permisos_por_rol.dart';

class PermisosPorRolModel implements PermisosPorRol {
  /// Rol → sus permisos por sí solo (`{canManageOrders: true, ...}`).
  final Map<String, Map<String, dynamic>> roles;

  /// Permiso especial → claves de permiso que enciende por sí solo.
  final Map<String, List<String>> granulares;

  const PermisosPorRolModel({required this.roles, required this.granulares});

  factory PermisosPorRolModel.fromJson(Map<String, dynamic> json) {
    final roles = (json['roles'] as Map<String, dynamic>? ?? const {}).map(
      (rol, permisos) =>
          MapEntry(rol, Map<String, dynamic>.from(permisos as Map)),
    );
    final granulares =
        (json['granulares'] as Map<String, dynamic>? ?? const {}).map(
      (id, claves) => MapEntry(id, List<String>.from(claves as List)),
    );
    return PermisosPorRolModel(roles: roles, granulares: granulares);
  }

  /// El rol OR cada permiso especial. Es exacto porque en el backend toda
  /// regla es una disyunción y los especiales solo SUMAN (lo verifica
  /// `permisos-por-rol.spec.ts`).
  @override
  EmpresaPermissions? paraUsuario(
    String rol,
    Iterable<String> permisosEspeciales,
  ) {
    final base = roles[rol];
    if (base == null) return null;
    final permisos = Map<String, dynamic>.from(base);
    for (final id in permisosEspeciales) {
      for (final clave in granulares[id] ?? const <String>[]) {
        permisos[clave] = true;
      }
    }
    return EmpresaPermissionsModel.fromJson(permisos);
  }
}

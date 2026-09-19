import '../../../empresa/domain/entities/empresa_permissions.dart';

/// Qué permite cada rol y qué suma cada permiso especial
/// (`GET /usuarios/permisos-por-rol`).
///
/// Lo usa la ficha de usuario para ofrecer solo los accesos rápidos y las
/// opciones de menú que ese usuario va a poder ver. Las reglas NO se copian
/// acá: las calcula el backend, que es la única fuente.
abstract class PermisosPorRol {
  /// Permisos efectivos de alguien con [rol] y esos [permisosEspeciales].
  /// Null si el backend no conoce el rol.
  EmpresaPermissions? paraUsuario(
    String rol,
    Iterable<String> permisosEspeciales,
  );
}

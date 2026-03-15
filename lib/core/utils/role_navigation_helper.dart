import '../constants/storage_constants.dart';
import '../storage/local_storage_service.dart';
import '../di/injection_container.dart';

/// Helper para determinar la ruta de navegación según el rol del usuario
class RoleNavigationHelper {
  /// Roles que deben ir al portal de cliente
  static const _clienteRoles = ['CLIENTE'];

  /// Determina la ruta correcta según el rol almacenado en localStorage
  static String getEmpresaRoute() {
    final localStorage = locator<LocalStorageService>();
    final tenantRole = localStorage.getString(StorageConstants.tenantRole);

    if (tenantRole != null && _clienteRoles.contains(tenantRole)) {
      return '/empresa/cliente';
    }
    return '/empresa/dashboard';
  }

  /// Determina la ruta según un rol proporcionado directamente
  static String getRouteForRole(String? role) {
    if (role != null && _clienteRoles.contains(role)) {
      return '/empresa/cliente';
    }
    return '/empresa/dashboard';
  }
}

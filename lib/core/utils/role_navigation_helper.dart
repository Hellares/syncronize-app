import '../constants/storage_constants.dart';
import '../storage/local_storage_service.dart';
import '../di/injection_container.dart';

/// Helper para determinar la ruta de navegación según el rol del usuario
class RoleNavigationHelper {
  /// Mapeo de rol → ruta inicial más relevante
  static const _roleRoutes = <String, String>{
    'CLIENTE': '/empresa/cliente',
    'VENDEDOR': '/empresa/dashboard-vendedor',
    'CAJERO': '/empresa/cola-pos',
    'TECNICO': '/empresa/ordenes',
    'CONTADOR': '/empresa/ventas/analytics',
  };

  /// Determina la ruta correcta según el rol almacenado en localStorage
  static String getEmpresaRoute() {
    final localStorage = locator<LocalStorageService>();
    final tenantRole = localStorage.getString(StorageConstants.tenantRole);
    return getRouteForRole(tenantRole);
  }

  /// Determina la ruta según un rol proporcionado directamente
  static String getRouteForRole(String? role) {
    if (role == null) return '/empresa/dashboard';
    return _roleRoutes[role] ?? '/empresa/dashboard';
  }
}

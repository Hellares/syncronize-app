import '../constants/storage_constants.dart';
import '../storage/local_storage_service.dart';
import '../di/injection_container.dart';

/// Helper para determinar la ruta de navegación según el rol del usuario
class RoleNavigationHelper {
  /// Mapeo de rol → ruta inicial más relevante.
  ///
  /// Nota de diseño: VENDEDOR y CAJERO caen en el **dashboard general**
  /// (`/empresa/dashboard`), que ya filtra los accesos rápidos por sus
  /// permisos y muestra un banner verde "Mi rendimiento" que los lleva
  /// a su dashboard personal con un tap. Esto evita que queden atrapados
  /// en una pantalla específica sin poder volver a la home común.
  ///
  /// Solo roles con una vista 100% dedicada (CLIENTE, TECNICO, CONTADOR)
  /// caen directo en su pantalla porque ahí está toda su operación.
  static const _roleRoutes = <String, String>{
    'CLIENTE': '/empresa/cliente',
    'TECNICO': '/empresa/ordenes',
    'CONTADOR': '/empresa/ventas/analytics',
    // El repartidor vive en su pool de entregas — toda su operación está ahí.
    'REPARTIDOR': '/empresa/delivery',
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

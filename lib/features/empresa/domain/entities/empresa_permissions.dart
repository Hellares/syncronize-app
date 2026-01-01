import 'package:equatable/equatable.dart';

/// Entidad que representa los permisos del usuario en la empresa
class EmpresaPermissions extends Equatable {
  final bool canManageUsers;

  // Productos - Separado en VIEW y MANAGE
  final bool canViewProducts;      // Ver catálogo de productos
  final bool canManageProducts;    // Crear, editar, eliminar productos

  // Servicios - Separado en VIEW y MANAGE
  final bool canViewServices;      // Ver catálogo de servicios
  final bool canManageServices;    // Crear, editar, eliminar servicios

  // Descuentos - Separado en VIEW y MANAGE
  final bool canViewDiscounts;     // Ver políticas de descuento
  final bool canManageDiscounts;   // Crear, editar, eliminar políticas de descuento

  final bool canManageSedes;
  final bool canViewReports;
  final bool canManageInvoices;
  final bool canManageOrders;
  final bool canViewStatistics;
  final bool canManageSettings;
  final bool canManagePaymentMethods;
  final bool canChangePlan;

  const EmpresaPermissions({
    required this.canManageUsers,
    required this.canViewProducts,
    required this.canManageProducts,
    required this.canViewServices,
    required this.canManageServices,
    required this.canViewDiscounts,
    required this.canManageDiscounts,
    required this.canManageSedes,
    required this.canViewReports,
    required this.canManageInvoices,
    required this.canManageOrders,
    required this.canViewStatistics,
    required this.canManageSettings,
    required this.canManagePaymentMethods,
    required this.canChangePlan,
  });

  /// Indica si el usuario es administrador (tiene permisos completos)
  bool get isAdmin => canManageUsers && canManageSettings;

  /// Indica si el usuario puede hacer operaciones de gestión básica
  bool get canManageBasicOperations =>
      canManageProducts || canManageServices || canManageOrders;

  @override
  List<Object?> get props => [
        canManageUsers,
        canViewProducts,
        canManageProducts,
        canViewServices,
        canManageServices,
        canViewDiscounts,
        canManageDiscounts,
        canManageSedes,
        canViewReports,
        canManageInvoices,
        canManageOrders,
        canViewStatistics,
        canManageSettings,
        canManagePaymentMethods,
        canChangePlan,
      ];
}

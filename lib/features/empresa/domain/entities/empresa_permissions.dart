import 'package:equatable/equatable.dart';

/// Entidad que representa los permisos del usuario en la empresa
class EmpresaPermissions extends Equatable {
  // Usuarios - Separado en VIEW y MANAGE
  final bool canViewUsers;         // Ver lista de usuarios
  final bool canManageUsers;       // Crear, editar, eliminar usuarios

  // Productos - Separado en VIEW y MANAGE
  final bool canViewProducts;      // Ver catálogo de productos
  final bool canManageProducts;    // Crear, editar, eliminar productos

  // Servicios - Separado en VIEW y MANAGE
  final bool canViewServices;      // Ver catálogo de servicios
  final bool canManageServices;    // Crear, editar, eliminar servicios

  // Clientes - Separado en VIEW y MANAGE
  final bool canViewClients;       // Ver lista de clientes
  final bool canManageClients;     // Crear, editar, eliminar clientes

  // Descuentos - Separado en VIEW y MANAGE
  final bool canViewDiscounts;     // Ver políticas de descuento
  final bool canManageDiscounts;   // Crear, editar, eliminar políticas de descuento

  // Cotizaciones - Separado en VIEW y MANAGE
  final bool canViewCotizaciones;   // Ver lista de cotizaciones
  final bool canManageCotizaciones; // Crear, editar, eliminar cotizaciones

  // Ventas - Separado en VIEW y MANAGE
  final bool canViewVentas;          // Ver lista de ventas
  final bool canManageVentas;        // Crear, confirmar, anular ventas

  // Devoluciones - Separado en VIEW y MANAGE
  final bool canViewDevoluciones;    // Ver lista de devoluciones
  final bool canManageDevoluciones;  // Crear, aprobar, procesar devoluciones

  // Proveedores - Separado en VIEW y MANAGE
  final bool canViewProveedores;   // Ver catálogo de proveedores
  final bool canManageProveedores; // Crear, editar, eliminar proveedores

  // Compras - Separado en VIEW y MANAGE
  final bool canViewCompras;       // Ver órdenes de compra, recepciones, lotes
  final bool canManageCompras;     // Crear, editar, confirmar compras

  final bool canManageSedes;
  final bool canViewReports;
  final bool canManageInvoices;
  final bool canManageOrders;
  final bool canViewStatistics;
  final bool canManageSettings;
  final bool canManagePaymentMethods;
  final bool canChangePlan;

  const EmpresaPermissions({
    required this.canViewUsers,
    required this.canManageUsers,
    required this.canViewProducts,
    required this.canManageProducts,
    required this.canViewServices,
    required this.canManageServices,
    required this.canViewClients,
    required this.canManageClients,
    required this.canViewDiscounts,
    required this.canManageDiscounts,
    required this.canViewCotizaciones,
    required this.canManageCotizaciones,
    required this.canViewVentas,
    required this.canManageVentas,
    required this.canViewDevoluciones,
    required this.canManageDevoluciones,
    required this.canViewProveedores,
    required this.canManageProveedores,
    required this.canViewCompras,
    required this.canManageCompras,
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
        canViewUsers,
        canManageUsers,
        canViewProducts,
        canManageProducts,
        canViewServices,
        canManageServices,
        canViewClients,
        canManageClients,
        canViewDiscounts,
        canManageDiscounts,
        canViewCotizaciones,
        canManageCotizaciones,
        canViewVentas,
        canManageVentas,
        canViewDevoluciones,
        canManageDevoluciones,
        canViewProveedores,
        canManageProveedores,
        canViewCompras,
        canManageCompras,
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

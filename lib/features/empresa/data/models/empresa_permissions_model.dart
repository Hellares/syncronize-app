import '../../domain/entities/empresa_permissions.dart';

class EmpresaPermissionsModel extends EmpresaPermissions {
  const EmpresaPermissionsModel({
    required super.canManageUsers,
    required super.canViewProducts,
    required super.canManageProducts,
    required super.canViewServices,
    required super.canManageServices,
    required super.canViewDiscounts,
    required super.canManageDiscounts,
    required super.canManageSedes,
    required super.canViewReports,
    required super.canManageInvoices,
    required super.canManageOrders,
    required super.canViewStatistics,
    required super.canManageSettings,
    required super.canManagePaymentMethods,
    required super.canChangePlan,
  });

  factory EmpresaPermissionsModel.fromJson(Map<String, dynamic> json) {
    return EmpresaPermissionsModel(
      canManageUsers: json['canManageUsers'] as bool? ?? false,
      canViewProducts: json['canViewProducts'] as bool? ?? false,
      canManageProducts: json['canManageProducts'] as bool? ?? false,
      canViewServices: json['canViewServices'] as bool? ?? false,
      canManageServices: json['canManageServices'] as bool? ?? false,
      canViewDiscounts: json['canViewDiscounts'] as bool? ?? false,
      canManageDiscounts: json['canManageDiscounts'] as bool? ?? false,
      canManageSedes: json['canManageSedes'] as bool? ?? false,
      canViewReports: json['canViewReports'] as bool? ?? false,
      canManageInvoices: json['canManageInvoices'] as bool? ?? false,
      canManageOrders: json['canManageOrders'] as bool? ?? false,
      canViewStatistics: json['canViewStatistics'] as bool? ?? false,
      canManageSettings: json['canManageSettings'] as bool? ?? false,
      canManagePaymentMethods: json['canManagePaymentMethods'] as bool? ?? false,
      canChangePlan: json['canChangePlan'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'canManageUsers': canManageUsers,
      'canViewProducts': canViewProducts,
      'canManageProducts': canManageProducts,
      'canViewServices': canViewServices,
      'canManageServices': canManageServices,
      'canViewDiscounts': canViewDiscounts,
      'canManageDiscounts': canManageDiscounts,
      'canManageSedes': canManageSedes,
      'canViewReports': canViewReports,
      'canManageInvoices': canManageInvoices,
      'canManageOrders': canManageOrders,
      'canViewStatistics': canViewStatistics,
      'canManageSettings': canManageSettings,
      'canManagePaymentMethods': canManagePaymentMethods,
      'canChangePlan': canChangePlan,
    };
  }

  EmpresaPermissions toEntity() => this;

  factory EmpresaPermissionsModel.fromEntity(EmpresaPermissions entity) {
    return EmpresaPermissionsModel(
      canManageUsers: entity.canManageUsers,
      canViewProducts: entity.canViewProducts,
      canManageProducts: entity.canManageProducts,
      canViewServices: entity.canViewServices,
      canManageServices: entity.canManageServices,
      canViewDiscounts: entity.canViewDiscounts,
      canManageDiscounts: entity.canManageDiscounts,
      canManageSedes: entity.canManageSedes,
      canViewReports: entity.canViewReports,
      canManageInvoices: entity.canManageInvoices,
      canManageOrders: entity.canManageOrders,
      canViewStatistics: entity.canViewStatistics,
      canManageSettings: entity.canManageSettings,
      canManagePaymentMethods: entity.canManagePaymentMethods,
      canChangePlan: entity.canChangePlan,
    );
  }
}

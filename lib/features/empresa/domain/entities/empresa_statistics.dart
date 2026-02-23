import 'package:equatable/equatable.dart';

/// Entidad que representa las estadísticas de la empresa
class EmpresaStatistics extends Equatable {
  final int totalProductos;
  final int totalServicios;
  final int totalUsuarios;
  final int totalSedes;
  final int totalCotizaciones;
  final int totalProveedores;
  final int ordenesPendientes;
  final int? comprobantesMes;
  final double? ingresosMes;

  const EmpresaStatistics({
    required this.totalProductos,
    required this.totalServicios,
    required this.totalUsuarios,
    required this.totalSedes,
    this.totalCotizaciones = 0,
    this.totalProveedores = 0,
    required this.ordenesPendientes,
    this.comprobantesMes,
    this.ingresosMes,
  });

  /// Indica si la empresa tiene inventario (productos o servicios)
  bool get hasInventory => totalProductos > 0 || totalServicios > 0;

  /// Indica si hay órdenes que requieren atención
  bool get hasUnattendedOrders => ordenesPendientes > 0;

  /// Indica si hay múltiples sedes
  bool get isMultiSede => totalSedes > 1;

  @override
  List<Object?> get props => [
        totalProductos,
        totalServicios,
        totalUsuarios,
        totalSedes,
        totalCotizaciones,
        totalProveedores,
        ordenesPendientes,
        comprobantesMes,
        ingresosMes,
      ];
}

/// Info de limite individual del plan
class PlanLimitInfo extends Equatable {
  final int? limite;
  final int actual;
  final int? disponible;

  const PlanLimitInfo({
    this.limite,
    required this.actual,
    this.disponible,
  });

  /// Porcentaje de uso (0.0 a 1.0). null si ilimitado.
  double? get usagePercent {
    if (limite == null || limite == 0) return null;
    return actual / limite!;
  }

  /// True si esta al 80%+ del limite
  bool get isWarning {
    final pct = usagePercent;
    return pct != null && pct >= 0.8 && pct < 1.0;
  }

  /// True si alcanzo o supero el limite
  bool get isAtLimit {
    final pct = usagePercent;
    return pct != null && pct >= 1.0;
  }

  @override
  List<Object?> get props => [limite, actual, disponible];
}

/// Info completa de limites del plan
class PlanLimitsInfo extends Equatable {
  final String? planName;
  final PlanLimitInfo productos;
  final PlanLimitInfo servicios;
  final PlanLimitInfo usuarios;
  final PlanLimitInfo sedes;
  final PlanLimitInfo plantillasAtributos;
  final PlanLimitInfo cotizaciones;

  const PlanLimitsInfo({
    this.planName,
    required this.productos,
    required this.servicios,
    required this.usuarios,
    required this.sedes,
    required this.plantillasAtributos,
    required this.cotizaciones,
  });

  @override
  List<Object?> get props => [
        planName,
        productos,
        servicios,
        usuarios,
        sedes,
        plantillasAtributos,
        cotizaciones,
      ];
}

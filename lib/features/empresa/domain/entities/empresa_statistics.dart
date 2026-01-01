import 'package:equatable/equatable.dart';

/// Entidad que representa las estadísticas de la empresa
class EmpresaStatistics extends Equatable {
  final int totalProductos;
  final int totalServicios;
  final int totalUsuarios;
  final int totalSedes;
  final int ordenesPendientes;
  final int? comprobantesMes;
  final double? ingresosMes;

  const EmpresaStatistics({
    required this.totalProductos,
    required this.totalServicios,
    required this.totalUsuarios,
    required this.totalSedes,
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
        ordenesPendientes,
        comprobantesMes,
        ingresosMes,
      ];
}

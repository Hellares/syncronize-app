import 'package:equatable/equatable.dart';
import 'movimiento_caja.dart';

/// Desglose de egresos por categoría (compra, gasto operativo, etc.).
/// Solo incluye egresos manuales reales — excluye contrapartidas de
/// anulación de venta.
class EgresoPorCategoria extends Equatable {
  final String categoria;
  final String label;
  final double total;
  final int cantidad;

  const EgresoPorCategoria({
    required this.categoria,
    required this.label,
    required this.total,
    required this.cantidad,
  });

  @override
  List<Object?> get props => [categoria, label, total, cantidad];
}

/// Resumen por metodo de pago
class ResumenMetodoPago extends Equatable {
  final MetodoPago metodoPago;
  final double totalIngresos;
  final double totalEgresos;
  final double saldo;

  const ResumenMetodoPago({
    required this.metodoPago,
    required this.totalIngresos,
    required this.totalEgresos,
    required this.saldo,
  });

  @override
  List<Object?> get props => [metodoPago, totalIngresos, totalEgresos, saldo];
}

/// Resumen general de la caja.
///
/// `saldo` = total operado (incluye TODOS los metodos: efectivo + digitales).
/// `saldoEfectivo` = solo lo que esta fisicamente en la gaveta (EFECTIVO + apertura).
/// Mostrar `saldoEfectivo` como "Saldo en Caja"; mostrar `saldo` como
/// "Total operado del dia" o similar para contexto.
class ResumenCaja extends Equatable {
  final double totalIngresos;
  final double totalEgresos;
  final double saldo;
  final double saldoEfectivo;
  final List<ResumenMetodoPago> detalles;

  /// Suma de contrapartidas EGRESO generadas por anulaciones de venta
  /// en esta caja. Es informativo — NO suma a totalEgresos (las
  /// contrapartidas se nacen anuladas y se cancelan con el INGRESO
  /// original). Su efecto sobre el saldo ya está reflejado vía la
  /// reducción de totalIngresos.
  final double egresoAnulacionVenta;
  final int cantidadAnulaciones;

  /// Desglose de Total Egresos por categoría real (compra, gasto, etc.).
  /// Excluye contrapartidas de anulación. Ordenado desc por monto.
  final List<EgresoPorCategoria> egresosPorCategoria;

  const ResumenCaja({
    required this.totalIngresos,
    required this.totalEgresos,
    required this.saldo,
    required this.saldoEfectivo,
    required this.detalles,
    this.egresoAnulacionVenta = 0,
    this.cantidadAnulaciones = 0,
    this.egresosPorCategoria = const [],
  });

  @override
  List<Object?> get props => [
        totalIngresos,
        totalEgresos,
        saldo,
        saldoEfectivo,
        detalles,
        egresoAnulacionVenta,
        cantidadAnulaciones,
        egresosPorCategoria,
      ];
}

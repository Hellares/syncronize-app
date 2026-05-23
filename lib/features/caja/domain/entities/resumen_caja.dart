import 'package:equatable/equatable.dart';
import 'movimiento_caja.dart';

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

  /// Suma de EGRESOs en esta caja generados por anulaciones de venta.
  /// Subconjunto de `totalEgresos`. Útil para que el cajero vea cuánto
  /// dinero "perdió" por anular ventas durante el turno.
  final double egresoAnulacionVenta;
  final int cantidadAnulaciones;

  const ResumenCaja({
    required this.totalIngresos,
    required this.totalEgresos,
    required this.saldo,
    required this.saldoEfectivo,
    required this.detalles,
    this.egresoAnulacionVenta = 0,
    this.cantidadAnulaciones = 0,
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
      ];
}

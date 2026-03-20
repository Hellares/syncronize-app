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

/// Resumen general de la caja
class ResumenCaja extends Equatable {
  final double totalIngresos;
  final double totalEgresos;
  final double saldo;
  final List<ResumenMetodoPago> detalles;

  const ResumenCaja({
    required this.totalIngresos,
    required this.totalEgresos,
    required this.saldo,
    required this.detalles,
  });

  @override
  List<Object?> get props => [totalIngresos, totalEgresos, saldo, detalles];
}

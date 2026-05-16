import 'package:equatable/equatable.dart';
import 'movimiento_caja.dart';

/// Detalle de cierre por metodo de pago (apertura asignada solo a EFECTIVO).
class DetalleCierreMetodo extends Equatable {
  final MetodoPago metodoPago;
  final double apertura;
  final double ingresos;
  final double egresos;
  final double esperado;
  final double conteoFisico;
  final double diferencia;

  const DetalleCierreMetodo({
    required this.metodoPago,
    required this.apertura,
    required this.ingresos,
    required this.egresos,
    required this.esperado,
    required this.conteoFisico,
    required this.diferencia,
  });

  @override
  List<Object?> get props => [
        metodoPago,
        apertura,
        ingresos,
        egresos,
        esperado,
        conteoFisico,
        diferencia,
      ];
}

/// Snapshot del cierre que dispara el cajero al cerrar la caja.
class CierreCaja extends Equatable {
  final double totalIngresos;
  final double totalEgresos;
  final double totalEsperado;
  final double totalConteoFisico;
  final double diferencia;
  final String? observaciones;
  final DateTime? fechaCierre;
  final List<DetalleCierreMetodo> detalles;

  const CierreCaja({
    required this.totalIngresos,
    required this.totalEgresos,
    required this.totalEsperado,
    required this.totalConteoFisico,
    required this.diferencia,
    this.observaciones,
    this.fechaCierre,
    this.detalles = const [],
  });

  @override
  List<Object?> get props => [
        totalIngresos,
        totalEgresos,
        totalEsperado,
        totalConteoFisico,
        diferencia,
        observaciones,
        fechaCierre,
        detalles,
      ];
}

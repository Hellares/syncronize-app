import 'package:equatable/equatable.dart';

class CajaMonitorResumen extends Equatable {
  final int totalCajasAbiertas;
  final double totalIngresos;
  final double totalEgresos;
  final double totalSaldo;

  const CajaMonitorResumen({
    required this.totalCajasAbiertas,
    required this.totalIngresos,
    required this.totalEgresos,
    required this.totalSaldo,
  });

  @override
  List<Object?> get props => [totalCajasAbiertas, totalIngresos, totalEgresos, totalSaldo];
}

class CajaMonitorItem extends Equatable {
  final String id;
  final String codigo;
  final String sedeId;
  final String sedeNombre;
  final String usuarioNombre;
  final double montoApertura;
  final DateTime fechaApertura;
  final double totalIngresos;
  final double totalEgresos;
  final double saldoActual;
  final int totalMovimientos;
  final UltimoMovimiento? ultimoMovimiento;

  const CajaMonitorItem({
    required this.id,
    required this.codigo,
    required this.sedeId,
    required this.sedeNombre,
    required this.usuarioNombre,
    required this.montoApertura,
    required this.fechaApertura,
    required this.totalIngresos,
    required this.totalEgresos,
    required this.saldoActual,
    required this.totalMovimientos,
    this.ultimoMovimiento,
  });

  Duration get tiempoAbierta => DateTime.now().difference(fechaApertura);

  @override
  List<Object?> get props => [id, codigo, saldoActual, totalMovimientos];
}

class UltimoMovimiento extends Equatable {
  final String tipo;
  final String categoria;
  final double monto;
  final String? descripcion;
  final DateTime fechaMovimiento;

  const UltimoMovimiento({
    required this.tipo,
    required this.categoria,
    required this.monto,
    this.descripcion,
    required this.fechaMovimiento,
  });

  @override
  List<Object?> get props => [tipo, monto, fechaMovimiento];
}

class CajaMonitorData extends Equatable {
  final CajaMonitorResumen resumen;
  final List<CajaMonitorItem> cajas;

  const CajaMonitorData({required this.resumen, required this.cajas});

  @override
  List<Object?> get props => [resumen, cajas];
}

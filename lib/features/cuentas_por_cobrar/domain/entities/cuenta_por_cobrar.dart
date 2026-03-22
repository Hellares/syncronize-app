import 'package:equatable/equatable.dart';

class CuentaPorCobrar extends Equatable {
  final String id;
  final String codigo;
  final String nombreCliente;
  final double saldoPendiente;
  final double totalVenta;
  final String estado;
  final int? diasVencimiento;
  final DateTime? fechaVencimiento;
  final int? numeroCuotas;
  final int? cuotasPagadas;
  final ProximaCuota? proximaCuota;
  final double totalMora;

  const CuentaPorCobrar({
    required this.id,
    required this.codigo,
    required this.nombreCliente,
    required this.saldoPendiente,
    required this.totalVenta,
    required this.estado,
    this.diasVencimiento,
    this.fechaVencimiento,
    this.numeroCuotas,
    this.cuotasPagadas,
    this.proximaCuota,
    this.totalMora = 0,
  });

  double get totalConMora => saldoPendiente + totalMora;

  @override
  List<Object?> get props => [id, codigo, nombreCliente, saldoPendiente, totalVenta, estado, numeroCuotas, cuotasPagadas, proximaCuota, totalMora];
}

class ProximaCuota extends Equatable {
  final String id;
  final int numero;
  final double monto;
  final double saldoPendiente;
  final DateTime fechaVencimiento;
  final String estado;
  final double montoMora;

  const ProximaCuota({
    required this.id,
    required this.numero,
    required this.monto,
    required this.saldoPendiente,
    required this.fechaVencimiento,
    required this.estado,
    this.montoMora = 0,
  });

  double get totalConMora => saldoPendiente + montoMora;

  @override
  List<Object?> get props => [id, numero, monto, saldoPendiente, fechaVencimiento, estado, montoMora];
}

class ResumenCuentasCobrar extends Equatable {
  final double totalPendiente;
  final double totalVencido;
  final int cantidadPendientes;
  final int cantidadVencidas;
  final double totalMora;

  const ResumenCuentasCobrar({
    required this.totalPendiente,
    required this.totalVencido,
    required this.cantidadPendientes,
    required this.cantidadVencidas,
    this.totalMora = 0,
  });

  double get totalPorCobrar => totalPendiente + totalVencido;
  double get totalConMora => totalPorCobrar + totalMora;

  @override
  List<Object?> get props => [totalPendiente, totalVencido, cantidadPendientes, cantidadVencidas, totalMora];
}

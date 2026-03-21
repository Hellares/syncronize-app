import 'package:equatable/equatable.dart';

class BancoPrincipal extends Equatable {
  final String nombreBanco;
  final String numeroCuenta;

  const BancoPrincipal({required this.nombreBanco, required this.numeroCuenta});

  @override
  List<Object?> get props => [nombreBanco, numeroCuenta];
}

class CuentaPorPagar extends Equatable {
  final String id;
  final String codigo;
  final String nombreProveedor;
  final double saldoPendiente;
  final double totalCompra;
  final String estado;
  final int? diasVencimiento;
  final DateTime? fechaVencimiento;
  final BancoPrincipal? bancoPrincipal;

  const CuentaPorPagar({
    required this.id,
    required this.codigo,
    required this.nombreProveedor,
    required this.saldoPendiente,
    required this.totalCompra,
    required this.estado,
    this.diasVencimiento,
    this.fechaVencimiento,
    this.bancoPrincipal,
  });

  @override
  List<Object?> get props => [id, codigo, nombreProveedor, saldoPendiente, totalCompra, estado];
}

class ResumenCuentasPagar extends Equatable {
  final double totalPendiente;
  final double totalVencido;
  final int cantidadPendientes;
  final int cantidadVencidas;

  const ResumenCuentasPagar({
    required this.totalPendiente,
    required this.totalVencido,
    required this.cantidadPendientes,
    required this.cantidadVencidas,
  });

  double get totalPorPagar => totalPendiente + totalVencido;

  @override
  List<Object?> get props => [totalPendiente, totalVencido, cantidadPendientes, cantidadVencidas];
}

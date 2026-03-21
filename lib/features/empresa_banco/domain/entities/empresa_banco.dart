import 'package:equatable/equatable.dart';

/// Entity que representa una cuenta bancaria de la empresa
class EmpresaBanco extends Equatable {
  final String id;
  final String nombreBanco;
  final String tipoCuenta;
  final String numeroCuenta;
  final String? cci;
  final String? moneda;
  final String? titular;
  final bool esPrincipal;
  final double saldoActual;
  final bool isActive;

  const EmpresaBanco({
    required this.id,
    required this.nombreBanco,
    required this.tipoCuenta,
    required this.numeroCuenta,
    this.cci,
    this.moneda,
    this.titular,
    this.esPrincipal = false,
    this.saldoActual = 0,
    this.isActive = true,
  });

  @override
  List<Object?> get props => [
        id,
        nombreBanco,
        tipoCuenta,
        numeroCuenta,
        cci,
        moneda,
        titular,
        esPrincipal,
        saldoActual,
        isActive,
      ];
}

/// Entity que representa la conciliación bancaria
class ConciliacionBancaria extends Equatable {
  final ConciliacionCuenta cuenta;
  final ConciliacionPeriodo periodo;
  final ConciliacionMovimientosSistema movimientosSistema;
  final ConciliacionResultado conciliacion;
  final List<ConciliacionMovimiento> movimientos;

  const ConciliacionBancaria({
    required this.cuenta,
    required this.periodo,
    required this.movimientosSistema,
    required this.conciliacion,
    required this.movimientos,
  });

  @override
  List<Object?> get props => [cuenta, periodo, movimientosSistema, conciliacion, movimientos];
}

class ConciliacionCuenta extends Equatable {
  final String id;
  final String nombreBanco;
  final String numeroCuenta;
  final String moneda;
  final double saldoActual;

  const ConciliacionCuenta({
    required this.id,
    required this.nombreBanco,
    required this.numeroCuenta,
    required this.moneda,
    required this.saldoActual,
  });

  @override
  List<Object?> get props => [id, nombreBanco, numeroCuenta, moneda, saldoActual];
}

class ConciliacionPeriodo extends Equatable {
  final String desde;
  final String hasta;

  const ConciliacionPeriodo({
    required this.desde,
    required this.hasta,
  });

  @override
  List<Object?> get props => [desde, hasta];
}

class ConciliacionMovimientosSistema extends Equatable {
  final int cantidad;
  final double totalIngresos;
  final double totalEgresos;
  final double saldoSistema;

  const ConciliacionMovimientosSistema({
    required this.cantidad,
    required this.totalIngresos,
    required this.totalEgresos,
    required this.saldoSistema,
  });

  @override
  List<Object?> get props => [cantidad, totalIngresos, totalEgresos, saldoSistema];
}

class ConciliacionResultado extends Equatable {
  final double saldoBanco;
  final double saldoSistema;
  final double diferencia;
  final bool conciliado;

  const ConciliacionResultado({
    required this.saldoBanco,
    required this.saldoSistema,
    required this.diferencia,
    required this.conciliado,
  });

  @override
  List<Object?> get props => [saldoBanco, saldoSistema, diferencia, conciliado];
}

class ConciliacionMovimiento extends Equatable {
  final String id;
  final String tipo;
  final double monto;
  final String descripcion;
  final String? fechaMovimiento;
  final bool esManual;

  const ConciliacionMovimiento({
    required this.id,
    required this.tipo,
    required this.monto,
    required this.descripcion,
    this.fechaMovimiento,
    this.esManual = false,
  });

  @override
  List<Object?> get props => [id, tipo, monto, descripcion, fechaMovimiento, esManual];
}

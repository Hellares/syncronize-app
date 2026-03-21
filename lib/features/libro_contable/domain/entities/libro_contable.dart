import 'package:equatable/equatable.dart';

class LibroContable extends Equatable {
  final List<MovimientoContable> movimientos;
  final ResumenContable resumen;

  const LibroContable({
    required this.movimientos,
    required this.resumen,
  });

  @override
  List<Object?> get props => [movimientos, resumen];
}

class MovimientoContable extends Equatable {
  final String id;
  final String tipo;
  final String descripcion;
  final double monto;
  final DateTime? fecha;
  final double? saldoAcumulado;
  final String? categoria;
  final String? referencia;

  const MovimientoContable({
    required this.id,
    required this.tipo,
    required this.descripcion,
    required this.monto,
    this.fecha,
    this.saldoAcumulado,
    this.categoria,
    this.referencia,
  });

  @override
  List<Object?> get props => [id, tipo, descripcion, monto, fecha, saldoAcumulado, categoria, referencia];
}

class ResumenContable extends Equatable {
  final double totalIngresos;
  final double totalEgresos;
  final double saldoFinal;

  const ResumenContable({
    required this.totalIngresos,
    required this.totalEgresos,
    required this.saldoFinal,
  });

  @override
  List<Object?> get props => [totalIngresos, totalEgresos, saldoFinal];
}

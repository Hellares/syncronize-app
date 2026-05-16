import 'package:equatable/equatable.dart';

class ReporteEvolucionMes extends Equatable {
  final String periodo; // YYYY-MM
  final double total;
  final Map<String, double> porCategoria;

  const ReporteEvolucionMes({
    required this.periodo,
    required this.total,
    required this.porCategoria,
  });

  @override
  List<Object?> get props => [periodo, total, porCategoria];
}

class ReporteCategoriaMes extends Equatable {
  final String categoriaId;
  final String nombre;
  final double monto;
  final String? icono;
  final String? color;

  const ReporteCategoriaMes({
    required this.categoriaId,
    required this.nombre,
    required this.monto,
    this.icono,
    this.color,
  });

  @override
  List<Object?> get props => [categoriaId, nombre, monto, icono, color];
}

class ReporteMesActual extends Equatable {
  final String periodo;
  final double totalGastado;
  final List<ReporteCategoriaMes> porCategoria;

  const ReporteMesActual({
    required this.periodo,
    required this.totalGastado,
    required this.porCategoria,
  });

  @override
  List<Object?> get props => [periodo, totalGastado, porCategoria];
}

class ReporteGastos extends Equatable {
  final List<ReporteEvolucionMes> evolucionMensual;
  final ReporteMesActual mesActual;

  const ReporteGastos({
    required this.evolucionMensual,
    required this.mesActual,
  });

  @override
  List<Object?> get props => [evolucionMensual, mesActual];
}

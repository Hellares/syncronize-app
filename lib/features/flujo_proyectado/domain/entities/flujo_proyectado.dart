import 'package:equatable/equatable.dart';

class PeriodoFlujo extends Equatable {
  final String label;
  final double cobrosEsperados;
  final double pagosEsperados;
  final double cuotasPrestamos;
  final double saldoProyectado;
  final double? flujoNeto;

  const PeriodoFlujo({
    required this.label,
    required this.cobrosEsperados,
    required this.pagosEsperados,
    required this.cuotasPrestamos,
    required this.saldoProyectado,
    this.flujoNeto,
  });

  @override
  List<Object?> get props => [
        label,
        cobrosEsperados,
        pagosEsperados,
        cuotasPrestamos,
        saldoProyectado,
        flujoNeto,
      ];
}

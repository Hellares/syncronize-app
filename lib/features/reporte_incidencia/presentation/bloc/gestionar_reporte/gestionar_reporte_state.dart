part of 'gestionar_reporte_cubit.dart';

abstract class GestionarReporteState extends Equatable {
  const GestionarReporteState();

  @override
  List<Object?> get props => [];
}

class GestionarReporteInitial extends GestionarReporteState {
  const GestionarReporteInitial();
}

class GestionarReporteLoading extends GestionarReporteState {
  const GestionarReporteLoading();
}

class GestionarReporteSuccess extends GestionarReporteState {
  final ReporteIncidencia reporte;
  final String message;

  const GestionarReporteSuccess(this.reporte, this.message);

  @override
  List<Object?> get props => [reporte, message];
}

class GestionarReporteError extends GestionarReporteState {
  final String message;

  const GestionarReporteError(this.message);

  @override
  List<Object?> get props => [message];
}

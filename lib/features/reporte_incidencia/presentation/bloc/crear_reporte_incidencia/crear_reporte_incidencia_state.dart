part of 'crear_reporte_incidencia_cubit.dart';

abstract class CrearReporteIncidenciaState extends Equatable {
  const CrearReporteIncidenciaState();

  @override
  List<Object?> get props => [];
}

class CrearReporteIncidenciaInitial extends CrearReporteIncidenciaState {
  const CrearReporteIncidenciaInitial();
}

class CrearReporteIncidenciaLoading extends CrearReporteIncidenciaState {
  const CrearReporteIncidenciaLoading();
}

class CrearReporteIncidenciaSuccess extends CrearReporteIncidenciaState {
  final ReporteIncidencia reporte;

  const CrearReporteIncidenciaSuccess(this.reporte);

  @override
  List<Object?> get props => [reporte];
}

class CrearReporteIncidenciaError extends CrearReporteIncidenciaState {
  final String message;

  const CrearReporteIncidenciaError(this.message);

  @override
  List<Object?> get props => [message];
}

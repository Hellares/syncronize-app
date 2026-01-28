part of 'reporte_incidencia_detail_cubit.dart';

abstract class ReporteIncidenciaDetailState extends Equatable {
  const ReporteIncidenciaDetailState();

  @override
  List<Object?> get props => [];
}

class ReporteIncidenciaDetailInitial extends ReporteIncidenciaDetailState {}

class ReporteIncidenciaDetailLoading extends ReporteIncidenciaDetailState {}

class ReporteIncidenciaDetailLoaded extends ReporteIncidenciaDetailState {
  final ReporteIncidencia reporte;

  const ReporteIncidenciaDetailLoaded(this.reporte);

  @override
  List<Object?> get props => [reporte];
}

class ReporteIncidenciaDetailError extends ReporteIncidenciaDetailState {
  final String message;

  const ReporteIncidenciaDetailError(this.message);

  @override
  List<Object?> get props => [message];
}

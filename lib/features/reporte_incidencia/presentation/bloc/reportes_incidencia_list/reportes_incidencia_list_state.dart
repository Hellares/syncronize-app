part of 'reportes_incidencia_list_cubit.dart';

abstract class ReportesIncidenciaListState extends Equatable {
  const ReportesIncidenciaListState();

  @override
  List<Object?> get props => [];
}

class ReportesIncidenciaListInitial extends ReportesIncidenciaListState {}

class ReportesIncidenciaListLoading extends ReportesIncidenciaListState {}

class ReportesIncidenciaListLoaded extends ReportesIncidenciaListState {
  final List<ReporteIncidencia> reportes;

  const ReportesIncidenciaListLoaded(this.reportes);

  @override
  List<Object?> get props => [reportes];
}

class ReportesIncidenciaListError extends ReportesIncidenciaListState {
  final String message;

  const ReportesIncidenciaListError(this.message);

  @override
  List<Object?> get props => [message];
}

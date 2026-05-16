import 'package:equatable/equatable.dart';
import '../../domain/entities/reporte_gastos.dart';

abstract class ReportesGastosState extends Equatable {
  const ReportesGastosState();
  @override
  List<Object?> get props => [];
}

class ReportesGastosInitial extends ReportesGastosState {
  const ReportesGastosInitial();
}

class ReportesGastosLoading extends ReportesGastosState {
  const ReportesGastosLoading();
}

class ReportesGastosLoaded extends ReportesGastosState {
  final ReporteGastos data;
  final int meses;
  const ReportesGastosLoaded(this.data, this.meses);
  @override
  List<Object?> get props => [data, meses];
}

class ReportesGastosError extends ReportesGastosState {
  final String message;
  const ReportesGastosError(this.message);
  @override
  List<Object?> get props => [message];
}

import 'package:equatable/equatable.dart';
import '../../../domain/usecases/get_compra_analytics_usecase.dart';

abstract class CompraAnalyticsState extends Equatable {
  const CompraAnalyticsState();

  @override
  List<Object?> get props => [];
}

class CompraAnalyticsInitial extends CompraAnalyticsState {
  const CompraAnalyticsInitial();
}

class CompraAnalyticsLoading extends CompraAnalyticsState {
  const CompraAnalyticsLoading();
}

class CompraAnalyticsLoaded extends CompraAnalyticsState {
  final CompraAnalyticsData data;
  final String? sedeId;
  final String? fechaInicio;
  final String? fechaFin;
  final String? periodo;

  const CompraAnalyticsLoaded({
    required this.data,
    this.sedeId,
    this.fechaInicio,
    this.fechaFin,
    this.periodo,
  });

  @override
  List<Object?> get props => [data, sedeId, fechaInicio, fechaFin, periodo];
}

class CompraAnalyticsError extends CompraAnalyticsState {
  final String message;

  const CompraAnalyticsError(this.message);

  @override
  List<Object?> get props => [message];
}

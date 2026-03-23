import 'package:equatable/equatable.dart';

import '../../../domain/entities/periodo_planilla.dart';

abstract class PlanillaListState extends Equatable {
  const PlanillaListState();

  @override
  List<Object?> get props => [];
}

class PlanillaListInitial extends PlanillaListState {
  const PlanillaListInitial();
}

class PlanillaListLoading extends PlanillaListState {
  const PlanillaListLoading();
}

class PlanillaListLoaded extends PlanillaListState {
  final List<PeriodoPlanilla> periodos;

  const PlanillaListLoaded(this.periodos);

  @override
  List<Object?> get props => [periodos];
}

class PlanillaListError extends PlanillaListState {
  final String message;

  const PlanillaListError(this.message);

  @override
  List<Object?> get props => [message];
}

class PlanillaListActionSuccess extends PlanillaListState {
  final String message;

  const PlanillaListActionSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

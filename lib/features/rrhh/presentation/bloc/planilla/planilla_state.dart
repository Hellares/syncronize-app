import 'package:equatable/equatable.dart';

import '../../../domain/entities/boleta_pago.dart';
import '../../../domain/entities/periodo_planilla.dart';

abstract class PlanillaState extends Equatable {
  const PlanillaState();

  @override
  List<Object?> get props => [];
}

class PlanillaInitial extends PlanillaState {
  const PlanillaInitial();
}

class PlanillaLoading extends PlanillaState {
  const PlanillaLoading();
}

class PlanillaPeriodosLoaded extends PlanillaState {
  final List<PeriodoPlanilla> periodos;

  const PlanillaPeriodosLoaded(this.periodos);

  @override
  List<Object?> get props => [periodos];
}

class PlanillaPeriodoDetailLoaded extends PlanillaState {
  final PeriodoPlanilla periodo;

  const PlanillaPeriodoDetailLoaded(this.periodo);

  @override
  List<Object?> get props => [periodo];
}

class PlanillaBoletaLoaded extends PlanillaState {
  final BoletaPago boleta;

  const PlanillaBoletaLoaded(this.boleta);

  @override
  List<Object?> get props => [boleta];
}

class PlanillaActionSuccess extends PlanillaState {
  final String message;

  const PlanillaActionSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

class PlanillaError extends PlanillaState {
  final String message;

  const PlanillaError(this.message);

  @override
  List<Object?> get props => [message];
}

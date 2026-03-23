import 'package:equatable/equatable.dart';

import '../../../domain/entities/boleta_pago.dart';

abstract class PlanillaDetailState extends Equatable {
  const PlanillaDetailState();

  @override
  List<Object?> get props => [];
}

class PlanillaDetailInitial extends PlanillaDetailState {
  const PlanillaDetailInitial();
}

class PlanillaDetailLoading extends PlanillaDetailState {
  const PlanillaDetailLoading();
}

class PlanillaDetailLoaded extends PlanillaDetailState {
  final List<BoletaPago> boletas;

  const PlanillaDetailLoaded(this.boletas);

  @override
  List<Object?> get props => [boletas];
}

class PlanillaDetailError extends PlanillaDetailState {
  final String message;

  const PlanillaDetailError(this.message);

  @override
  List<Object?> get props => [message];
}

class PlanillaDetailActionSuccess extends PlanillaDetailState {
  final String message;

  const PlanillaDetailActionSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

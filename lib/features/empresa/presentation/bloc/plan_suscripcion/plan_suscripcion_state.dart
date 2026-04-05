import 'package:equatable/equatable.dart';
import '../../../domain/entities/plan_suscripcion_detail.dart';

abstract class PlanSuscripcionState extends Equatable {
  const PlanSuscripcionState();

  @override
  List<Object?> get props => [];
}

class PlanSuscripcionInitial extends PlanSuscripcionState {
  const PlanSuscripcionInitial();
}

class PlanSuscripcionLoading extends PlanSuscripcionState {
  const PlanSuscripcionLoading();
}

class PlanSuscripcionLoaded extends PlanSuscripcionState {
  final List<PlanSuscripcionDetail> planes;

  const PlanSuscripcionLoaded(this.planes);

  @override
  List<Object?> get props => [planes];
}

class PlanSuscripcionError extends PlanSuscripcionState {
  final String message;

  const PlanSuscripcionError(this.message);

  @override
  List<Object?> get props => [message];
}

class PlanSuscripcionCambiando extends PlanSuscripcionState {
  final List<PlanSuscripcionDetail> planes;

  const PlanSuscripcionCambiando(this.planes);

  @override
  List<Object?> get props => [planes];
}

class PlanSuscripcionCambiado extends PlanSuscripcionState {
  const PlanSuscripcionCambiado();
}

class PlanSuscripcionCambioError extends PlanSuscripcionState {
  final String message;
  final List<PlanSuscripcionDetail> planes;

  const PlanSuscripcionCambioError(this.message, this.planes);

  @override
  List<Object?> get props => [message, planes];
}

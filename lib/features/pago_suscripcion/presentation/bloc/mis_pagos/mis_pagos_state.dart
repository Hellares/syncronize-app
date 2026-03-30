part of 'mis_pagos_cubit.dart';

abstract class MisPagosSuscripcionState extends Equatable {
  const MisPagosSuscripcionState();

  @override
  List<Object?> get props => [];
}

class MisPagosSuscripcionInitial extends MisPagosSuscripcionState {
  const MisPagosSuscripcionInitial();
}

class MisPagosSuscripcionLoading extends MisPagosSuscripcionState {
  const MisPagosSuscripcionLoading();
}

class MisPagosSuscripcionLoaded extends MisPagosSuscripcionState {
  final List<PagoSuscripcion> pagos;

  const MisPagosSuscripcionLoaded({required this.pagos});

  @override
  List<Object?> get props => [pagos];
}

class MisPagosSuscripcionError extends MisPagosSuscripcionState {
  final String message;

  const MisPagosSuscripcionError(this.message);

  @override
  List<Object?> get props => [message];
}

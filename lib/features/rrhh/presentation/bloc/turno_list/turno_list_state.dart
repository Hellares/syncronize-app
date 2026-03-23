import 'package:equatable/equatable.dart';

import '../../../domain/entities/turno.dart';

abstract class TurnoListState extends Equatable {
  const TurnoListState();

  @override
  List<Object?> get props => [];
}

class TurnoListInitial extends TurnoListState {
  const TurnoListInitial();
}

class TurnoListLoading extends TurnoListState {
  const TurnoListLoading();
}

class TurnoListLoaded extends TurnoListState {
  final List<Turno> turnos;

  const TurnoListLoaded(this.turnos);

  @override
  List<Object?> get props => [turnos];
}

class TurnoListError extends TurnoListState {
  final String message;

  const TurnoListError(this.message);

  @override
  List<Object?> get props => [message];
}

class TurnoListActionSuccess extends TurnoListState {
  final String message;

  const TurnoListActionSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

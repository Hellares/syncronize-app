import 'package:equatable/equatable.dart';

import '../../../domain/entities/incidencia.dart';

abstract class IncidenciaState extends Equatable {
  const IncidenciaState();

  @override
  List<Object?> get props => [];
}

class IncidenciaInitial extends IncidenciaState {
  const IncidenciaInitial();
}

class IncidenciaLoading extends IncidenciaState {
  const IncidenciaLoading();
}

class IncidenciaListLoaded extends IncidenciaState {
  final List<Incidencia> incidencias;

  const IncidenciaListLoaded(this.incidencias);

  @override
  List<Object?> get props => [incidencias];
}

class IncidenciaActionSuccess extends IncidenciaState {
  final String message;

  const IncidenciaActionSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

class IncidenciaError extends IncidenciaState {
  final String message;

  const IncidenciaError(this.message);

  @override
  List<Object?> get props => [message];
}

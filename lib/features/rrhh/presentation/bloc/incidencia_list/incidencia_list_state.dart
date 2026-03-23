import 'package:equatable/equatable.dart';

import '../../../domain/entities/incidencia.dart';

abstract class IncidenciaListState extends Equatable {
  const IncidenciaListState();

  @override
  List<Object?> get props => [];
}

class IncidenciaListInitial extends IncidenciaListState {
  const IncidenciaListInitial();
}

class IncidenciaListLoading extends IncidenciaListState {
  const IncidenciaListLoading();
}

class IncidenciaListLoaded extends IncidenciaListState {
  final List<Incidencia> incidencias;
  final Map<String, dynamic>? meta;

  const IncidenciaListLoaded(this.incidencias, {this.meta});

  @override
  List<Object?> get props => [incidencias, meta];
}

class IncidenciaListError extends IncidenciaListState {
  final String message;

  const IncidenciaListError(this.message);

  @override
  List<Object?> get props => [message];
}

class IncidenciaListActionSuccess extends IncidenciaListState {
  final String message;

  const IncidenciaListActionSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

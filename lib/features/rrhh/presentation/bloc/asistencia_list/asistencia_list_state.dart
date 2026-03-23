import 'package:equatable/equatable.dart';

import '../../../domain/entities/asistencia.dart';

abstract class AsistenciaListState extends Equatable {
  const AsistenciaListState();

  @override
  List<Object?> get props => [];
}

class AsistenciaListInitial extends AsistenciaListState {
  const AsistenciaListInitial();
}

class AsistenciaListLoading extends AsistenciaListState {
  const AsistenciaListLoading();
}

class AsistenciaListLoaded extends AsistenciaListState {
  final List<Asistencia> asistencias;
  final Map<String, dynamic>? meta;

  const AsistenciaListLoaded(this.asistencias, {this.meta});

  @override
  List<Object?> get props => [asistencias, meta];
}

class AsistenciaListError extends AsistenciaListState {
  final String message;

  const AsistenciaListError(this.message);

  @override
  List<Object?> get props => [message];
}

class AsistenciaListActionSuccess extends AsistenciaListState {
  final String message;

  const AsistenciaListActionSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

import 'package:equatable/equatable.dart';

import '../../../domain/entities/asistencia.dart';

abstract class AsistenciaState extends Equatable {
  const AsistenciaState();

  @override
  List<Object?> get props => [];
}

class AsistenciaInitial extends AsistenciaState {
  const AsistenciaInitial();
}

class AsistenciaLoading extends AsistenciaState {
  const AsistenciaLoading();
}

class AsistenciaListLoaded extends AsistenciaState {
  final List<Asistencia> asistencias;

  const AsistenciaListLoaded(this.asistencias);

  @override
  List<Object?> get props => [asistencias];
}

class AsistenciaResumenLoaded extends AsistenciaState {
  final AsistenciaResumen resumen;

  const AsistenciaResumenLoaded(this.resumen);

  @override
  List<Object?> get props => [resumen];
}

class AsistenciaActionSuccess extends AsistenciaState {
  final String message;

  const AsistenciaActionSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

class AsistenciaError extends AsistenciaState {
  final String message;

  const AsistenciaError(this.message);

  @override
  List<Object?> get props => [message];
}

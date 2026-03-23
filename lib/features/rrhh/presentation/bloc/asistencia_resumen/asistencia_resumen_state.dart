import 'package:equatable/equatable.dart';

import '../../../domain/entities/asistencia.dart';

abstract class AsistenciaResumenState extends Equatable {
  const AsistenciaResumenState();

  @override
  List<Object?> get props => [];
}

class AsistenciaResumenInitial extends AsistenciaResumenState {
  const AsistenciaResumenInitial();
}

class AsistenciaResumenLoading extends AsistenciaResumenState {
  const AsistenciaResumenLoading();
}

class AsistenciaResumenLoaded extends AsistenciaResumenState {
  final AsistenciaResumen resumen;

  const AsistenciaResumenLoaded(this.resumen);

  @override
  List<Object?> get props => [resumen];
}

class AsistenciaResumenError extends AsistenciaResumenState {
  final String message;

  const AsistenciaResumenError(this.message);

  @override
  List<Object?> get props => [message];
}

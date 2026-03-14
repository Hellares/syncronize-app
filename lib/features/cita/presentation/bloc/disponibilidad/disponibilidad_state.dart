import 'package:equatable/equatable.dart';
import '../../../domain/entities/slot_disponibilidad.dart';

abstract class DisponibilidadState extends Equatable {
  const DisponibilidadState();

  @override
  List<Object?> get props => [];
}

class DisponibilidadInitial extends DisponibilidadState {
  const DisponibilidadInitial();
}

class DisponibilidadLoading extends DisponibilidadState {
  const DisponibilidadLoading();
}

class DisponibilidadLoaded extends DisponibilidadState {
  final DisponibilidadResponse disponibilidad;

  const DisponibilidadLoaded(this.disponibilidad);

  @override
  List<Object?> get props => [disponibilidad];
}

class TecnicosDisponiblesLoaded extends DisponibilidadState {
  final List<TecnicoDisponible> tecnicos;

  const TecnicosDisponiblesLoaded(this.tecnicos);

  @override
  List<Object?> get props => [tecnicos];
}

class DisponibilidadError extends DisponibilidadState {
  final String message;

  const DisponibilidadError(this.message);

  @override
  List<Object?> get props => [message];
}

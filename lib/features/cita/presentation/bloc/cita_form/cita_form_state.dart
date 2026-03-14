import 'package:equatable/equatable.dart';
import '../../../domain/entities/cita.dart';

abstract class CitaFormState extends Equatable {
  const CitaFormState();

  @override
  List<Object?> get props => [];
}

class CitaFormInitial extends CitaFormState {
  const CitaFormInitial();
}

class CitaFormLoading extends CitaFormState {
  const CitaFormLoading();
}

class CitaFormSuccess extends CitaFormState {
  final Cita cita;
  final String mensaje;

  const CitaFormSuccess({required this.cita, this.mensaje = 'Cita creada exitosamente'});

  @override
  List<Object?> get props => [cita, mensaje];
}

class CitaFormError extends CitaFormState {
  final String message;

  const CitaFormError(this.message);

  @override
  List<Object?> get props => [message];
}

class CitaTransitionSuccess extends CitaFormState {
  final Map<String, dynamic> resultado;
  final String mensaje;

  const CitaTransitionSuccess({required this.resultado, required this.mensaje});

  @override
  List<Object?> get props => [resultado, mensaje];
}

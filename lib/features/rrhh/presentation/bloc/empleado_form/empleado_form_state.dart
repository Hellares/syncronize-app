import 'package:equatable/equatable.dart';

import '../../../domain/entities/empleado.dart';

abstract class EmpleadoFormState extends Equatable {
  const EmpleadoFormState();

  @override
  List<Object?> get props => [];
}

class EmpleadoFormInitial extends EmpleadoFormState {
  const EmpleadoFormInitial();
}

class EmpleadoFormSubmitting extends EmpleadoFormState {
  const EmpleadoFormSubmitting();
}

class EmpleadoFormSuccess extends EmpleadoFormState {
  final Empleado empleado;

  const EmpleadoFormSuccess(this.empleado);

  @override
  List<Object?> get props => [empleado];
}

class EmpleadoFormError extends EmpleadoFormState {
  final String message;

  const EmpleadoFormError(this.message);

  @override
  List<Object?> get props => [message];
}

import 'package:equatable/equatable.dart';

import '../../../domain/entities/empleado.dart';

abstract class EmpleadoDetailState extends Equatable {
  const EmpleadoDetailState();

  @override
  List<Object?> get props => [];
}

class EmpleadoDetailInitial extends EmpleadoDetailState {
  const EmpleadoDetailInitial();
}

class EmpleadoDetailLoading extends EmpleadoDetailState {
  const EmpleadoDetailLoading();
}

class EmpleadoDetailLoaded extends EmpleadoDetailState {
  final Empleado empleado;

  const EmpleadoDetailLoaded(this.empleado);

  @override
  List<Object?> get props => [empleado];
}

class EmpleadoDetailError extends EmpleadoDetailState {
  final String message;

  const EmpleadoDetailError(this.message);

  @override
  List<Object?> get props => [message];
}

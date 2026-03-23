import 'package:equatable/equatable.dart';

import '../../../domain/entities/empleado.dart';

abstract class EmpleadoListState extends Equatable {
  const EmpleadoListState();

  @override
  List<Object?> get props => [];
}

class EmpleadoListInitial extends EmpleadoListState {
  const EmpleadoListInitial();
}

class EmpleadoListLoading extends EmpleadoListState {
  const EmpleadoListLoading();
}

class EmpleadoListLoaded extends EmpleadoListState {
  final List<Empleado> empleados;
  final Map<String, dynamic>? meta;

  const EmpleadoListLoaded(this.empleados, {this.meta});

  @override
  List<Object?> get props => [empleados, meta];
}

class EmpleadoListError extends EmpleadoListState {
  final String message;

  const EmpleadoListError(this.message);

  @override
  List<Object?> get props => [message];
}

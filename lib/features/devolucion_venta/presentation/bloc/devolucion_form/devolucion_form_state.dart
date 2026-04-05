import 'package:equatable/equatable.dart';
import '../../../domain/entities/devolucion_venta.dart';

abstract class DevolucionFormState extends Equatable {
  const DevolucionFormState();
  @override
  List<Object?> get props => [];
}

class DevolucionFormInitial extends DevolucionFormState {
  const DevolucionFormInitial();
}

class DevolucionFormLoading extends DevolucionFormState {
  const DevolucionFormLoading();
}

class DevolucionFormSuccess extends DevolucionFormState {
  final DevolucionVenta devolucion;
  final String message;
  const DevolucionFormSuccess({required this.devolucion, required this.message});
  @override
  List<Object?> get props => [devolucion, message];
}

class DevolucionFormError extends DevolucionFormState {
  final String message;
  const DevolucionFormError(this.message);
  @override
  List<Object?> get props => [message];
}

class DevolucionEstadoUpdated extends DevolucionFormState {
  final DevolucionVenta devolucion;
  final String message;
  const DevolucionEstadoUpdated({required this.devolucion, required this.message});
  @override
  List<Object?> get props => [devolucion, message];
}

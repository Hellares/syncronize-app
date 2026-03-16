import 'package:equatable/equatable.dart';
import '../../../domain/entities/devolucion_venta.dart';

abstract class DevolucionListState extends Equatable {
  const DevolucionListState();
  @override
  List<Object?> get props => [];
}

class DevolucionListInitial extends DevolucionListState {
  const DevolucionListInitial();
}

class DevolucionListLoading extends DevolucionListState {
  const DevolucionListLoading();
}

class DevolucionListLoaded extends DevolucionListState {
  final List<DevolucionVenta> devoluciones;
  final EstadoDevolucion? filtroEstado;

  const DevolucionListLoaded({required this.devoluciones, this.filtroEstado});

  @override
  List<Object?> get props => [devoluciones, filtroEstado];
}

class DevolucionListError extends DevolucionListState {
  final String message;
  const DevolucionListError(this.message);
  @override
  List<Object?> get props => [message];
}

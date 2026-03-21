import 'package:equatable/equatable.dart';
import '../../domain/entities/inventario.dart';

abstract class InventarioDetailState extends Equatable {
  const InventarioDetailState();

  @override
  List<Object?> get props => [];
}

class InventarioDetailInitial extends InventarioDetailState {
  const InventarioDetailInitial();
}

class InventarioDetailLoading extends InventarioDetailState {
  const InventarioDetailLoading();
}

class InventarioDetailLoaded extends InventarioDetailState {
  final Inventario inventario;

  const InventarioDetailLoaded(this.inventario);

  @override
  List<Object?> get props => [inventario];
}

class InventarioDetailError extends InventarioDetailState {
  final String message;

  const InventarioDetailError(this.message);

  @override
  List<Object?> get props => [message];
}

class InventarioDetailActionLoading extends InventarioDetailState {
  final Inventario inventario;
  final String actionMessage;

  const InventarioDetailActionLoading(this.inventario, this.actionMessage);

  @override
  List<Object?> get props => [inventario, actionMessage];
}

class InventarioDetailActionSuccess extends InventarioDetailState {
  final Inventario inventario;
  final String successMessage;

  const InventarioDetailActionSuccess(this.inventario, this.successMessage);

  @override
  List<Object?> get props => [inventario, successMessage];
}

class InventarioDetailActionError extends InventarioDetailState {
  final Inventario inventario;
  final String errorMessage;

  const InventarioDetailActionError(this.inventario, this.errorMessage);

  @override
  List<Object?> get props => [inventario, errorMessage];
}

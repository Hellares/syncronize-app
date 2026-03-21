import 'package:equatable/equatable.dart';
import '../../domain/entities/inventario.dart';

abstract class InventarioListState extends Equatable {
  const InventarioListState();

  @override
  List<Object?> get props => [];
}

class InventarioListInitial extends InventarioListState {
  const InventarioListInitial();
}

class InventarioListLoading extends InventarioListState {
  const InventarioListLoading();
}

class InventarioListLoaded extends InventarioListState {
  final List<Inventario> inventarios;

  const InventarioListLoaded(this.inventarios);

  @override
  List<Object?> get props => [inventarios];
}

class InventarioListError extends InventarioListState {
  final String message;

  const InventarioListError(this.message);

  @override
  List<Object?> get props => [message];
}

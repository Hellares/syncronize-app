import 'package:equatable/equatable.dart';
import '../../../domain/entities/orden_compra.dart';

abstract class OrdenCompraFormState extends Equatable {
  const OrdenCompraFormState();

  @override
  List<Object?> get props => [];
}

class OrdenCompraFormInitial extends OrdenCompraFormState {
  const OrdenCompraFormInitial();
}

class OrdenCompraFormLoading extends OrdenCompraFormState {
  const OrdenCompraFormLoading();
}

class OrdenCompraFormSuccess extends OrdenCompraFormState {
  final OrdenCompra ordenCompra;
  final bool isUpdate;

  const OrdenCompraFormSuccess(this.ordenCompra, {this.isUpdate = false});

  @override
  List<Object?> get props => [ordenCompra, isUpdate];
}

class OrdenCompraFormError extends OrdenCompraFormState {
  final String message;

  const OrdenCompraFormError(this.message);

  @override
  List<Object?> get props => [message];
}

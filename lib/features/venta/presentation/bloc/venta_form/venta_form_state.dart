import 'package:equatable/equatable.dart';
import '../../../domain/entities/venta.dart';

abstract class VentaFormState extends Equatable {
  const VentaFormState();

  @override
  List<Object?> get props => [];
}

class VentaFormInitial extends VentaFormState {
  const VentaFormInitial();
}

class VentaFormLoading extends VentaFormState {
  const VentaFormLoading();
}

class VentaFormSuccess extends VentaFormState {
  final Venta venta;
  final String message;

  const VentaFormSuccess({required this.venta, required this.message});

  @override
  List<Object?> get props => [venta, message];
}

class VentaFormError extends VentaFormState {
  final String message;

  const VentaFormError(this.message);

  @override
  List<Object?> get props => [message];
}

class VentaConfirmada extends VentaFormState {
  final Venta venta;

  const VentaConfirmada(this.venta);

  @override
  List<Object?> get props => [venta];
}

class VentaPagoRegistrado extends VentaFormState {
  final Venta venta;

  const VentaPagoRegistrado(this.venta);

  @override
  List<Object?> get props => [venta];
}

class VentaAnulada extends VentaFormState {
  final Venta venta;

  const VentaAnulada(this.venta);

  @override
  List<Object?> get props => [venta];
}

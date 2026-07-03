import 'package:equatable/equatable.dart';
import '../../domain/entities/checkout.dart';

abstract class CheckoutState extends Equatable {
  const CheckoutState();
  @override
  List<Object?> get props => [];
}

class CheckoutInitial extends CheckoutState {
  const CheckoutInitial();
}

class CheckoutLoadingEnvio extends CheckoutState {
  const CheckoutLoadingEnvio();
}

class CheckoutReady extends CheckoutState {
  final Map<String, OpcionesEnvio> opcionesPorEmpresa;

  const CheckoutReady({required this.opcionesPorEmpresa});

  @override
  List<Object?> get props => [opcionesPorEmpresa];
}

class CheckoutConfirmando extends CheckoutState {
  final Map<String, OpcionesEnvio> opcionesPorEmpresa;

  const CheckoutConfirmando({required this.opcionesPorEmpresa});

  @override
  List<Object?> get props => [opcionesPorEmpresa];
}

class CheckoutExito extends CheckoutState {
  final List<String> codigos;
  final List<String> pedidoIds;

  const CheckoutExito({required this.codigos, this.pedidoIds = const []});

  @override
  List<Object?> get props => [codigos, pedidoIds];
}

class CheckoutError extends CheckoutState {
  final String message;
  final Map<String, OpcionesEnvio>? opcionesPorEmpresa;

  const CheckoutError(this.message, {this.opcionesPorEmpresa});

  @override
  List<Object?> get props => [message, opcionesPorEmpresa];
}

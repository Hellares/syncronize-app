part of 'pedido_action_cubit.dart';

abstract class PedidoActionState extends Equatable {
  const PedidoActionState();

  @override
  List<Object?> get props => [];
}

class PedidoActionInitial extends PedidoActionState {
  const PedidoActionInitial();
}

class PedidoActionLoading extends PedidoActionState {
  const PedidoActionLoading();
}

class PedidoActionSuccess extends PedidoActionState {
  final String message;

  const PedidoActionSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

class PedidoActionError extends PedidoActionState {
  final String message;

  const PedidoActionError(this.message);

  @override
  List<Object?> get props => [message];
}

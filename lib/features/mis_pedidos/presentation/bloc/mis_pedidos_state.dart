part of 'mis_pedidos_cubit.dart';

abstract class MisPedidosState extends Equatable {
  const MisPedidosState();

  @override
  List<Object?> get props => [];
}

class MisPedidosInitial extends MisPedidosState {
  const MisPedidosInitial();
}

class MisPedidosLoading extends MisPedidosState {
  const MisPedidosLoading();
}

class MisPedidosLoaded extends MisPedidosState {
  final List<PedidoMarketplace> pedidos;
  final EstadoPedidoMarketplace? filtroEstado;

  const MisPedidosLoaded({
    required this.pedidos,
    this.filtroEstado,
  });

  @override
  List<Object?> get props => [pedidos, filtroEstado];
}

class MisPedidosError extends MisPedidosState {
  final String message;

  const MisPedidosError(this.message);

  @override
  List<Object?> get props => [message];
}

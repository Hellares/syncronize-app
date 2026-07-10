part of 'mis_premios_cubit.dart';

abstract class MisPremiosState extends Equatable {
  const MisPremiosState();
  @override
  List<Object?> get props => [];
}

class MisPremiosLoading extends MisPremiosState {
  const MisPremiosLoading();
}

class MisPremiosLoaded extends MisPremiosState {
  final List<PremioCliente> premios;
  const MisPremiosLoaded(this.premios);

  @override
  List<Object?> get props => [premios];
}

class MisPremiosError extends MisPremiosState {
  final String message;
  const MisPremiosError(this.message);

  @override
  List<Object?> get props => [message];
}

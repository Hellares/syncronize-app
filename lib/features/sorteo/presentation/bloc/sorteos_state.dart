part of 'sorteos_cubit.dart';

abstract class SorteosState extends Equatable {
  const SorteosState();
  @override
  List<Object?> get props => [];
}

class SorteosInitial extends SorteosState {
  const SorteosInitial();
}

class SorteosLoading extends SorteosState {
  const SorteosLoading();
}

class SorteosLoaded extends SorteosState {
  final List<Sorteo> sorteos;
  final EstadoSorteo? filtro;

  const SorteosLoaded({required this.sorteos, this.filtro});

  @override
  List<Object?> get props => [sorteos, filtro];
}

class SorteosError extends SorteosState {
  final String message;
  const SorteosError(this.message);

  @override
  List<Object?> get props => [message];
}

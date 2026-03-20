part of 'carrito_cubit.dart';

abstract class CarritoState extends Equatable {
  const CarritoState();

  @override
  List<Object?> get props => [];
}

class CarritoInitial extends CarritoState {
  const CarritoInitial();
}

class CarritoLoading extends CarritoState {
  const CarritoLoading();
}

class CarritoLoaded extends CarritoState {
  final Carrito carrito;

  const CarritoLoaded(this.carrito);

  @override
  List<Object?> get props => [carrito];
}

class CarritoError extends CarritoState {
  final String message;

  const CarritoError(this.message);

  @override
  List<Object?> get props => [message];
}

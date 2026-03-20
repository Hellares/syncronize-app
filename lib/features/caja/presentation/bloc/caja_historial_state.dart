import 'package:equatable/equatable.dart';
import '../../domain/entities/caja.dart';

abstract class CajaHistorialState extends Equatable {
  const CajaHistorialState();

  @override
  List<Object?> get props => [];
}

class CajaHistorialInitial extends CajaHistorialState {
  const CajaHistorialInitial();
}

class CajaHistorialLoading extends CajaHistorialState {
  const CajaHistorialLoading();
}

class CajaHistorialLoaded extends CajaHistorialState {
  final List<Caja> cajas;

  const CajaHistorialLoaded(this.cajas);

  @override
  List<Object?> get props => [cajas];
}

class CajaHistorialError extends CajaHistorialState {
  final String message;

  const CajaHistorialError(this.message);

  @override
  List<Object?> get props => [message];
}

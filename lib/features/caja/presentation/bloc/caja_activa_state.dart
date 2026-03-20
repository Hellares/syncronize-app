import 'package:equatable/equatable.dart';
import '../../domain/entities/caja.dart';

abstract class CajaActivaState extends Equatable {
  const CajaActivaState();

  @override
  List<Object?> get props => [];
}

class CajaActivaInitial extends CajaActivaState {
  const CajaActivaInitial();
}

class CajaActivaLoading extends CajaActivaState {
  const CajaActivaLoading();
}

class CajaActivaAbierta extends CajaActivaState {
  final Caja caja;

  const CajaActivaAbierta(this.caja);

  @override
  List<Object?> get props => [caja];
}

class CajaActivaSinCaja extends CajaActivaState {
  const CajaActivaSinCaja();
}

class CajaActivaError extends CajaActivaState {
  final String message;

  const CajaActivaError(this.message);

  @override
  List<Object?> get props => [message];
}

import 'package:equatable/equatable.dart';
import '../../domain/entities/flujo_proyectado.dart';

abstract class FlujoProyectadoState extends Equatable {
  const FlujoProyectadoState();

  @override
  List<Object?> get props => [];
}

class FlujoProyectadoInitial extends FlujoProyectadoState {
  const FlujoProyectadoInitial();
}

class FlujoProyectadoLoading extends FlujoProyectadoState {
  const FlujoProyectadoLoading();
}

class FlujoProyectadoLoaded extends FlujoProyectadoState {
  final List<PeriodoFlujo> periodos;

  const FlujoProyectadoLoaded({required this.periodos});

  @override
  List<Object?> get props => [periodos];
}

class FlujoProyectadoError extends FlujoProyectadoState {
  final String message;

  const FlujoProyectadoError(this.message);

  @override
  List<Object?> get props => [message];
}

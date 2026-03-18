import 'package:equatable/equatable.dart';
import '../../../domain/entities/cotizacion_pos.dart';

abstract class ColaPosState extends Equatable {
  const ColaPosState();

  @override
  List<Object?> get props => [];
}

class ColaPosInitial extends ColaPosState {
  const ColaPosInitial();
}

class ColaPosLoading extends ColaPosState {
  const ColaPosLoading();
}

class ColaPosLoaded extends ColaPosState {
  final List<CotizacionPOS> cotizaciones;

  const ColaPosLoaded({required this.cotizaciones});

  @override
  List<Object?> get props => [cotizaciones];
}

class ColaPosError extends ColaPosState {
  final String message;

  const ColaPosError(this.message);

  @override
  List<Object?> get props => [message];
}

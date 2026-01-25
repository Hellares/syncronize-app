import 'package:equatable/equatable.dart';
import '../../../domain/entities/transferencia_stock.dart';

abstract class CrearTransferenciaState extends Equatable {
  const CrearTransferenciaState();

  @override
  List<Object?> get props => [];
}

class CrearTransferenciaInitial extends CrearTransferenciaState {
  const CrearTransferenciaInitial();
}

class CrearTransferenciaProcessing extends CrearTransferenciaState {
  const CrearTransferenciaProcessing();
}

class CrearTransferenciaSuccess extends CrearTransferenciaState {
  final TransferenciaStock transferencia;
  final String message;

  const CrearTransferenciaSuccess(this.transferencia, this.message);

  @override
  List<Object?> get props => [transferencia, message];
}

class CrearTransferenciaError extends CrearTransferenciaState {
  final String message;
  final String? errorCode;

  const CrearTransferenciaError(this.message, {this.errorCode});

  @override
  List<Object?> get props => [message, errorCode];
}

class CrearTransferenciaMultipleSuccess extends CrearTransferenciaState {
  final TransferenciaStock transferencia;
  final String mensaje;

  const CrearTransferenciaMultipleSuccess({
    required this.transferencia,
    required this.mensaje,
  });

  @override
  List<Object?> get props => [transferencia, mensaje];
}

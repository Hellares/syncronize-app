import 'package:equatable/equatable.dart';
import '../../../domain/entities/transferencia_stock.dart';

abstract class GestionarTransferenciaState extends Equatable {
  const GestionarTransferenciaState();

  @override
  List<Object?> get props => [];
}

class GestionarTransferenciaInitial extends GestionarTransferenciaState {
  const GestionarTransferenciaInitial();
}

class GestionarTransferenciaProcessing extends GestionarTransferenciaState {
  final String action;

  const GestionarTransferenciaProcessing(this.action);

  @override
  List<Object?> get props => [action];
}

class GestionarTransferenciaSuccess extends GestionarTransferenciaState {
  final TransferenciaStock transferencia;
  final String message;

  const GestionarTransferenciaSuccess(this.transferencia, this.message);

  @override
  List<Object?> get props => [transferencia, message];
}

class GestionarTransferenciaError extends GestionarTransferenciaState {
  final String message;
  final String? errorCode;

  const GestionarTransferenciaError(this.message, {this.errorCode});

  @override
  List<Object?> get props => [message, errorCode];
}

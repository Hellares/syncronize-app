import 'package:equatable/equatable.dart';

abstract class RecibirTransferenciaIncidenciasState extends Equatable {
  const RecibirTransferenciaIncidenciasState();

  @override
  List<Object?> get props => [];
}

class RecibirTransferenciaIncidenciasInitial
    extends RecibirTransferenciaIncidenciasState {
  const RecibirTransferenciaIncidenciasInitial();
}

class RecibirTransferenciaIncidenciasProcessing
    extends RecibirTransferenciaIncidenciasState {
  const RecibirTransferenciaIncidenciasProcessing();
}

class RecibirTransferenciaIncidenciasSuccess
    extends RecibirTransferenciaIncidenciasState {
  final Map<String, dynamic> transferencia;
  final String message;

  const RecibirTransferenciaIncidenciasSuccess({
    required this.transferencia,
    this.message = 'Transferencia recibida exitosamente',
  });

  @override
  List<Object?> get props => [transferencia, message];
}

class RecibirTransferenciaIncidenciasError
    extends RecibirTransferenciaIncidenciasState {
  final String message;
  final String? errorCode;

  const RecibirTransferenciaIncidenciasError(
    this.message, {
    this.errorCode,
  });

  @override
  List<Object?> get props => [message, errorCode];
}

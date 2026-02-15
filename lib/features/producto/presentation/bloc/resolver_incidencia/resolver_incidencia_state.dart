import 'package:equatable/equatable.dart';
import '../../../domain/entities/transferencia_incidencia.dart';

abstract class ResolverIncidenciaState extends Equatable {
  const ResolverIncidenciaState();

  @override
  List<Object?> get props => [];
}

class ResolverIncidenciaInitial extends ResolverIncidenciaState {
  const ResolverIncidenciaInitial();
}

class ResolverIncidenciaProcessing extends ResolverIncidenciaState {
  const ResolverIncidenciaProcessing();
}

class ResolverIncidenciaSuccess extends ResolverIncidenciaState {
  final TransferenciaIncidencia incidenciaResuelta;
  final String message;

  const ResolverIncidenciaSuccess({
    required this.incidenciaResuelta,
    required this.message,
  });

  @override
  List<Object?> get props => [incidenciaResuelta, message];
}

class ResolverIncidenciaError extends ResolverIncidenciaState {
  final String message;
  final String? errorCode;

  const ResolverIncidenciaError(
    this.message, {
    this.errorCode,
  });

  @override
  List<Object?> get props => [message, errorCode];
}

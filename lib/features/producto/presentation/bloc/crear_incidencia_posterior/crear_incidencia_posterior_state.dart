import 'package:equatable/equatable.dart';

/// Estados para la creación de incidencias posteriores
abstract class CrearIncidenciaPosteriorState extends Equatable {
  const CrearIncidenciaPosteriorState();

  @override
  List<Object?> get props => [];
}

/// Estado inicial
class CrearIncidenciaPosteriorInitial extends CrearIncidenciaPosteriorState {
  const CrearIncidenciaPosteriorInitial();
}

/// Procesando (subiendo evidencias y creando incidencia)
class CrearIncidenciaPosteriorProcessing extends CrearIncidenciaPosteriorState {
  final double progress;
  final String? message;

  const CrearIncidenciaPosteriorProcessing({
    this.progress = 0.0,
    this.message,
  });

  @override
  List<Object?> get props => [progress, message];
}

/// Éxito al crear la incidencia
class CrearIncidenciaPosteriorSuccess extends CrearIncidenciaPosteriorState {
  final String message;
  final int evidenciasSubidas;

  const CrearIncidenciaPosteriorSuccess({
    required this.message,
    this.evidenciasSubidas = 0,
  });

  @override
  List<Object?> get props => [message, evidenciasSubidas];
}

/// Error al crear la incidencia
class CrearIncidenciaPosteriorError extends CrearIncidenciaPosteriorState {
  final String message;
  final String? errorCode;

  const CrearIncidenciaPosteriorError(
    this.message, {
    this.errorCode,
  });

  @override
  List<Object?> get props => [message, errorCode];
}

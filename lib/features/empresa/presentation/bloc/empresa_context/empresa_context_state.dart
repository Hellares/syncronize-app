import 'package:equatable/equatable.dart';
import '../../../domain/entities/empresa_context.dart';

/// Estados del contexto de empresa
abstract class EmpresaContextState extends Equatable {
  const EmpresaContextState();

  @override
  List<Object?> get props => [];
}

/// Estado inicial
class EmpresaContextInitial extends EmpresaContextState {
  const EmpresaContextInitial();
}

/// Estado de carga
class EmpresaContextLoading extends EmpresaContextState {
  const EmpresaContextLoading();
}

/// Estado de éxito con el contexto cargado
class EmpresaContextLoaded extends EmpresaContextState {
  final EmpresaContext context;

  const EmpresaContextLoaded(this.context);

  @override
  List<Object?> get props => [context];
}

/// Estado de error
class EmpresaContextError extends EmpresaContextState {
  final String message;
  final String? errorCode;

  const EmpresaContextError(this.message, {this.errorCode});

  @override
  List<Object?> get props => [message, errorCode];
}

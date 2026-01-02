import 'package:equatable/equatable.dart';
import '../../../domain/entities/registro_usuario_response.dart';

/// Estados del cubit de formulario de usuario
abstract class UsuarioFormState extends Equatable {
  const UsuarioFormState();

  @override
  List<Object?> get props => [];
}

/// Estado inicial
class UsuarioFormInitial extends UsuarioFormState {
  const UsuarioFormInitial();
}

/// Estado de envío del formulario
class UsuarioFormSubmitting extends UsuarioFormState {
  const UsuarioFormSubmitting();
}

/// Estado de éxito al enviar el formulario
class UsuarioFormSuccess extends UsuarioFormState {
  final RegistroUsuarioResponse response;

  const UsuarioFormSuccess(this.response);

  @override
  List<Object?> get props => [response];
}

/// Estado de error al enviar el formulario
class UsuarioFormError extends UsuarioFormState {
  final String message;

  const UsuarioFormError(this.message);

  @override
  List<Object?> get props => [message];
}

import 'package:equatable/equatable.dart';
import '../../../domain/entities/registro_cliente_response.dart';

/// Estados para el formulario de cliente
abstract class ClienteFormState extends Equatable {
  const ClienteFormState();

  @override
  List<Object?> get props => [];
}

/// Estado inicial
class ClienteFormInitial extends ClienteFormState {
  const ClienteFormInitial();
}

/// Estado de carga (enviando formulario)
class ClienteFormLoading extends ClienteFormState {
  const ClienteFormLoading();
}

/// Estado de éxito
class ClienteFormSuccess extends ClienteFormState {
  final RegistroClienteResponse response;

  const ClienteFormSuccess(this.response);

  @override
  List<Object?> get props => [response];
}

/// Estado de error
class ClienteFormError extends ClienteFormState {
  final String message;

  const ClienteFormError(this.message);

  @override
  List<Object?> get props => [message];
}

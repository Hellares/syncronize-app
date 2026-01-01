part of 'auth_bloc.dart';

/// Eventos del AuthBloc
abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

/// Evento para verificar el estado de autenticación
class CheckAuthStatusEvent extends AuthEvent {
  final User? user;

  const CheckAuthStatusEvent({this.user});

  @override
  List<Object?> get props => [user];
}

/// Evento cuando un usuario inicia sesión exitosamente
class UserLoggedInEvent extends AuthEvent {
  final User user;

  const UserLoggedInEvent({required this.user});

  @override
  List<Object> get props => [user];
}

/// Evento para cerrar sesión
class LogoutRequestedEvent extends AuthEvent {
  const LogoutRequestedEvent();
}

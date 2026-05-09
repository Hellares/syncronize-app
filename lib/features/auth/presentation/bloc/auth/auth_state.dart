part of 'auth_bloc.dart';

/// Estados del AuthBloc
abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

/// Estado inicial
class AuthInitial extends AuthState {}

/// Estado de carga
class AuthLoading extends AuthState {}

/// Usuario autenticado
class Authenticated extends AuthState {
  final User user;

  const Authenticated({required this.user});

  @override
  List<Object> get props => [user];
}

/// Usuario no autenticado. `reason` se setea cuando la salida fue
/// involuntaria (sesión revocada, token expirado, cuenta desactivada
/// por admin) para que la UI pueda mostrar un mensaje explicativo. En
/// logout normal por click del usuario `reason` es null.
class Unauthenticated extends AuthState {
  final String? reason;

  const Unauthenticated({this.reason});

  @override
  List<Object?> get props => [reason];
}

/// Requiere selección de modo de login
class AuthModeSelectionRequired extends AuthState {
  final User user;
  final List<dynamic> modeOptions; // Lista de ModeOption

  const AuthModeSelectionRequired({
    required this.user,
    required this.modeOptions,
  });

  @override
  List<Object> get props => [user, modeOptions];
}

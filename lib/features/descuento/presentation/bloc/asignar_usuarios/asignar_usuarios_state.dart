import 'package:equatable/equatable.dart';

abstract class AsignarUsuariosState extends Equatable {
  const AsignarUsuariosState();

  @override
  List<Object?> get props => [];
}

class AsignarUsuariosInitial extends AsignarUsuariosState {
  const AsignarUsuariosInitial();
}

class AsignarUsuariosLoading extends AsignarUsuariosState {
  const AsignarUsuariosLoading();
}

class AsignarUsuariosLoaded extends AsignarUsuariosState {
  final List<Map<String, dynamic>> usuariosAsignados;
  final List<Map<String, dynamic>> todosUsuarios;

  const AsignarUsuariosLoaded({
    required this.usuariosAsignados,
    required this.todosUsuarios,
  });

  @override
  List<Object?> get props => [usuariosAsignados, todosUsuarios];
}

class AsignarUsuariosError extends AsignarUsuariosState {
  final String message;
  final String? errorCode;

  const AsignarUsuariosError(this.message, {this.errorCode});

  @override
  List<Object?> get props => [message, errorCode];
}

class AsignarUsuariosSuccess extends AsignarUsuariosState {
  final String message;

  const AsignarUsuariosSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

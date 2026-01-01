import 'package:equatable/equatable.dart';

/// Respuesta al establecer una contraseña para un usuario OAuth
class SetPasswordResponse extends Equatable {
  final bool success;
  final String message;

  const SetPasswordResponse({
    required this.success,
    required this.message,
  });

  @override
  List<Object?> get props => [success, message];

  @override
  String toString() {
    return 'SetPasswordResponse(success: $success, message: $message)';
  }
}

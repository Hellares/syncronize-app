import 'package:equatable/equatable.dart';

/// Respuesta de verificación de métodos de autenticación disponibles
class AuthMethodsResponse extends Equatable {
  final String email;
  final bool exists;
  final List<String> methods;
  final int? authMethodsCount;

  const AuthMethodsResponse({
    required this.email,
    required this.exists,
    required this.methods,
    this.authMethodsCount,
  });

  /// Verifica si el usuario tiene configurado el método PASSWORD
  bool get hasPassword => methods.contains('PASSWORD');

  /// Verifica si el usuario tiene configurado el método GOOGLE
  bool get hasGoogle => methods.contains('GOOGLE');

  /// Verifica si el usuario tiene múltiples métodos de autenticación
  bool get hasMultipleMethods => methods.length > 1;

  /// Verifica si el usuario tiene al menos un método configurado
  bool get hasAnyMethod => methods.isNotEmpty;

  @override
  List<Object?> get props => [email, exists, methods, authMethodsCount];

  @override
  String toString() {
    return 'AuthMethodsResponse(email: $email, exists: $exists, methods: $methods, count: $authMethodsCount)';
  }
}

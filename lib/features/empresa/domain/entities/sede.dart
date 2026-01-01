import 'package:equatable/equatable.dart';

/// Entidad que representa una sede de la empresa
class Sede extends Equatable {
  final String id;
  final String nombre;
  final String? telefono;
  final String? email;
  final String? direccion;
  final bool esPrincipal;
  final bool isActive;
  final String? userRole;

  const Sede({
    required this.id,
    required this.nombre,
    this.telefono,
    this.email,
    this.direccion,
    required this.esPrincipal,
    required this.isActive,
    this.userRole,
  });

  /// Indica si el usuario tiene un rol específico en esta sede
  bool get hasUserRole => userRole != null && userRole!.isNotEmpty;

  @override
  List<Object?> get props => [
        id,
        nombre,
        telefono,
        email,
        direccion,
        esPrincipal,
        isActive,
        userRole,
      ];
}

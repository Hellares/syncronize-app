import 'package:equatable/equatable.dart';

/// Entidad de usuario
class User extends Equatable {
  final String id;
  final String? email; // Ahora es opcional (puede ser null si usa DNI)
  final String? dni; // DNI del usuario
  final String nombres;
  final String apellidos;
  final bool emailVerificado;
  final bool? telefonoVerificado;
  final String? telefono;
  final String? rolGlobal;
  final String? photoUrl; // URL de la foto de perfil (Google, etc.)
  final DateTime? lastLoginAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? metodoPrincipalLogin; // EMAIL, DNI, TELEFONO, GOOGLE, FACEBOOK
  final bool? requiereCambioPassword; // Si debe cambiar password

  const User({
    required this.id,
    this.email,
    this.dni,
    required this.nombres,
    required this.apellidos,
    required this.emailVerificado,
    this.telefonoVerificado,
    this.telefono,
    this.rolGlobal,
    this.photoUrl,
    this.lastLoginAt,
    required this.createdAt,
    required this.updatedAt,
    this.metodoPrincipalLogin,
    this.requiereCambioPassword,
  });

  String get nombreCompleto => '$nombres $apellidos';

  /// Obtiene las iniciales del usuario (primera letra del nombre y apellido)
  String get iniciales {
    final primeraLetraNombre = nombres.isNotEmpty ? nombres[0].toUpperCase() : '';
    final primeraLetraApellido = apellidos.isNotEmpty ? apellidos[0].toUpperCase() : '';
    return '$primeraLetraNombre$primeraLetraApellido';
  }

  /// Identificador para mostrar (email o DNI)
  String get identificador => email ?? dni ?? id;

  @override
  List<Object?> get props => [
        id,
        email,
        dni,
        nombres,
        apellidos,
        emailVerificado,
        telefonoVerificado,
        telefono,
        rolGlobal,
        photoUrl,
        lastLoginAt,
        createdAt,
        updatedAt,
        metodoPrincipalLogin,
        requiereCambioPassword,
      ];
}

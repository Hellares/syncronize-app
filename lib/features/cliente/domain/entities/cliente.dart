import 'package:equatable/equatable.dart';

/// Entity que representa un cliente
class Cliente extends Equatable {
  final String id;
  final String personaId;
  final String? usuarioId;
  final String dni;
  final String nombres;
  final String apellidos;
  final String nombreCompleto;
  final String telefono;
  final String? email;
  final String? direccion;
  final String? distrito;
  final String? provincia;
  final String? departamento;
  final bool isActive;
  final String estado;
  final bool? emailVerificado;
  final bool? telefonoVerificado;
  final bool? dniVerificado;
  final bool yaExistiaEnSistema;
  final String? registradoPor;
  final String? registradoPorNombre;
  final DateTime fechaRegistro;
  final DateTime creadoEn;
  final DateTime actualizadoEn;

  const Cliente({
    required this.id,
    required this.personaId,
    this.usuarioId,
    required this.dni,
    required this.nombres,
    required this.apellidos,
    required this.nombreCompleto,
    required this.telefono,
    this.email,
    this.direccion,
    this.distrito,
    this.provincia,
    this.departamento,
    required this.isActive,
    required this.estado,
    this.emailVerificado,
    this.telefonoVerificado,
    this.dniVerificado,
    required this.yaExistiaEnSistema,
    this.registradoPor,
    this.registradoPorNombre,
    required this.fechaRegistro,
    required this.creadoEn,
    required this.actualizadoEn,
  });

  /// Obtiene las iniciales del cliente
  String get iniciales {
    final primeraLetraNombre = nombres.isNotEmpty ? nombres[0] : '';
    final primeraLetraApellido = apellidos.isNotEmpty ? apellidos[0] : '';
    return '$primeraLetraNombre$primeraLetraApellido'.toUpperCase();
  }

  /// Verifica si el cliente tiene todos los datos completos
  bool get datosCompletos {
    return email != null &&
           direccion != null &&
           distrito != null &&
           provincia != null &&
           departamento != null;
  }

  /// Verifica si el cliente está verificado completamente
  bool get totalmenteVerificado {
    return (emailVerificado ?? false) &&
           (telefonoVerificado ?? false) &&
           (dniVerificado ?? false);
  }

  @override
  List<Object?> get props => [
        id,
        personaId,
        usuarioId,
        dni,
        nombres,
        apellidos,
        nombreCompleto,
        telefono,
        email,
        direccion,
        distrito,
        provincia,
        departamento,
        isActive,
        estado,
        emailVerificado,
        telefonoVerificado,
        dniVerificado,
        yaExistiaEnSistema,
        registradoPor,
        registradoPorNombre,
        fechaRegistro,
        creadoEn,
        actualizadoEn,
      ];
}
